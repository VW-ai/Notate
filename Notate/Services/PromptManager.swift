import Foundation

/// Centralized management of AI prompts for consistency and easy updates
struct PromptManager {

    // MARK: - Research Generation Prompts

    static func todoResearchPrompt(content: String, userContext: UserContext? = nil) -> String {
        let contextInfo = buildContextInfo(userContext)

        return """
        Research this TODO and create a helpful markdown guide: "\(content)"

        Provide practical information including:
        - Nearby locations if relevant\(contextInfo.location)
        - Best practices or tips
        - Tools, apps, or resources that could help
        - Time-saving strategies
        - Cost estimates if applicable

        Format as markdown with clear sections. Be concise but thorough.
        Limit to 300 words maximum.
        Focus on actionable advice that helps complete the task efficiently.
        """
    }

    static func pieceResearchPrompt(content: String, userContext: UserContext? = nil) -> String {
        let contextInfo = buildContextInfo(userContext)

        return """
        Research this topic and create a helpful markdown summary: "\(content)"

        Provide relevant information including:
        - Context or background information
        - Related concepts or connections
        - Useful resources for learning more
        - Practical applications
        - Current trends or developments (if applicable)

        Format as markdown with clear sections. Be informative and well-organized.
        Limit to 300 words maximum.
        Focus on educational value and practical insights.
        """
    }

    // MARK: - Content Analysis Prompts

    static func contentClassificationPrompt(content: String, userContext: UserContext? = nil) -> String {
        return """
        Analyze this user input for extractable data and actionable insights:

        Input: "\(content)"

        Identify any of the following:
        1. Phone numbers (any format)
        2. Email addresses
        3. Dates or times (relative or absolute)
        4. Locations or addresses
        5. Person names
        6. URLs or web links
        7. Task urgency indicators
        8. Priority keywords

        Return a JSON object with:
        {
          "detected_types": ["phone_number", "date_time", ...],
          "extracted_data": {
            "phone": "555-123-4567",
            "person_name": "John Doe",
            "urgency": "high|medium|low"
          },
          "confidence": 0.95,
          "reasoning": "Brief explanation of what was detected"
        }

        Only include fields that are actually detected. Be conservative with confidence scores.
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
        I need to search for information about: "\(query)"

        Please provide a comprehensive research summary in markdown format that includes:

        ## Key Information
        - Main facts and details about the topic
        - Important considerations or tips
        - Current trends or developments

        ## Resources and Sources
        - Relevant websites or services
        - Where to find more information
        - Official sources or documentation

        ## Practical Guidance
        - Actionable recommendations
        - Best practices to follow
        - Common mistakes to avoid

        ## Next Steps
        - Specific actions to take
        - Things to consider or investigate further
        - Who to contact for additional help

        Format the response as structured markdown with clear sections and bullet points.
        Focus on providing practical, actionable information that helps the user move forward.
        Limit to 400 words maximum while being comprehensive.
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
        let metrics = PromptMetrics(
            promptType: type,
            version: promptVersion,
            responseTime: responseTime,
            userRating: rating,
            timestamp: Date()
        )

        // TODO: Implement prompt analytics storage
        print("📊 Prompt metrics: \(type) - \(responseTime)ms - rating: \(rating ?? 0)")
    }
}