import Foundation

/// Centralized management of AI prompts for consistency and easy updates
struct PromptManager {

    // MARK: - Research Generation Prompts

    static func todoResearchPrompt(content: String, userContext: UserContext? = nil) -> String {
        let contextInfo = buildContextInfo(userContext)

        return """
        You are Claude 4.5 embedded in Notate. Analyze this TODO: "\(content)"

        Produce a tight markdown briefing (≈180 words max) that:
        - Surfaces the core objective, blockers, and timing signals\(contextInfo.timeContext)
        - Suggests high-leverage next steps or quick wins with clear ownership
        - Recommends tools, venues, or contacts that accelerate progress\(contextInfo.location)
        - Highlights risks, costs, or dependencies only if they influence action

        Structure freely, but begin with a "Snapshot" bullet list (3 bullet max) before deeper guidance.
        Keep sentences crisp, avoid filler, and tailor advice directly to the captured text.
        """
    }

    static func pieceResearchPrompt(content: String, userContext: UserContext? = nil) -> String {
        let contextInfo = buildContextInfo(userContext)

        return """
        You are Claude 4.5, researching this entry for Notate: "\(content)"

        Craft an insight-rich markdown summary (target 200 words or less) that:
        - Explains why the topic matters right now, referencing context when relevant\(contextInfo.location)\(contextInfo.timeContext)
        - Surfaces standout insights, frameworks, or examples useful to the user
        - Points to standout resources or experts worth a follow-up
        - Suggests one or two concrete next steps or experiments

        Use flexible headings that best fit the material. Lead with a "Key Takeaways" section (3 concise bullets) before elaborating.
        """
    }

    // MARK: - Content Analysis Prompts

    static func contentClassificationPrompt(content: String, userContext: UserContext? = nil) -> String {
        return """
        Act as Claude 4.5 extracting structured data for Notate.

        Input: "\(content)"

        Capture every actionable element (phones, emails, names, companies, dates/times, locations, URLs, commitments, follow-ups, urgency cues).
        Normalize dates/times to ISO 8601 when possible and resolve relative phrases conservatively.
        Provide short reasoning for classification via the confidence fields.

        Return strict JSON in this shape:
        {
          "detected_types": ["phone_number", ...],
          "extracted_data": {
            "phone": "555-123-4567",
            "person_name": "John Doe",
            "urgency": "high|medium|low"
          },
          "confidence": 0.95,
          "reasoning": "Brief explanation of what was detected"
        }

        Omit keys you cannot support. Keep the JSON human-checkable and machine-parseable.
        """
    }

    // MARK: - Smart Action Prompts

    static func calendarEventPrompt(content: String) -> String {
        return """
        Extract calendar event information from this text: "\(content)"

        Extract:
        - Event title (clean, descriptive)
        - Date/time information
        - Duration estimate
        - Location (if mentioned)
        - Notes or additional context

        Return JSON:
        {
          "title": "Meeting with John",
          "date_time": "2024-01-15T14:30:00Z",
          "duration_minutes": 60,
          "location": "Conference Room A",
          "notes": "Discuss project timeline",
          "confidence": 0.9
        }

        Use ISO 8601 format for date_time. If time is relative (like "tomorrow"), calculate actual date.
        """
    }

    static func contactExtractionPrompt(content: String) -> String {
        return """
        Extract contact information from this text: "\(content)"

        Extract:
        - Full name (if available)
        - Phone number(s)
        - Email address(es)
        - Title or role (if mentioned)
        - Company or organization (if mentioned)
        - Additional context

        Return JSON:
        {
          "name": "John Doe",
          "phone": "555-123-4567",
          "email": "john@example.com",
          "title": "Project Manager",
          "company": "Tech Corp",
          "notes": "Met at conference",
          "confidence": 0.9
        }

        Only include fields that are clearly mentioned. Use "Unknown Contact" if no name is provided.
        """
    }

    static func webSearchPrompt(query: String) -> String {
        return """
        You are Claude 4.5 with full research latitude. Investigate: "\(query)"

        Deliver a focused markdown brief (≤220 words) that:
        - Leads with a "Snapshot" section (3 punchy bullets capturing the most valuable findings)
        - Highlights the most credible insights, emerging angles, or contrarian signals
        - Mentions notable sources inline (site or organization names suffice)
        - Suggests practical follow-up moves tailored to someone acting on this query

        Shape the remaining sections around what the topic truly needs—no rigid template. Use tables or short lists only when they sharpen clarity.
        """
    }

