import Foundation

/// AI-native content extractor that attempts to extract all possible information types from text
@MainActor
class AIContentExtractor {
    private let aiService: AIService
    private var extractionCache: [String: CachedExtraction] = [:]

    init(aiService: AIService) {
        self.aiService = aiService
    }

    // MARK: - Main Extraction Method

    /// Extract all possible information from text using AI
    func extractAllInformation(_ text: String) async -> ExtractedInformation {
        let cacheKey = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Check cache first
        if let cached = extractionCache[cacheKey], !cached.isExpired {
            return cached.information
        }

        guard aiService.isConfigured else {
            return fallbackExtraction(text)
        }

        let prompt = """
        You are Claude 4.5 extracting structured data for Notate.

        Input: "\(text)"

        Capture every actionable detail, even when phrased informally or with typos:
        1. Phone numbers (any format, partials included)
        2. Email addresses
        3. People names or references (nicknames, initials)
        4. Date/time information (normalize to ISO 8601 when possible; resolve relative terms cautiously)
        5. Location hints (addresses, venues, neighborhoods)
        6. Action intents (call, follow up, schedule, buy, research, etc.)
        7. URLs or digital resources
        8. Any other structured facts that aid automation

        Return strict JSON:
        {
            "phoneNumber": "string or null",
            "email": "string or null",
            "personName": "string or null",
            "timeInfo": "normalized date/time string or null",
            "locationInfo": "location description or null",
            "actionIntent": "specific action verb or null",
            "urls": ["array of urls"],
            "otherData": "any other structured info or null"
        }

        Use null when evidence is weak. Do not add extra keys. Ensure the JSON parses without modification.
        """

        do {
            let response = try await aiService.quickExtraction(prompt)
            let extracted = parseExtractionResponse(response) ?? fallbackExtraction(text)

            // Cache the result
            extractionCache[cacheKey] = CachedExtraction(information: extracted)

            return extracted
        } catch {
            print("AI extraction failed: \(error)")
            return fallbackExtraction(text)
        }
    }

    // MARK: - Decision Methods for Actions

    /// Should create a reminder based on extracted information
    func shouldCreateReminder(_ info: ExtractedInformation, entryType: EntryType) -> Bool {
        // For TODOs, always create reminders
        if entryType == .todo {
            return true
        }

        // For pieces, create reminder if there's an action intent
        return info.actionIntent != nil
    }

    /// Should create a calendar event based on extracted information
    func shouldCreateCalendarEvent(_ info: ExtractedInformation) -> Bool {
        // Create calendar event if we have time information
        // Action intent is helpful but not required - meetings often don't have explicit action verbs
        return info.timeInfo != nil
    }

    /// Should create a contact based on extracted information
    func shouldCreateContact(_ info: ExtractedInformation) -> Bool {
        // Create contact if we have contact info (phone OR email)
        // Person name is helpful but not required - we can use "Unknown Contact" as fallback
        return info.phoneNumber != nil || info.email != nil
    }

    /// Should open maps based on extracted information
    func shouldOpenMaps(_ info: ExtractedInformation) -> Bool {
        // Open maps if we have location info
        return info.locationInfo != nil
    }

    /// Should generate research (for non-raw data)
    func shouldGenerateResearch(_ info: ExtractedInformation, text: String) -> Bool {
        // Don't generate research for simple raw data
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // If it's just a phone number or email, skip research
        if trimmed.count < 30 && (info.phoneNumber != nil || info.email != nil) && info.actionIntent == nil {
            return false
        }

        return true
    }

    // MARK: - Fallback Extraction (simple regex for when AI fails)

    private func fallbackExtraction(_ text: String) -> ExtractedInformation {
        var info = ExtractedInformation()

        // Simple phone extraction
        if let phoneRange = text.range(of: #"\+?[\d\s\-\(\)]{10,}"#, options: .regularExpression) {
            info.phoneNumber = String(text[phoneRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Simple email extraction
        if let emailRange = text.range(of: #"\S+@\S+\.\S+"#, options: .regularExpression) {
            info.email = String(text[emailRange])
        }

        // Simple URL extraction
        let urlPattern = #"https?://\S+"#
        if text.range(of: urlPattern, options: .regularExpression) != nil {
            do {
                let regex = try NSRegularExpression(pattern: urlPattern)
                let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
                info.urls = matches.compactMap { match in
                    Range(match.range, in: text).map { String(text[$0]) }
                }
            } catch {
                print("URL extraction error: \(error)")
            }
        }

        return info
    }

    // MARK: - Response Parsing

    private func parseExtractionResponse(_ response: String) -> ExtractedInformation? {
        guard let data = response.data(using: .utf8) else { return nil }

        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

            var info = ExtractedInformation()
            info.phoneNumber = json?["phoneNumber"] as? String
            info.email = json?["email"] as? String
            info.personName = json?["personName"] as? String
            info.timeInfo = json?["timeInfo"] as? String
            info.locationInfo = json?["locationInfo"] as? String
            info.actionIntent = json?["actionIntent"] as? String
            info.urls = json?["urls"] as? [String] ?? []
            info.otherData = json?["otherData"] as? String

            return info
        } catch {
            print("Failed to parse AI extraction response: \(error)")
            return nil
        }
    }
}

// MARK: - Supporting Types

struct ExtractedInformation {
    var phoneNumber: String?
    var email: String?
    var personName: String?
    var timeInfo: String?
    var locationInfo: String?
    var actionIntent: String?
    var urls: [String] = []
    var otherData: String?

    var hasContactInfo: Bool {
        return phoneNumber != nil || email != nil
    }

    var hasTimeInfo: Bool {
        return timeInfo != nil
    }

    var hasLocationInfo: Bool {
        return locationInfo != nil
    }

    var hasActionIntent: Bool {
        return actionIntent != nil
    }
}

struct CachedExtraction {
    let information: ExtractedInformation
    let timestamp: Date

    init(information: ExtractedInformation) {
        self.information = information
        self.timestamp = Date()
    }

    var isExpired: Bool {
        // Cache for 5 minutes
        Date().timeIntervalSince(timestamp) > 300
    }
}
