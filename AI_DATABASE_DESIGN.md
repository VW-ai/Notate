# AI Database Design for Notate

## Current Database Analysis

### Existing Schema
```sql
CREATE TABLE entries (
    id TEXT PRIMARY KEY,
    type TEXT NOT NULL,                 -- 'todo' | 'thought'
    content TEXT NOT NULL,              -- User's original content
    tags TEXT,                          -- JSON array of tags
    source_app TEXT,                    -- Source application
    trigger_used TEXT NOT NULL,         -- Trigger pattern used
    created_at TEXT NOT NULL,           -- ISO8601 timestamp
    status TEXT NOT NULL,               -- 'open' | 'done'
    priority TEXT,                      -- 'low' | 'med' | 'high'
    metadata TEXT,                      -- JSON object (flexible)
    encrypted_content TEXT              -- Future encryption
);
```

### Current Strengths
- ✅ Flexible `metadata` JSON field for AI data
- ✅ Good indexing on core fields
- ✅ Robust error handling and corruption detection
- ✅ Transaction safety with queue-based operations

## AI-Enhanced Database Design

### Option 1: Extend Current Schema (Recommended)
**Advantages:** Minimal migration, leverages existing metadata field, backwards compatible

#### Enhanced Metadata Structure
```json
{
  // Calendar Integration
  "calendar_event_id": "ABC123",
  "due_date": "2024-01-15T14:30:00Z",
  "calendar_synced": true,
  "calendar_last_sync": "2024-01-15T10:00:00Z",

  // AI Processing
  "ai_processed": true,
  "ai_last_processed": "2024-01-15T10:00:00Z",
  "ai_processing_version": "v1.0",
  "ai_processing_status": "completed", // pending|processing|completed|failed

  // Date/Time Detection
  "detected_datetime": {
    "has_datetime": true,
    "raw_date": "2024-01-15",
    "raw_time": "14:30",
    "is_relative": false,
    "confidence": 0.95,
    "description": "tomorrow at 2:30pm"
  },

  // Search Suggestions
  "search_suggestions": [
    {
      "query": "SwiftUI tutorial 2024",
      "description": "Learn modern SwiftUI",
      "confidence": 0.9,
      "clicked": false,
      "generated_at": "2024-01-15T10:00:00Z"
    }
  ],

  // AI Processing History
  "ai_history": [
    {
      "action": "datetime_detection",
      "timestamp": "2024-01-15T10:00:00Z",
      "result": "success",
      "model": "claude-3-haiku",
      "cost": 0.001
    }
  ]
}
```

#### New Indexes for AI Operations
```sql
-- Performance indexes for AI queries
CREATE INDEX IF NOT EXISTS idx_entries_ai_processed
ON entries(json_extract(metadata, '$.ai_processed'));

CREATE INDEX IF NOT EXISTS idx_entries_calendar_synced
ON entries(json_extract(metadata, '$.calendar_synced'));

CREATE INDEX IF NOT EXISTS idx_entries_ai_status
ON entries(json_extract(metadata, '$.ai_processing_status'));
```

### Option 2: Dedicated AI Tables (Future Consideration)
**When to consider:** If AI data becomes complex or performance-critical

```sql
-- AI processing state table
CREATE TABLE ai_processing (
    entry_id TEXT PRIMARY KEY,
    status TEXT NOT NULL,           -- pending|processing|completed|failed
    last_processed TEXT,            -- ISO8601 timestamp
    processing_version TEXT,        -- AI model version
    error_message TEXT,             -- Error details if failed
    cost_accumulated REAL,          -- API cost tracking
    FOREIGN KEY(entry_id) REFERENCES entries(id) ON DELETE CASCADE
);

-- Calendar integration table
CREATE TABLE calendar_events (
    id TEXT PRIMARY KEY,
    entry_id TEXT NOT NULL,
    calendar_event_id TEXT,         -- System calendar event ID
    due_date TEXT,                  -- ISO8601 timestamp
    synced_at TEXT,                 -- Last sync timestamp
    sync_status TEXT,               -- synced|pending|failed
    FOREIGN KEY(entry_id) REFERENCES entries(id) ON DELETE CASCADE
);

-- Search suggestions table
CREATE TABLE search_suggestions (
    id TEXT PRIMARY KEY,
    entry_id TEXT NOT NULL,
    query TEXT NOT NULL,
    description TEXT,
    confidence REAL,
    clicked BOOLEAN DEFAULT FALSE,
    generated_at TEXT,
    FOREIGN KEY(entry_id) REFERENCES entries(id) ON DELETE CASCADE
);

-- AI operation history
CREATE TABLE ai_operations (
    id TEXT PRIMARY KEY,
    entry_id TEXT NOT NULL,
    operation_type TEXT NOT NULL,   -- datetime_detection|search_suggestions|calendar_sync
    model_used TEXT,               -- claude-3-haiku
    cost REAL,
    duration_ms INTEGER,
    success BOOLEAN,
    error_message TEXT,
    created_at TEXT,
    FOREIGN KEY(entry_id) REFERENCES entries(id) ON DELETE CASCADE
);
```

## Implementation Strategy

