import Foundation
import SQLite3
import CryptoKit
import Combine

final class DatabaseManager: ObservableObject {
    static let shared = DatabaseManager()
    
    private var db: OpaquePointer?
    private let dbPath: String
    private let encryptionKey: SymmetricKey
    private let queue = DispatchQueue(label: "io.github.V1ctor2182.Notate.DatabaseQueue")
    private let queueKey = DispatchSpecificKey<Void>()
    private let sqliteTransient: sqlite3_destructor_type = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    // Fixed: Add synchronization for database repair operations
    private var isRepairingDatabase = false
    private let repairLock = NSLock()
    
    @Published var entries: [Entry] = []
    
    private init() {
        // Create database path in Application Support
        let documentsPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dbDirectory = documentsPath.appendingPathComponent("Notate")
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: dbDirectory, withIntermediateDirectories: true)
        
        self.dbPath = dbDirectory.appendingPathComponent("notate.db").path
        
        // Generate or load encryption key
        self.encryptionKey = Self.loadOrCreateEncryptionKey()
        
        queue.setSpecific(key: queueKey, value: ())
        performOnQueue {
            self.openDatabase()
            self.createTables()
            self.loadEntriesInternal()
        }
    }
    
    deinit {
        closeDatabase()
    }

    // MARK: - Database Operations

    private func performOnQueue<T>(_ work: () -> T) -> T {
        if DispatchQueue.getSpecific(key: queueKey) != nil {
            return work()
        }
        return queue.sync(execute: work)
    }

    private func bindText(_ statement: OpaquePointer?, index: Int32, value: String?) {
        guard let statement else { return }
        if let value {
            value.withCString { pointer in
                sqlite3_bind_text(statement, index, pointer, -1, sqliteTransient)
            }
        } else {
            sqlite3_bind_null(statement, index)
        }
    }
    
    private func openDatabase() {
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            print("❌ Unable to open database at \(dbPath)")
            return
        }
        
        // Enable foreign keys
        sqlite3_exec(db, "PRAGMA foreign_keys = ON", nil, nil, nil)
        
        print("✅ Database opened at \(dbPath)")
    }

    private func finalizeOpenStatements(on db: OpaquePointer?) {
        // Fixed: Improved statement finalization with error handling and safety checks
        guard let db else { return }

        var finalizedCount = 0
        var errorCount = 0

        var statement = sqlite3_next_stmt(db, nil)
        while let current = statement {
            let result = sqlite3_finalize(current)
            if result == SQLITE_OK {
                finalizedCount += 1
            } else {
                errorCount += 1
                let errorMsg = String(cString: sqlite3_errmsg(db))
                print("⚠️ Failed to finalize statement: \(errorMsg) (code: \(result))")
            }

            statement = sqlite3_next_stmt(db, nil)

            // Safety break to prevent infinite loops
            if finalizedCount + errorCount > 100 {
                print("⚠️ Too many statements to finalize, possible leak detected")
                break
            }
        }

        if finalizedCount > 0 || errorCount > 0 {
            print("📊 Statement cleanup: \(finalizedCount) finalized, \(errorCount) errors")
        }
    }

    private func closeDatabase() {
        performOnQueue {
            _ = self.closeDatabaseInternal()
        }
    }

    @discardableResult
    private func closeDatabaseInternal() -> Bool {
        guard let db = db else { return true }

        sqlite3_exec(db, "ROLLBACK", nil, nil, nil)
        sqlite3_exec(db, "PRAGMA optimize", nil, nil, nil)
        finalizeOpenStatements(on: db)

        var result = sqlite3_close_v2(db)
        var retryCount = 0
        let maxRetries = 3

        while result == SQLITE_BUSY && retryCount < maxRetries {
            let errorMsg = String(cString: sqlite3_errmsg(db))
            print("⚠️ Database close attempt \(retryCount + 1) failed: \(errorMsg) (code: \(result))")
            Thread.sleep(forTimeInterval: 0.1)
            finalizeOpenStatements(on: db)
            result = sqlite3_close_v2(db)
            retryCount += 1
        }

        if result == SQLITE_OK {
            print("✅ Database closed successfully")
            self.db = nil
            return true
        }

        let errorMsg = String(cString: sqlite3_errmsg(db))
        print("❌ Failed to close database after \(maxRetries) attempts: \(errorMsg) (code: \(result))")
        return false
    }

    private func forceCloseDatabase() {
        performOnQueue {
            _ = self.forceCloseDatabaseInternal()
        }
    }

    @discardableResult
    private func forceCloseDatabaseInternal() -> Bool {
        guard let db = db else { return true }

        print("🔧 Force closing database...")

        sqlite3_exec(db, "ROLLBACK", nil, nil, nil)
        sqlite3_exec(db, "PRAGMA optimize", nil, nil, nil)
        sqlite3_exec(db, "PRAGMA wal_checkpoint(FULL)", nil, nil, nil)

        sqlite3_exec(db, "PRAGMA temp_store = MEMORY", nil, nil, nil)
        sqlite3_exec(db, "PRAGMA cache_size = 0", nil, nil, nil)

        finalizeOpenStatements(on: db)

        let result = sqlite3_close_v2(db)
        if result == SQLITE_OK {
            print("✅ Database force closed successfully")
            self.db = nil
            return true
        }

        let errorMsg = String(cString: sqlite3_errmsg(db))
        print("⚠️ Database force close failed: \(errorMsg) (code: \(result))")
        return false
    }
    
    private func createTables() {
        let createEntriesTable = """
        CREATE TABLE IF NOT EXISTS entries (
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            content TEXT NOT NULL,
            tags TEXT, -- JSON array
            source_app TEXT,
            trigger_used TEXT NOT NULL,
            created_at TEXT NOT NULL,
            status TEXT NOT NULL,
            priority TEXT,
            metadata TEXT, -- JSON object
            encrypted_content TEXT -- For future encryption
        );
        """
        
        let createIndexes = [
            "CREATE INDEX IF NOT EXISTS idx_entries_type ON entries(type);",
            "CREATE INDEX IF NOT EXISTS idx_entries_created_at ON entries(created_at);",
            "CREATE INDEX IF NOT EXISTS idx_entries_status ON entries(status);",
            "CREATE INDEX IF NOT EXISTS idx_entries_priority ON entries(priority);"
        ]
        
        if sqlite3_exec(db, createEntriesTable, nil, nil, nil) != SQLITE_OK {
            print("❌ Error creating entries table")
            return
        }
        
        for indexSQL in createIndexes {
            if sqlite3_exec(db, indexSQL, nil, nil, nil) != SQLITE_OK {
                print("❌ Error creating index")
            }
        }
        
        print("✅ Database tables created")
    }
    
    // MARK: - CRUD Operations
    
    func saveEntry(_ entry: Entry) {
        performOnQueue {
            self.saveEntryInternal(entry)
        }
    }

    private func saveEntryInternal(_ entry: Entry) {
        guard let db = db else {
            print("❌ Database not initialized")
            return
        }

        guard repairDatabaseIfNeededInternal() else {
            print("❌ Failed to repair database")
            return
        }

        let insertSQL = """
        INSERT OR REPLACE INTO entries 
        (id, type, content, tags, source_app, trigger_used, created_at, status, priority, metadata)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """

        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) == SQLITE_OK {
            let cleanContent = entry.content.trimmingCharacters(in: .controlCharacters)
            let cleanId = entry.id.trimmingCharacters(in: .controlCharacters)

            bindText(statement, index: 1, value: cleanId)
            bindText(statement, index: 2, value: entry.type.rawValue)
            bindText(statement, index: 3, value: cleanContent)

            let tagsJSON = try? JSONEncoder().encode(entry.tags)
            let tagsString = tagsJSON?.base64EncodedString()
            bindText(statement, index: 4, value: tagsString)

            bindText(statement, index: 5, value: entry.sourceApp)
            bindText(statement, index: 6, value: entry.triggerUsed)

            let formatter = ISO8601DateFormatter()
            let createdAtString = formatter.string(from: entry.createdAt)
            bindText(statement, index: 7, value: createdAtString)

            bindText(statement, index: 8, value: entry.status.rawValue)
            bindText(statement, index: 9, value: entry.priority?.rawValue)

            let metadataString: String?
            if let metadata = entry.metadata {
                let metadataJSON = try? JSONEncoder().encode(metadata)
                metadataString = metadataJSON?.base64EncodedString()
            } else {
                metadataString = nil
            }
            bindText(statement, index: 10, value: metadataString)

            let result = sqlite3_step(statement)
            if result == SQLITE_DONE {
                print("✅ Entry saved: \(entry.id)")
                loadEntriesInternal()
            } else {
                let errorMsg = String(cString: sqlite3_errmsg(db))
                print("❌ Error saving entry: \(errorMsg) (code: \(result))")

                if result == SQLITE_CORRUPT || result == SQLITE_NOTADB {
                    print("🔄 Database corruption detected, attempting to rebuild...")
                    sqlite3_finalize(statement)
                    if rebuildDatabaseInternal() {
                        print("🔄 Retrying save after database rebuild...")
                        saveEntryInternal(entry)
                        return
                    }
                }
            }
        } else {
            let errorMsg = String(cString: sqlite3_errmsg(db))
            print("❌ Error preparing statement: \(errorMsg)")
        }

        sqlite3_finalize(statement)
    }

    private func repairDatabaseIfNeededInternal() -> Bool {
        // Fixed: Prevent concurrent repair operations using lock
        guard repairLock.try() else {
            print("⚠️ Database repair already in progress, skipping...")
            return isRepairingDatabase ? false : true // Return false if repair is ongoing
        }
        defer { repairLock.unlock() }

        // If already repairing, return false
        if isRepairingDatabase {
            return false
        }

        guard let db = db else {
            print("❌ Database pointer missing during repair check")
            return false
        }

        // 尝试修复数据库
        let integrityResult = sqlite3_exec(db, "PRAGMA integrity_check", nil, nil, nil)
        if integrityResult != SQLITE_OK {
            print("⚠️ Database integrity check failed, attempting repair...")
            return performDatabaseRebuild()
        }

        // 额外检查：尝试执行一个简单查询
        let countResult = sqlite3_exec(db, "SELECT COUNT(*) FROM entries", nil, nil, nil)
        if countResult != SQLITE_OK {
            let errorMsg = String(cString: sqlite3_errmsg(db))
            print("⚠️ Database query test failed: \(errorMsg), rebuilding...")
            return performDatabaseRebuild()
        }

        // 数据质量检查：使用更安全的方法检查数据
        if checkDataQuality() {
            return performDatabaseRebuild()
        }

        return true
    }

    private func checkDataQuality() -> Bool {
        guard let db = db else { return true } // Assume corrupted if no db

        var hasCorruptedData = false

        // Thread-safe corruption detection
        let callback: @convention(c) (UnsafeMutableRawPointer?, Int32, UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?, UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?) -> Int32 = { userData, argc, argv, colNames in
            if argc >= 3, let argv = argv, let userData = userData {
                // Safely extract strings
                guard let idPtr = argv[0], let typePtr = argv[1], let contentPtr = argv[2] else {
                    userData.assumingMemoryBound(to: Bool.self).pointee = true
                    return 1 // Stop iteration on error
                }

                let id = String(cString: idPtr)
                let type = String(cString: typePtr)
                let content = String(cString: contentPtr)

                // 检查是否包含乱码字符（非打印字符或异常字符）
                let isCorrupted = id.contains { $0.asciiValue != nil && $0.asciiValue! < 32 && $0.asciiValue! != 9 && $0.asciiValue! != 10 && $0.asciiValue! != 13 } ||
                                type.contains { $0.asciiValue != nil && $0.asciiValue! < 32 && $0.asciiValue! != 9 && $0.asciiValue! != 10 && $0.asciiValue! != 13 } ||
                                content.contains { $0.asciiValue != nil && $0.asciiValue! < 32 && $0.asciiValue! != 9 && $0.asciiValue! != 10 && $0.asciiValue! != 13 }

                if isCorrupted {
                    print("⚠️ Corrupted data detected in database: ID='\(id)', Type='\(type)', Content='\(content)'")
                    userData.assumingMemoryBound(to: Bool.self).pointee = true
                    return 1 // Stop iteration on first corruption
                }
            }
            return 0
        }

        let qualityResult = sqlite3_exec(db, "SELECT id, type, content FROM entries LIMIT 1", callback, &hasCorruptedData, nil)

        if qualityResult != SQLITE_OK {
            let errorMsg = String(cString: sqlite3_errmsg(db))
            print("⚠️ Error during data quality check: \(errorMsg)")
            return true // Assume corrupted on error
        }

        return hasCorruptedData
    }

    private func performDatabaseRebuild() -> Bool {
        isRepairingDatabase = true
        defer { isRepairingDatabase = false }

        return rebuildDatabaseInternal()
    }

    private func rebuildDatabaseInternal() -> Bool {
        print("🔧 Rebuilding database...")

        var closed = closeDatabaseInternal()
        if !closed {
            closed = forceCloseDatabaseInternal()
        }

        guard closed else {
            print("❌ Unable to close database connection; aborting rebuild")
            return false
        }

        Thread.sleep(forTimeInterval: 0.2)

        let backupPath = dbPath + ".backup.\(Date().timeIntervalSince1970)"
        do {
            if FileManager.default.fileExists(atPath: dbPath) {
                // 先删除备份文件（如果存在）
                if FileManager.default.fileExists(atPath: backupPath) {
                    try FileManager.default.removeItem(atPath: backupPath)
                }
                try FileManager.default.moveItem(atPath: dbPath, toPath: backupPath)
                print("📦 Backed up corrupted database to: \(backupPath)")
            }
        } catch {
            print("⚠️ Failed to backup database: \(error)")
            // 如果备份失败，直接删除损坏的数据库
            try? FileManager.default.removeItem(atPath: dbPath)
        }
        
        // 确保目录存在
        let dbDirectory = URL(fileURLWithPath: dbPath).deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dbDirectory, withIntermediateDirectories: true)
        
        // 重新打开数据库
        openDatabase()
        guard db != nil else {
            print("❌ Failed to reopen database during rebuild")
            return false
        }
        createTables()
        
        // 验证新数据库
        let testResult = sqlite3_exec(db, "SELECT COUNT(*) FROM entries", nil, nil, nil)
        if testResult == SQLITE_OK {
            print("✅ Database rebuilt and verified successfully")
            // 注意：不在这里调用loadEntries()，让调用者决定何时重新加载
            return true
        } else {
            print("❌ Failed to verify rebuilt database")
            return false
        }
    }
    
    func updateEntry(_ entry: Entry) {
        saveEntry(entry) // INSERT OR REPLACE handles updates
    }
    
    func deleteEntry(id: String) {
        performOnQueue {
            self.deleteEntryInternal(id: id)
        }
    }

    private func deleteEntryInternal(id: String) {
        guard let db = db else {
            print("❌ Database not initialized for delete")
            return
        }

        let deleteSQL = "DELETE FROM entries WHERE id = ?"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, deleteSQL, -1, &statement, nil) == SQLITE_OK {
            bindText(statement, index: 1, value: id)

            if sqlite3_step(statement) == SQLITE_DONE {
                print("✅ Entry deleted: \(id)")
                loadEntriesInternal()
            } else {
                print("❌ Error deleting entry")
            }
        }

        sqlite3_finalize(statement)
    }
    
    func loadEntries() {
        performOnQueue {
            self.loadEntriesInternal()
        }
    }

    private func loadEntriesInternal() {
        print("📖 Loading entries from database...")

        guard let db = db else {
            print("❌ Database not initialized for loading")
            return
        }

        if !repairDatabaseIfNeededInternal() {
            print("❌ Database is corrupted, attempting to rebuild...")
            if rebuildDatabaseInternal() {
                print("✅ Database rebuilt successfully, retrying load...")
                DispatchQueue.main.async {
                    self.entries = []
                    print("🔄 Updated UI with 0 entries (after rebuild)")
                }
                return
            } else {
                print("❌ Failed to rebuild database")
                return
            }
        }

        let querySQL = "SELECT * FROM entries ORDER BY created_at DESC"
        var statement: OpaquePointer?
        var loadedEntries: [Entry] = []

        if sqlite3_prepare_v2(db, querySQL, -1, &statement, nil) == SQLITE_OK {
            var rowCount = 0
            while sqlite3_step(statement) == SQLITE_ROW {
                if let entry = parseEntryFromStatement(statement) {
                    loadedEntries.append(entry)
                    rowCount += 1
                    print("📄 Loaded entry \(rowCount): \(entry.content)")
                } else {
                    print("⚠️ Failed to parse entry at row \(rowCount) - database may be corrupted")
                    if rowCount == 0 {
                        print("🔄 First entry failed to parse, rebuilding database...")
                        sqlite3_finalize(statement)
                        if rebuildDatabaseInternal() {
                            print("✅ Database rebuilt, retrying load...")
                            loadEntriesInternal()
                            return
                        }
                    }
                }
            }
            print("📊 Total entries loaded: \(loadedEntries.count)")
        } else {
            let errorMsg = String(cString: sqlite3_errmsg(db))
            print("❌ Error preparing load query: \(errorMsg)")
        }

        sqlite3_finalize(statement)

        DispatchQueue.main.async {
            self.entries = loadedEntries
            print("🔄 Updated UI with \(loadedEntries.count) entries")
        }
    }
    
    private func parseEntryFromStatement(_ statement: OpaquePointer?) -> Entry? {
        guard let statement = statement else { 
            print("❌ Statement is nil")
            return nil 
        }
        
        // 检查列数
        let columnCount = sqlite3_column_count(statement)
        print("🔍 Parsing entry with \(columnCount) columns")
        
        // 安全地获取文本字段
        func safeGetText(_ column: Int32) -> String? {
            let text = sqlite3_column_text(statement, column)
            return text != nil ? String(cString: text!) : nil
        }
        
        guard let id = safeGetText(0) else {
            print("❌ Failed to get id from column 0")
            return nil
        }
        
        guard let typeString = safeGetText(1) else {
            print("❌ Failed to get type from column 1")
            return nil
        }
        
        guard let content = safeGetText(2) else {
            print("❌ Failed to get content from column 2")
            return nil
        }
        
        print("📋 Raw data - ID: \(id), Type: \(typeString), Content: \(content)")
        
        // Parse tags
        var tags: [String] = []
        if let tagsData = safeGetText(3), !tagsData.isEmpty {
            if let tagsJSON = Data(base64Encoded: tagsData),
               let decodedTags = try? JSONDecoder().decode([String].self, from: tagsJSON) {
                tags = decodedTags
            } else {
                print("⚠️ Failed to decode tags: \(tagsData)")
            }
        }
        
        let sourceApp = safeGetText(4)
        
        guard let triggerUsed = safeGetText(5) else {
            print("❌ Failed to get triggerUsed from column 5")
            return nil
        }
        
        guard let createdAtString = safeGetText(6) else {
            print("❌ Failed to get createdAt from column 6")
            return nil
        }
        
        guard let statusString = safeGetText(7) else {
            print("❌ Failed to get status from column 7")
            return nil
        }
        
        let priorityString = safeGetText(8)
        
        print("📋 Parsed strings - Trigger: \(triggerUsed), CreatedAt: \(createdAtString), Status: \(statusString), Priority: \(priorityString ?? "nil")")
        
        // Parse metadata
        var metadata: [String: FlexibleCodable]?
        if let metadataData = safeGetText(9), !metadataData.isEmpty {
            if let metadataJSON = Data(base64Encoded: metadataData),
               let decodedMetadata = try? JSONDecoder().decode([String: FlexibleCodable].self, from: metadataJSON) {
                metadata = decodedMetadata
            } else {
                print("⚠️ Failed to decode metadata: \(metadataData)")
            }
        }
        
        // Parse dates and enums
        let formatter = ISO8601DateFormatter()
        guard let createdAt = formatter.date(from: createdAtString) else {
            print("❌ Failed to parse date: \(createdAtString)")
            return nil
        }
        
        guard let type = EntryType(rawValue: typeString) else {
            print("❌ Failed to parse type: \(typeString)")
            return nil
        }
        
        guard let status = EntryStatus(rawValue: statusString) else {
            print("❌ Failed to parse status: \(statusString)")
            return nil
        }
        
        let priority = priorityString.flatMap { EntryPriority(rawValue: $0) }
        
        print("✅ Successfully parsed entry: \(content)")
        
        return Entry(
            id: id,
            type: type,
            content: content,
            tags: tags,
            sourceApp: sourceApp,
            triggerUsed: triggerUsed,
            createdAt: createdAt,
            status: status,
            priority: priority,
            metadata: metadata
        )
    }
    
    // MARK: - Search and Filter
    
    func searchEntries(query: String) -> [Entry] {
        return performOnQueue {
            self.searchEntriesInternal(query: query)
        }
    }

    private func searchEntriesInternal(query: String) -> [Entry] {
        guard let db = db else {
            print("❌ Database not initialized for search")
            return []
        }
        let searchSQL = """
        SELECT * FROM entries 
        WHERE content LIKE ? OR id IN (
            SELECT DISTINCT id FROM entries, json_each(tags) 
            WHERE json_each.value LIKE ?
        )
        ORDER BY created_at DESC
        """

        var statement: OpaquePointer?
        var results: [Entry] = []
        let searchPattern = "%\(query)%"

        if sqlite3_prepare_v2(db, searchSQL, -1, &statement, nil) == SQLITE_OK {
            bindText(statement, index: 1, value: searchPattern)
            bindText(statement, index: 2, value: searchPattern)

            while sqlite3_step(statement) == SQLITE_ROW {
                if let entry = parseEntryFromStatement(statement) {
                    results.append(entry)
                }
            }
        }

        sqlite3_finalize(statement)
        return results
    }
    
    func filterEntries(type: EntryType? = nil, status: EntryStatus? = nil, priority: EntryPriority? = nil) -> [Entry] {
        return performOnQueue {
            self.filterEntriesInternal(type: type, status: status, priority: priority)
        }
    }

    private func filterEntriesInternal(type: EntryType? = nil, status: EntryStatus? = nil, priority: EntryPriority? = nil) -> [Entry] {
        guard let db = db else {
            print("❌ Database not initialized for filter")
            return []
        }
        var conditions: [String] = []
        var parameters: [String] = []

        if let type = type {
            conditions.append("type = ?")
            parameters.append(type.rawValue)
        }

        if let status = status {
            conditions.append("status = ?")
            parameters.append(status.rawValue)
        }

        if let priority = priority {
            conditions.append("priority = ?")
            parameters.append(priority.rawValue)
        }

        let whereClause = conditions.isEmpty ? "" : "WHERE " + conditions.joined(separator: " AND ")
        let filterSQL = "SELECT * FROM entries \(whereClause) ORDER BY created_at DESC"

        var statement: OpaquePointer?
        var results: [Entry] = []

        if sqlite3_prepare_v2(db, filterSQL, -1, &statement, nil) == SQLITE_OK {
            for (index, param) in parameters.enumerated() {
                bindText(statement, index: Int32(index + 1), value: param)
            }

            while sqlite3_step(statement) == SQLITE_ROW {
                if let entry = parseEntryFromStatement(statement) {
                    results.append(entry)
                }
            }
        }

        sqlite3_finalize(statement)
        return results
    }
    
    // MARK: - Export
    
    func exportToJSON() -> Data? {
        return try? JSONEncoder().encode(entries)
    }
    
    func exportToCSV() -> String {
        var csv = "id,type,content,tags,source_app,trigger_used,created_at,status,priority\n"
        
        for entry in entries {
            let tagsString = entry.tags.joined(separator: ";")
            let priorityString = entry.priority?.rawValue ?? ""
            let formatter = ISO8601DateFormatter()
            
            csv += "\"\(entry.id)\",\"\(entry.type.rawValue)\",\"\(entry.content.replacingOccurrences(of: "\"", with: "\"\""))\",\"\(tagsString)\",\"\(entry.sourceApp ?? "")\",\"\(entry.triggerUsed)\",\"\(formatter.string(from: entry.createdAt))\",\"\(entry.status.rawValue)\",\"\(priorityString)\"\n"
        }
        
        return csv
    }
    
    // MARK: - Database Maintenance
    
    func forceRebuildDatabase() -> Bool {
        print("🔧 Force rebuilding database...")
        return performOnQueue {
            self.rebuildDatabaseInternal()
        }
    }

    func checkDatabaseHealth() -> Bool {
        return performOnQueue {
            guard db != nil else { return false }

            let result = sqlite3_exec(db, "PRAGMA integrity_check", nil, nil, nil)
            if result == SQLITE_OK {
                print("✅ Database health check passed")
                return true
            } else {
                let errorMsg = String(cString: sqlite3_errmsg(db))
                print("❌ Database health check failed: \(errorMsg)")
                return false
            }
        }
    }

    func forceRefreshEntries() {
        print("🔄 Force refreshing entries...")
        loadEntries()
    }
    
    // MARK: - Encryption Key Management
    
    private static func loadOrCreateEncryptionKey() -> SymmetricKey {
        // Fixed: Add proper error handling for keychain operations
        let keychain = Keychain(service: "com.notate.app")
        let keyIdentifier = "notate-encryption-key"

        do {
            // Try to load existing key
            if let keyData = try keychain.getData(for: keyIdentifier) {
                print("✅ Loaded existing encryption key from keychain")
                return SymmetricKey(data: keyData)
            }
        } catch KeychainError.itemNotFound {
            print("ℹ️ No existing encryption key found, creating new one")
        } catch {
            print("⚠️ Failed to load encryption key: \(error), creating fallback key")
        }

        // Create new key
        let newKey = SymmetricKey(size: .bits256)
        let keyData = newKey.withUnsafeBytes { Data($0) }

        do {
            try keychain.setData(keyData, for: keyIdentifier)
            print("✅ Created and stored new encryption key")
        } catch {
            print("❌ Failed to store encryption key: \(error)")
            print("⚠️ Using in-memory key only - data will not be encrypted persistently")
        }

        return newKey
    }

    // MARK: - AI Metadata Operations

    func getEntriesNeedingAIProcessing() -> [Entry] {
        return performOnQueue {
            return self.entries.filter { entry in
                entry.needsAIProcessing
            }
        }
    }

    func getEntriesWithAIActions() -> [Entry] {
        return performOnQueue {
            return self.entries.filter { entry in
                entry.hasAIActions
            }
        }
    }

    func getEntriesWithAIResearch() -> [Entry] {
        return performOnQueue {
            return self.entries.filter { entry in
                entry.hasAIResearch
            }
        }
    }

    func updateEntryAIMetadata(_ entryId: String, metadata: AIMetadata) {
        performOnQueue {
            guard let index = self.entries.firstIndex(where: { $0.id == entryId }) else {
                print("⚠️ Entry not found for AI metadata update: \(entryId)")
                return
            }

            var updatedEntry = self.entries[index]
            updatedEntry.setAIMetadata(metadata)

            // Update in database
            self.saveEntryInternal(updatedEntry)

            // Update in-memory array to trigger @Published notification
            self.entries[index] = updatedEntry
            print("✅ Updated entry AI metadata in memory for: \(entryId)")
        }
    }

    func addAIActionToEntry(_ entryId: String, action: AIAction) {
        performOnQueue {
            guard let index = self.entries.firstIndex(where: { $0.id == entryId }) else {
                print("⚠️ Entry not found for AI action addition: \(entryId)")
                return
            }

            var updatedEntry = self.entries[index]
            updatedEntry.addAIAction(action)

            // Update in database
            self.saveEntryInternal(updatedEntry)

            // Update in-memory array to trigger @Published notification
            self.entries[index] = updatedEntry
            print("✅ Added AI action to entry in memory: \(entryId)")
        }
    }

    func updateAIActionStatus(_ entryId: String, actionId: String, status: ActionStatus) {
        performOnQueue {
            guard let index = self.entries.firstIndex(where: { $0.id == entryId }) else {
                print("⚠️ Entry not found for AI action update: \(entryId)")
                return
            }

            var updatedEntry = self.entries[index]
            updatedEntry.updateAIAction(actionId, status: status)

            // Update in database
            self.saveEntryInternal(updatedEntry)

            // Update in-memory array to trigger @Published notification
            self.entries[index] = updatedEntry
            print("✅ Updated AI action status in memory: \(entryId), action: \(actionId), status: \(status)")
        }
    }

    func updateAIActionData(_ entryId: String, actionId: String, reverseData: [String: ActionData]) {
        performOnQueue {
            guard let index = self.entries.firstIndex(where: { $0.id == entryId }) else {
                print("⚠️ Entry not found for AI action data update: \(entryId)")
                return
            }

            var updatedEntry = self.entries[index]
            updatedEntry.updateAIActionData(actionId, reverseData: reverseData)

            // Update in database
            self.saveEntryInternal(updatedEntry)

            // Update in-memory array to trigger @Published notification
            self.entries[index] = updatedEntry
            print("✅ Updated AI action data in memory: \(entryId), action: \(actionId)")
        }
    }

    func setAIResearchForEntry(_ entryId: String, research: ResearchResults) {
        performOnQueue {
            guard let index = self.entries.firstIndex(where: { $0.id == entryId }) else {
                print("⚠️ Entry not found for AI research update: \(entryId)")
                return
            }

            var updatedEntry = self.entries[index]
            updatedEntry.setAIResearch(research)

            // Update in database
            self.saveEntryInternal(updatedEntry)

            // Update in-memory array to trigger @Published notification
            self.entries[index] = updatedEntry
            print("✅ Updated AI research in memory for: \(entryId)")
        }
    }

    // MARK: - AI Analytics

    func getAIUsageStats() -> AIUsageStats {
        return performOnQueue { () -> AIUsageStats in
            let entriesWithAI = self.entries.filter { $0.hasAIProcessing }
            let totalActionsExecuted = entriesWithAI.reduce(0) { count, entry in
                count + (entry.aiMetadata?.executedActions.count ?? 0)
            }
            let totalResearchGenerated = entriesWithAI.filter { $0.hasAIResearch }.count
            let totalCost = entriesWithAI.reduce(0.0) { cost, entry in
                cost + (entry.aiMetadata?.totalCost ?? 0.0)
            }

            return AIUsageStats(
                totalEntriesProcessed: entriesWithAI.count,
                totalActionsExecuted: totalActionsExecuted,
                totalResearchGenerated: totalResearchGenerated,
                totalCost: totalCost,
                lastUpdated: Date()
            )
        }
    }

    // Add AI indexes for better performance (call during database initialization)
    private func createAIIndexes() {
        let indexes = [
            "CREATE INDEX IF NOT EXISTS idx_ai_processed ON entries(json_extract(metadata, '$.ai') IS NOT NULL);",
            "CREATE INDEX IF NOT EXISTS idx_ai_actions ON entries(json_extract(metadata, '$.ai.actions') IS NOT NULL);",
            "CREATE INDEX IF NOT EXISTS idx_ai_research ON entries(json_extract(metadata, '$.ai.researchResults') IS NOT NULL);"
        ]

        for indexSQL in indexes {
            if sqlite3_exec(db, indexSQL, nil, nil, nil) != SQLITE_OK {
                print("❌ Error creating AI index: \(indexSQL)")
            }
        }
    }
}

