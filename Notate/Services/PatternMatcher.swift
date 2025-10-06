import Foundation

/// Simple pattern matching service for detecting data types without AI
/// Uses regex and keyword matching for fast, reliable detection
struct PatternMatcher {

    // MARK: - Phone Number Detection

    static func isPhoneNumber(_ text: String) -> Bool {
        let phonePatterns = [
            #"(\+?\d{1,3}[\s.-]?)?\(?[\d\s.-]{10,}\)?"#,  // General phone pattern
            #"\+?\d{1,3}[\s.-]?\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4}"#,  // US format
            #"\d{3}[-.]?\d{3}[-.]?\d{4}"#,  // Simple US format
            #"\(\d{3}\)\s?\d{3}[-.]?\d{4}"#  // (555) 123-4567 format
        ]

        return phonePatterns.contains { pattern in
            text.range(of: pattern, options: .regularExpression) != nil
        }
    }

    static func extractPhoneNumber(_ text: String) -> String? {
        let phonePattern = #"(\+?\d{1,3}[\s.-]?)?\(?[\d\s.-]{10,}\)?"#
        guard let range = text.range(of: phonePattern, options: .regularExpression) else {
            return nil
        }
        return String(text[range])
    }

    // MARK: - Email Detection

    static func isEmail(_ text: String) -> Bool {
        let emailPattern = #"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"#
        return text.range(of: emailPattern, options: .regularExpression) != nil
    }

    static func extractEmail(_ text: String) -> String? {
        let emailPattern = #"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"#
        guard let range = text.range(of: emailPattern, options: .regularExpression) else {
            return nil
        }
        return String(text[range])
    }

    // MARK: - Time/Date Detection

    static func containsTimeKeywords(_ text: String) -> Bool {
        let timeKeywords = [
            "tomorrow", "today", "tonight", "yesterday",
            "morning", "afternoon", "evening", "noon",
            "pm", "am", "o'clock",
            "monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday",
            "mon", "tue", "wed", "thu", "fri", "sat", "sun",
            "next week", "this week", "last week",
            "next month", "this month", "last month",
            "january", "february", "march", "april", "may", "june",
            "july", "august", "september", "october", "november", "december",
            "jan", "feb", "mar", "apr", "may", "jun",
            "jul", "aug", "sep", "oct", "nov", "dec"
        ]

        let lowercaseText = text.lowercased()
        return timeKeywords.contains { keyword in
            lowercaseText.contains(keyword)
        }
    }

    static func containsTimeFormats(_ text: String) -> Bool {
        let timePatterns = [
            #"\d{1,2}:\d{2}\s*(am|pm)?"#,  // 3:30pm, 15:30
            #"\d{1,2}\s*(am|pm)"#,         // 3pm, 11am
            #"\d{1,2}/\d{1,2}/\d{2,4}"#,   // 12/25/2024
            #"\d{1,2}-\d{1,2}-\d{2,4}"#    // 12-25-2024
        ]

        return timePatterns.contains { pattern in
            text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
        }
    }

    static func containsDateOrTime(_ text: String) -> Bool {
        return containsTimeKeywords(text) || containsTimeFormats(text)
    }

    // MARK: - Location Detection

    static func isLocation(_ text: String) -> Bool {
        return containsAddressPattern(text) || containsLocationKeywords(text)
    }

    static func containsAddressPattern(_ text: String) -> Bool {
        let addressPatterns = [
            #"\d+\s+\w+\s+(street|st|avenue|ave|road|rd|drive|dr|boulevard|blvd|lane|ln|way|court|ct|place|pl)\b"#,
            #"\b\d{5}(-\d{4})?\b"#  // ZIP codes
        ]

        return addressPatterns.contains { pattern in
            text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
        }
    }

    static func containsLocationKeywords(_ text: String) -> Bool {
        let locationKeywords = [
            "at ", "near ", "in ", "on ",
            "restaurant", "cafe", "store", "shop", "mall",
            "office", "building", "hotel", "airport", "station",
            "park", "beach", "downtown", "uptown"
        ]

        let lowercaseText = text.lowercased()
        return locationKeywords.contains { keyword in
            lowercaseText.contains(keyword)
        }
    }

    // MARK: - Name Detection

    static func containsPersonName(_ text: String) -> Bool {
        // Simple heuristics for person names
        let namePatterns = [
            #"\b[A-Z][a-z]+\s+[A-Z][a-z]+"#,  // First Last
            #"\b(mr|mrs|ms|dr|prof)\.\s+[A-Z][a-z]+"#  // Title + Name
        ]

        return namePatterns.contains { pattern in
            text.range(of: pattern, options: .regularExpression) != nil
        }
    }