    // MARK: - Enhanced Research Prompts

    static func contextualResearchPrompt(content: String, detectedType: ContentType, userContext: UserContext? = nil) -> String {
        let contextInfo = buildContextInfo(userContext)

        switch detectedType {
        case .learningTopic:
            return learningResearchPrompt(content: content, contextInfo: contextInfo)
        case .shoppingTask:
            return shoppingResearchPrompt(content: content, contextInfo: contextInfo)
        case .locationBased:
            return locationResearchPrompt(content: content, contextInfo: contextInfo)
        case .workTask:
            return workTaskResearchPrompt(content: content, contextInfo: contextInfo)
        case .personalCare:
            return personalCareResearchPrompt(content: content, contextInfo: contextInfo)
        case .general:
            return generalResearchPrompt(content: content, contextInfo: contextInfo)
        }
    }

    // MARK: - Specialized Research Prompts

    private static func learningResearchPrompt(content: String, contextInfo: ContextInfo) -> String {
        return """
        Create a learning guide for: "\(content)"

        Structure your response as:
        # Learning Path: [Topic]

        ## Getting Started
        - Prerequisites or background needed
        - Recommended starting resources

        ## Core Resources
        - Official documentation/courses
        - Best tutorials or books
        - Practice platforms or exercises

        ## Advanced Learning
        - Advanced topics to explore
        - Professional certifications
        - Community resources

        ## Practical Application
        - Project ideas to practice
        - Real-world use cases
        - Portfolio building tips

        Keep it concise but comprehensive. Focus on quality over quantity of resources.
        """
    }

    private static func shoppingResearchPrompt(content: String, contextInfo: ContextInfo) -> String {
        return """
        Create a shopping guide for: "\(content)"

        # Shopping Guide: [Item]

        ## Where to Buy\(contextInfo.location)
        - Best local stores or chains
        - Online retailers with good prices
        - Specialty stores if needed

        ## Price Comparison
        - Typical price ranges
        - Best times to buy (sales, seasons)
        - Brand recommendations (budget vs premium)

        ## What to Look For
        - Key features or specifications
        - Quality indicators
        - Common pitfalls to avoid

        ## Money-Saving Tips
        - Coupons or discount strategies
        - Bulk buying considerations
        - Alternative options

        Focus on practical, actionable advice for smart purchasing.
        """
    }

    private static func locationResearchPrompt(content: String, contextInfo: ContextInfo) -> String {
        return """
        Create a location guide for: "\(content)"

        # Location Guide: [Place/Activity]

        ## Nearby Options\(contextInfo.location)
        - Top-rated venues or locations
        - Distance and accessibility
        - Hours of operation

        ## What to Expect
        - Typical experience or offerings
        - Price ranges
        - Best times to visit

        ## Preparation Tips
        - What to bring or wear
        - Reservations or bookings needed
        - Transportation options

        ## Insider Tips
        - Local recommendations
        - Hidden gems or alternatives
        - Things to avoid

        Provide practical, local-focused advice.
        """
    }

    private static func workTaskResearchPrompt(content: String, contextInfo: ContextInfo) -> String {
        return """
        Create a work task guide for: "\(content)"

        # Task Completion Guide: [Task]

        ## Approach & Strategy
        - Best practices for this type of task
        - Common methodologies or frameworks
        - Time estimation

        ## Tools & Resources
        - Recommended software or platforms
        - Templates or examples
        - Reference materials

        ## Step-by-Step Process
        - Logical workflow or sequence
        - Key milestones or checkpoints
        - Quality assurance tips

        ## Potential Challenges
        - Common obstacles and solutions
        - Risk mitigation strategies
        - When to seek help

        Focus on efficiency and professional execution.
        """
    }