### Phase 1: Metadata Enhancement (Week 1)
1. **Extend Entry Model**
   ```swift
   extension Entry {
       var aiMetadata: AIMetadata? {
           get { /* parse from metadata JSON */ }
           set { /* update metadata JSON */ }
       }
   }

   struct AIMetadata: Codable {
       var processed: Bool = false
       var lastProcessed: Date?
       var processingStatus: ProcessingStatus = .pending
       var detectedDateTime: DetectedDateTime?
       var searchSuggestions: [SearchSuggestion] = []
       var calendarEventId: String?
       var calendarSynced: Bool = false
   }
   ```

2. **Add AI-specific Database Methods**
   ```swift
   extension DatabaseManager {
       func getEntriesNeedingAIProcessing() -> [Entry]
       func markEntryAsProcessed(_ entry: Entry)
       func updateAIMetadata(_ entry: Entry, metadata: AIMetadata)
       func getEntriesWithCalendarEvents() -> [Entry]
   }
   ```

### Phase 2: Efficient Querying (Week 2)
1. **Add SQLite JSON Indexes**
2. **Implement Batch Processing**
   ```swift
   func processEntriesInBatch(limit: Int = 10) async {
       let unprocessed = getEntriesNeedingAIProcessing()
       // Process in background queue
   }
   ```

3. **Add Caching Layer**
   ```swift
   class AICache {
       private var dateTimeCache: [String: DetectedDateTime] = [:]
       private var searchCache: [String: [SearchSuggestion]] = [:]

       func getCachedDateTime(for content: String) -> DetectedDateTime?
       func cacheDateTime(_ result: DetectedDateTime, for content: String)
   }
   ```

### Phase 3: Optimization & Analytics (Week 3)
1. **Cost Tracking**
   ```sql
   -- Track API costs
   SELECT
       DATE(created_at) as date,
       SUM(json_extract(metadata, '$.ai_history[*].cost')) as daily_cost
   FROM entries
   GROUP BY DATE(created_at);
   ```

2. **Performance Monitoring**
   ```swift
   struct AIMetrics {
       var totalProcessed: Int
       var averageProcessingTime: TimeInterval
       var successRate: Double
       var totalCost: Decimal
   }
   ```

## Data Migration Strategy

### Migration Steps
1. **Backup Current Database**
2. **Add New Indexes** (non-breaking)
3. **Migrate Existing Entries** (background process)
4. **Validate Data Integrity**

### Migration Code
```swift
extension DatabaseManager {
    func migrateToAISchema() {
        performOnQueue {
            // Add new indexes
            createAIIndexes()

            // Migrate existing entries
            let allEntries = entries
            for entry in allEntries {
                var updatedEntry = entry
                if updatedEntry.aiMetadata == nil {
                    updatedEntry.aiMetadata = AIMetadata()
                    updateEntry(updatedEntry)
                }
            }
        }
    }

    private func createAIIndexes() {
        let indexes = [
            "CREATE INDEX IF NOT EXISTS idx_ai_processed ON entries(json_extract(metadata, '$.ai_processed'));",
            "CREATE INDEX IF NOT EXISTS idx_calendar_synced ON entries(json_extract(metadata, '$.calendar_synced'));",
            "CREATE INDEX IF NOT EXISTS idx_ai_status ON entries(json_extract(metadata, '$.ai_processing_status'));"
        ]

        for indexSQL in indexes {
            sqlite3_exec(db, indexSQL, nil, nil, nil)
        }
    }
}
```

## Performance Considerations

### Indexing Strategy
- **Priority:** Index frequently queried AI metadata fields
- **JSON Indexes:** Use SQLite's JSON extract functions for metadata queries
- **Composite Indexes:** For complex filtering (type + AI status)

### Caching Strategy
- **In-Memory Cache:** Recently processed AI results
- **Content Hash Cache:** Avoid reprocessing identical content
- **TTL Cache:** Expire old search suggestions

### Background Processing
- **Queue-Based:** Process AI operations asynchronously
- **Batch Processing:** Group multiple entries for efficiency
- **Rate Limiting:** Respect API rate limits

## Privacy & Security

### Data Protection
- **Local Storage:** All AI metadata stays local
- **Encryption:** Leverage existing encryption for sensitive data
- **Opt-in:** Clear consent for AI processing

### API Key Management
- **Keychain Storage:** Secure API key storage
- **Key Rotation:** Support for API key updates
- **Validation:** Test API connectivity

## Success Metrics

### Database Performance
- Query execution time < 50ms
- Background processing doesn't block UI
- Database size growth < 20% with AI data

### Data Quality
- AI processing success rate > 95%
- Date detection accuracy > 90%
- Search suggestion relevance > 80%

### Cost Management
- Daily API costs < $0.10 per active user
- Cache hit rate > 70%
- Processing efficiency improving over time

## Risk Mitigation

### Database Corruption
- **Existing Robustness:** Your current corruption detection is excellent
- **AI Data Validation:** Validate AI metadata before storage
- **Graceful Degradation:** App works without AI data

### API Failures
- **Retry Logic:** Exponential backoff for transient failures
- **Offline Mode:** Mark entries for later processing
- **Fallback Processing:** Basic date parsing without AI

### Performance Issues
- **Background Processing:** Never block main thread
- **Memory Management:** Clean up AI caches periodically
- **Progressive Enhancement:** Core features work without AI

---

## Recommendation

**Start with Option 1 (Metadata Enhancement)** because:
1. Leverages your existing robust database architecture
2. Minimal migration risk
3. Preserves current performance characteristics
4. Easy to extend later if needed

Your current database design is already well-architected for this enhancement!