    // MARK: - Raw Data Detection

    static func isRawData(_ text: String) -> Bool {
        // Check if the text is just raw data without context
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Phone number only
        if isPhoneNumber(trimmedText) && trimmedText.count < 20 {
            return true
        }

        // Email only
        if isEmail(trimmedText) && trimmedText.count < 50 {
            return true
        }

        // Just numbers (could be ID, account number, etc.)
        if trimmedText.allSatisfy({ $0.isNumber || $0.isWhitespace || "-.".contains($0) }) {
            return true
        }

        return false
    }

    // MARK: - URL Detection

    static func containsURL(_ text: String) -> Bool {
        let urlPattern = #"https?://[^\s]+"#
        return text.range(of: urlPattern, options: .regularExpression) != nil
    }

    static func extractURLs(_ text: String) -> [String] {
        let urlPattern = #"https?://[^\s]+"#
        var urls: [String] = []

        do {
            let regex = try NSRegularExpression(pattern: urlPattern, options: [])
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))

            for match in matches {
                if let range = Range(match.range, in: text) {
                    urls.append(String(text[range]))
                }
            }
        } catch {
            print("Error creating regex for URL extraction: \(error)")
        }

        return urls
    }

    // MARK: - Content Classification Helpers

    static func getDetectedDataTypes(_ text: String) -> [DetectedDataType] {
        var types: [DetectedDataType] = []

        if isPhoneNumber(text) {
            types.append(.phoneNumber)
        }

        if isEmail(text) {
            types.append(.email)
        }

        if containsDateOrTime(text) {
            types.append(.dateTime)
        }

        if isLocation(text) {
            types.append(.location)
        }

        if containsPersonName(text) {
            types.append(.personName)
        }

        if containsURL(text) {
            types.append(.url)
        }

        return types
    }

    // MARK: - Priority Determination

    static func getActionPriority(for text: String, entryType: EntryType) -> ActionPriority {
        switch entryType {
        case .todo:
            if containsDateOrTime(text) {
                return .calendar  // TODOs with time should go to calendar
            } else {
                return .reminders  // Other TODOs go to reminders
            }

        case .thought, .piece:
            if isPhoneNumber(text) {
                return .contacts
            } else if isEmail(text) {
                return .contacts
            } else if isLocation(text) {
                return .maps
            } else {
                return .research  // General pieces get research
            }
        }
    }
}

// MARK: - Supporting Types

enum DetectedDataType: String, CaseIterable {
    case phoneNumber = "phone_number"
    case email = "email"
    case dateTime = "date_time"
    case location = "location"
    case personName = "person_name"
    case url = "url"

    var displayName: String {
        switch self {
        case .phoneNumber: return "Phone Number"
        case .email: return "Email"
        case .dateTime: return "Date/Time"
        case .location: return "Location"
        case .personName: return "Person Name"
        case .url: return "URL"
        }
    }
}

enum ActionPriority {
    case reminders    // Add to Apple Reminders
    case calendar     // Add to Calendar
    case contacts     // Add to Contacts
    case maps         // Save to Maps
    case research     // Generate AI research only

    var actionType: AIActionType? {
        switch self {
        case .reminders: return .appleReminders
        case .calendar: return .calendar
        case .contacts: return .contacts
        case .maps: return .maps
        case .research: return nil  // Research doesn't create an action
        }
    }
}

// MARK: - Extraction Helpers

extension PatternMatcher {
    /// Extract structured data from text based on detected patterns
    static func extractStructuredData(_ text: String) -> StructuredData {
        var data = StructuredData()

        // Extract phone numbers
        if let phone = extractPhoneNumber(text) {
            data.phoneNumber = phone
        }

        // Extract emails
        if let email = extractEmail(text) {
            data.email = email
        }

        // Extract URLs
        data.urls = extractURLs(text)

        // Extract potential names (simple heuristic)
        if containsPersonName(text) {
            data.personName = extractPotentialName(text)
        }

        return data
    }

    private static func extractPotentialName(_ text: String) -> String? {
        let namePattern = #"\b[A-Z][a-z]+\s+[A-Z][a-z]+"#
        guard let range = text.range(of: namePattern, options: .regularExpression) else {
            return nil
        }
        return String(text[range])
    }
}

struct StructuredData {
    var phoneNumber: String?
    var email: String?
    var personName: String?
    var urls: [String] = []

    var hasContactInfo: Bool {
        return phoneNumber != nil || email != nil
    }

    var primaryContactInfo: String? {
        return phoneNumber ?? email
    }
}