    private static func personalCareResearchPrompt(content: String, contextInfo: ContextInfo) -> String {
        return """
        Create a personal care guide for: "\(content)"

        # Personal Care Guide: [Activity/Need]

        ## Getting Started
        - Basic requirements or preparation
        - When and how often to do this
        - Safety considerations

        ## Options & Approaches\(contextInfo.location)
        - DIY vs professional options
        - Local services or providers
        - Product recommendations

        ## Cost Considerations
        - Typical price ranges
        - Budget-friendly alternatives
        - Value for money options

        ## Tips for Success
        - Best practices
        - Common mistakes to avoid
        - Maintenance or follow-up

        Provide practical, health-conscious advice.
        """
    }

    private static func generalResearchPrompt(content: String, contextInfo: ContextInfo) -> String {
        return """
        Research and provide helpful information about: "\(content)"

        # Information Guide: [Topic]

        ## Overview
        - What this is and why it matters
        - Current relevance or trends
        - Key facts or statistics

        ## Practical Information
        - How to get started or involved
        - Resources for more information
        - Common applications or uses

        ## Considerations
        - Benefits and limitations
        - Costs or requirements
        - Alternatives to consider

        ## Next Steps
        - Recommended actions
        - Where to learn more
        - Who to contact for help

        Provide balanced, informative content that helps decision-making.
        """
    }

    // MARK: - Utility Methods

    private static func buildContextInfo(_ userContext: UserContext?) -> ContextInfo {
        guard let context = userContext else {
            return ContextInfo(location: "", timeContext: "")
        }

        let locationInfo = context.location.map { " (near \($0))" } ?? ""
        let timeInfo = context.timeOfDay.map { " (\($0))" } ?? ""

        return ContextInfo(location: locationInfo, timeContext: timeInfo)
    }
}

// MARK: - Supporting Types

struct UserContext {
    let location: String?
    let timeOfDay: String?
    let previousEntries: [String]?
    let userPreferences: [String: String]?

    init(location: String? = nil, timeOfDay: String? = nil, previousEntries: [String]? = nil, userPreferences: [String: String]? = nil) {
        self.location = location
        self.timeOfDay = timeOfDay
        self.previousEntries = previousEntries
        self.userPreferences = userPreferences
    }
}

private struct ContextInfo {
    let location: String
    let timeContext: String
}

enum ContentType: String, CaseIterable {
    case learningTopic = "learning_topic"
    case shoppingTask = "shopping_task"
    case locationBased = "location_based"
    case workTask = "work_task"
    case personalCare = "personal_care"
    case general = "general"

    var displayName: String {
        switch self {
        case .learningTopic: return "Learning"
        case .shoppingTask: return "Shopping"
        case .locationBased: return "Location"
        case .workTask: return "Work Task"
        case .personalCare: return "Personal Care"
        case .general: return "General"
        }
    }
}

// MARK: - Prompt Templates

extension PromptManager {

    /// Generate a system prompt for maintaining conversation context
    static func systemPrompt() -> String {
        return """
        You are a helpful AI assistant integrated into Notate, a productivity app for capturing and organizing thoughts and tasks.

        Guidelines:
        - Provide practical, actionable advice
        - Keep responses concise but comprehensive
        - Use markdown formatting for better readability
        - Focus on local and immediately useful information
        - Respect user privacy and data
        - Be encouraging and supportive in tone

        Your primary goal is to help users be more productive and informed about their captured content.
        """
    }

    /// Generate a prompt for testing API connectivity
    static func connectionTestPrompt() -> String {
        return "Respond with exactly one word: 'Connected'"
    }

    /// Generate a prompt for validating API responses
    static func validationPrompt(for content: String) -> String {
        return """
        Validate this content for helpfulness and accuracy: "\(content)"

        Return a simple JSON response:
        {
          "is_valid": true,
          "quality_score": 0.9,
          "issues": []
        }
        """
    }
}

// MARK: - Prompt Versioning

extension PromptManager {
    static let promptVersion = "v1.0"

    /// Track prompt performance for optimization
    struct PromptMetrics {
        let promptType: String
        let version: String
        let responseTime: TimeInterval
        let userRating: Double?
        let timestamp: Date
    }

    /// Log prompt usage for analytics
    static func logPromptUsage(_ type: String, responseTime: TimeInterval, rating: Double? = nil) {
        // TODO: Implement prompt analytics storage
        print("📊 Prompt metrics: \(type) - \(responseTime)ms - rating: \(rating ?? 0)")
    }
}