// MARK: - Keychain Error Types
enum KeychainError: Error, LocalizedError {
    case itemNotFound
    case duplicateItem
    case invalidData
    case unhandledError(OSStatus)

    var errorDescription: String? {
        switch self {
        case .itemNotFound:
            return "Item not found in keychain"
        case .duplicateItem:
            return "Item already exists in keychain"
        case .invalidData:
            return "Invalid data format"
        case .unhandledError(let status):
            return "Keychain operation failed with status: \(status)"
        }
    }
}

// MARK: - AI Usage Statistics
struct AIUsageStats {
    let totalEntriesProcessed: Int
    let totalActionsExecuted: Int
    let totalResearchGenerated: Int
    let totalCost: Double
    let lastUpdated: Date

    var formattedCost: String {
        return String(format: "$%.4f", totalCost)
    }

    var averageCostPerEntry: Double {
        guard totalEntriesProcessed > 0 else { return 0.0 }
        return totalCost / Double(totalEntriesProcessed)
    }
}

// MARK: - Enhanced Keychain Wrapper with Error Handling
private class Keychain {
    private let service: String

    init(service: String) {
        self.service = service
    }

    func getData(for key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data else {
                throw KeychainError.invalidData
            }
            return data
        case errSecItemNotFound:
            throw KeychainError.itemNotFound
        default:
            throw KeychainError.unhandledError(status)
        }
    }

    func setData(_ data: Data, for key: String) throws {
        // First, try to update existing item
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        if updateStatus == errSecItemNotFound {
            // Item doesn't exist, create new one
            let newAttributes: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: key,
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            ]

            let addStatus = SecItemAdd(newAttributes as CFDictionary, nil)
            if addStatus != errSecSuccess {
                throw KeychainError.unhandledError(addStatus)
            }
        } else if updateStatus != errSecSuccess {
            throw KeychainError.unhandledError(updateStatus)
        }
    }

    func deleteData(for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainError.unhandledError(status)
        }
    }
}
