# Unified AI Implementation Guide for Notate

## Product Vision

Transform Notate into an intelligent assistant that **executes actions** based on user intent. The system uses existing triggers to determine content type (TODO vs PIECE) and autonomously executes appropriate tool actions while providing helpful research via AI-generated markdown summaries.

## Core Principles

### 1. Trigger-Based Classification (No AI Classification Needed)
User intent is explicit through trigger choice:
- `///` → **TODO** (actionable items)
- `,,,` → **PIECE** (information, thoughts, data)

### 2. Autonomous Tool Execution
AI agent has full access to system tools and auto-executes appropriate actions:
- **Apple Reminders** for TODOs
- **Calendar** for time-based content
- **Contacts** for phone numbers/emails
- **Maps** for locations
- **Web Search** with markdown research summaries

### 3. Research-Focused AI
AI provides value through **intelligent research and organization**, not classification:
- Generate helpful markdown summaries
- Organize web search results
- Provide actionable insights

## Technical Architecture

### Simplified Data Model

#### Entry Metadata (Focused on Actions & Research)
```json
{
  "ai_actions": [
    {
      "id": "action_001",
      "type": "apple_reminders",
      "status": "executed",
      "data": {
        "reminder_id": "ABC123",
        "title": "Buy milk",
        "due_date": "2024-01-15T14:30:00Z"
      },
      "executed_at": "2024-01-15T10:05:00Z",
      "reversible": true,
      "reverse_data": {
        "reminder_existed": false
      }
    },
    {
      "id": "action_002",
      "type": "web_search",
      "status": "executed",
      "data": {
        "query": "best grocery stores NYC",
        "results_stored": true
      },
      "executed_at": "2024-01-15T10:06:00Z",
      "reversible": false
    }
  ],

  "research_results": {
    "format": "markdown",
    "content": "# Grocery Shopping Research\n\n## Nearby Options\n- **Whole Foods** (0.3 mi) - Organic focus, open until 10pm\n- **Safeway** (0.8 mi) - 24 hours, good prices\n\n## Money Saving Tips\n- Store brands are 20-30% cheaper\n- Shop Tuesday evenings for best discounts\n\n## Delivery Options\n- Instacart - 2 hour delivery\n- Amazon Fresh - Same day if ordered by 2pm",
    "generated_at": "2024-01-15T10:07:00Z",
    "research_cost": 0.003
  },

  "processing_meta": {
    "processed_at": "2024-01-15T10:05:00Z",
    "processing_version": "v1.0",
    "total_cost": 0.003,
    "processing_time_ms": 2100
  }
}
```

### Swift Data Models

```swift
// MARK: - Main AI Metadata Structure
struct AIMetadata: Codable {
    var actions: [AIAction] = []
    var researchResults: ResearchResults?
    var processingMeta: ProcessingMeta?
}

// MARK: - AI Actions
struct AIAction: Codable {
    let id: String
    let type: AIActionType
    var status: ActionStatus
    let data: [String: FlexibleCodable]
    let executedAt: Date?
    let reversible: Bool
    let reverseData: [String: FlexibleCodable]?
}

enum AIActionType: String, CaseIterable, Codable {
    case appleReminders = "apple_reminders"
    case calendar = "calendar"
    case contacts = "contacts"
    case maps = "maps"
    case webSearch = "web_search"
}

enum ActionStatus: String, Codable {
    case pending, executing, executed, failed, reversed
}

// MARK: - Research Results
struct ResearchResults: Codable {
    let format: ResultFormat = .markdown
    let content: String
    let generatedAt: Date
    let researchCost: Double
}

enum ResultFormat: String, Codable {
    case markdown
}

// MARK: - Processing Metadata
struct ProcessingMeta: Codable {
    let processedAt: Date
    let processingVersion: String
    let totalCost: Double
    let processingTimeMs: Int
}
```

### Service Architecture

```swift
// MARK: - Autonomous AI Agent
@MainActor
class AutonomousAIAgent: ObservableObject {
    private let aiService: AIService
    private let toolService: ToolService
    private let cacheService: AICacheService

    func processEntry(_ entry: Entry) async {
        // No classification needed - use trigger type
        switch entry.type {
        case .todo:
            await processTodo(entry)
        case .thought:
            await processPiece(entry)
        }
    }

    private func processTodo(_ entry: Entry) async {
        var actions: [AIAction] = []

        // 1. Always add to Apple Reminders
        if let reminderAction = await addToReminders(entry.content) {
            actions.append(reminderAction)
        }

        // 2. Check for time components and add to Calendar
        if containsTimeKeywords(entry.content) {
            if let calendarAction = await addToCalendar(entry.content) {
                actions.append(calendarAction)
            }
        }

        // 3. Research and generate markdown summary
        let research = await generateTodoResearch(entry.content)

        // 4. Save all results
        let metadata = AIMetadata(
            actions: actions,
            researchResults: research,
            processingMeta: ProcessingMeta(
                processedAt: Date(),
                processingVersion: "v1.0",
                totalCost: research?.researchCost ?? 0,
                processingTimeMs: 0
            )
        )

        await saveAIMetadata(metadata, for: entry)
    }

    private func processPiece(_ entry: Entry) async {
        var actions: [AIAction] = []

        // 1. Pattern matching for specific data types
        if isPhoneNumber(entry.content) {
            if let contactAction = await addToContacts(entry.content) {
                actions.append(contactAction)
            }
        }

        if isLocation(entry.content) {
            if let mapAction = await saveToMaps(entry.content) {
                actions.append(mapAction)
            }
        }

        // 2. Research if it's not just raw data
        var research: ResearchResults?
        if !isRawData(entry.content) {
            research = await generatePieceResearch(entry.content)
        }

        // 3. Save results
        let metadata = AIMetadata(
            actions: actions,
            researchResults: research,
            processingMeta: ProcessingMeta(
                processedAt: Date(),
                processingVersion: "v1.0",
                totalCost: research?.researchCost ?? 0,
                processingTimeMs: 0
            )
        )

        await saveAIMetadata(metadata, for: entry)
    }
}

// MARK: - Pattern Matching (No AI)
extension AutonomousAIAgent {
    private func isPhoneNumber(_ text: String) -> Bool {
        let phoneRegex = #"(\+?\d{1,3}[\s.-]?)?\(?[\d\s.-]{10,}\)?"#
        return text.range(of: phoneRegex, options: .regularExpression) != nil
    }

    private func containsTimeKeywords(_ text: String) -> Bool {
        let timeKeywords = ["tomorrow", "today", "tonight", "morning", "afternoon", "evening", "pm", "am", "o'clock", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
        return timeKeywords.contains { text.lowercased().contains($0) }
    }

    private func isLocation(_ text: String) -> Bool {
        // Check for address patterns, "at [place]", etc.
        let locationPatterns = ["\\d+\\s+\\w+\\s+(street|st|avenue|ave|road|rd|drive|dr)", "at\\s+[A-Z]"]
        return locationPatterns.contains { pattern in
            text.range(of: pattern, options: .regularExpression) != nil
        }
    }

    private func isRawData(_ text: String) -> Bool {
        // Phone numbers, emails, addresses without context
        return isPhoneNumber(text) || isEmail(text) || isJustAnAddress(text)
    }
}

// MARK: - Tool Service
class ToolService {
    func addToReminders(_ content: String) async -> AIAction? {
        // EventKit Reminders integration
        // Parse dates from content using simple keyword matching
    }

    func addToCalendar(_ content: String) async -> AIAction? {
        // EventKit Calendar integration
        // Extract time/date information
    }

    func addToContacts(_ content: String) async -> AIAction? {
        // Contacts framework integration
        // Extract name and phone number
    }

    func saveToMaps(_ content: String) async -> AIAction? {
        // MapKit integration or bookmark creation
    }
}

// MARK: - AI Research Service
class AIService {
    private let apiKey: String
    private let baseURL = "https://api.anthropic.com/v1/messages"

    func generateTodoResearch(_ content: String) async throws -> ResearchResults {
        let prompt = """
        Research this TODO and create a helpful markdown guide: "\(content)"

        Provide practical information including:
        - Nearby locations if relevant
        - Best practices or tips
        - Tools, apps, or resources that could help
        - Time-saving strategies

        Format as markdown with clear sections. Be concise but thorough.
        """

        let response = try await makeAPICall(prompt: prompt, model: "claude-3-haiku-20240307")

        return ResearchResults(
            content: response,
            generatedAt: Date(),
            researchCost: 0.003
        )
    }

    func generatePieceResearch(_ content: String) async throws -> ResearchResults {
        let prompt = """
        Research this topic and create a helpful markdown summary: "\(content)"

        Provide relevant information including:
        - Context or background information
        - Related concepts or connections
        - Useful resources for learning more
        - Practical applications

        Format as markdown. Be informative and well-organized.
        """

        let response = try await makeAPICall(prompt: prompt, model: "claude-3-haiku-20240307")

        return ResearchResults(
            content: response,
            generatedAt: Date(),
            researchCost: 0.003
        )
    }

    private func makeAPICall(prompt: String, model: String) async throws -> String {
        // Claude API implementation
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let requestBody = [
            "model": model,
            "max_tokens": 1000,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let content = response["content"] as! [[String: Any]]
        return content[0]["text"] as! String
    }
}
```

### Database Integration

```swift
extension DatabaseManager {
    // MARK: - AI Metadata Management
    func updateAIMetadata(_ entry: Entry, metadata: AIMetadata) {
        var updatedEntry = entry

        // Serialize AIMetadata to Entry.metadata
        if let aiData = try? JSONEncoder().encode(metadata) {
            var entryMetadata = updatedEntry.metadata ?? [:]
            entryMetadata["ai"] = FlexibleCodable(aiData.base64EncodedString())
            updatedEntry.metadata = entryMetadata

            updateEntry(updatedEntry)
        }
    }

    func getAIMetadata(for entry: Entry) -> AIMetadata? {
        guard let metadataDict = entry.metadata,
              let aiDataString = metadataDict["ai"]?.wrappedValue as? String,
              let aiData = Data(base64Encoded: aiDataString) else {
            return nil
        }

        return try? JSONDecoder().decode(AIMetadata.self, from: aiData)
    }

    // MARK: - AI Queries
    func getEntriesNeedingAIProcessing() -> [Entry] {
        return entries.filter { entry in
            getAIMetadata(for: entry) == nil
        }
    }

    func getEntriesWithActions() -> [Entry] {
        return entries.filter { entry in
            guard let aiMetadata = getAIMetadata(for: entry) else { return false }
            return !aiMetadata.actions.isEmpty
        }
    }
}
```

## Processing Examples

### TODO: "Buy milk tomorrow"
**Auto-Executed Actions:**
1. Add to Apple Reminders with "tomorrow" date
2. Web search for grocery information

**Generated Research:**
```markdown
# Grocery Shopping: Milk

## Nearby Options
- **Whole Foods** (0.3 mi) - Organic selection, open until 10pm
- **Safeway** (0.8 mi) - 24 hours, competitive prices

## Money Saving Tips
- Store brands typically 20-30% cheaper than name brands
- Tuesday evenings often have best discounts
- Buy larger quantities if you use milk regularly

## Delivery Options
- **Instacart** - 2 hour delivery, $3.99 fee
- **Amazon Fresh** - Same day if ordered by 2pm

## Milk Types to Consider
- Whole milk for cooking/baking
- 2% for general use
- Oat milk as dairy alternative
```

### PIECE: "555-123-4567 John from the meeting"
**Auto-Executed Actions:**
1. Add to Contacts: Name "John", Phone "555-123-4567"

**No Research Generated** (raw contact data)

### TODO: "Learn SwiftUI"
**Auto-Executed Actions:**
1. Add to Apple Reminders as ongoing task
2. Web search for SwiftUI learning resources

**Generated Research:**
```markdown
# Learning SwiftUI

## Getting Started
SwiftUI is Apple's modern UI framework. Best approach is hands-on practice with real projects.

## Free Resources
- **Stanford CS193p** - Excellent free course covering fundamentals
- **Apple Documentation** - Comprehensive reference with examples
- **WWDC Sessions** - Latest features and best practices

## Paid Options
- **Hacking with Swift** - Practical tutorials with projects
- **SwiftUI by Tutorials** - Ray Wenderlich comprehensive guide

## Practice Ideas
- Build a simple to-do app
- Create a weather app using APIs
- Practice with different UI components

## Community
- SwiftUI subreddit for questions
- Apple Developer Forums
- iOS Dev Slack channels
```

## User Interface Design

### Entry Detail View with Actions & Research
```
┌────────────────────────────────────────┐
│ 🟢 TODO: "Buy milk tomorrow"          │
│ Created 1 hour ago                     │
│                                        │
│ ✅ AI ACTIONS COMPLETED                │
│ ┌────────────────────────────────────┐ │
│ │ ✓ Added to Reminders               │ │
│ │ ✓ Researched grocery options       │ │
│ │                                    │ │
│ │ [ ↻ Undo Actions ] [ 📝 Research ] │ │
│ └────────────────────────────────────┘ │
│                                        │
│ 📄 Research Summary                    │
│ ┌────────────────────────────────────┐ │
│ │ # Grocery Shopping: Milk           │ │
│ │                                    │ │
│ │ ## Nearby Options                  │ │
│ │ - **Whole Foods** (0.3 mi)        │ │
│ │ - **Safeway** (0.8 mi)            │ │
│ │                                    │ │
│ │ ## Money Saving Tips               │ │
│ │ - Store brands 20-30% cheaper     │ │
│ │                                    │ │
│ │ [Expand to show full research...]  │ │
│ └────────────────────────────────────┘ │
└────────────────────────────────────────┘
```

### Contact Auto-Creation for Pieces
```
┌────────────────────────────────────────┐
│ 📱 "555-123-4567 John from meeting"   │
│ Created just now                       │
│                                        │
│ ✅ CONTACT CREATED                     │
│ ┌────────────────────────────────────┐ │
│ │ 👤 John                            │ │
│ │ 📞 555-123-4567                    │ │
│ │                                    │ │
│ │ [ ↻ Undo ] [ ✏️ Edit ] [ 📞 Call ] │ │
│ └────────────────────────────────────┘ │
│                                        │
│ 🤖 No research needed                 │
│ (Contact data processed)               │
└────────────────────────────────────────┘
```

### Settings Integration
```
┌─ AI Features ─────────────────────────┐
│ ☑️ Enable AI-powered features         │
│                                       │
│ Claude API Key: [●●●●●●●●●●●●]        │
│ [ Test Connection ]                   │
│                                       │
│ Tool Permissions:                     │
│ ☑️ Auto-add to Apple Reminders        │
│ ☑️ Auto-add to Calendar              │
│ ☑️ Auto-add to Contacts              │
│ ☑️ Auto-save locations to Maps       │
│ ☑️ Generate research summaries       │
│                                       │
│ 📊 Usage Stats                        │
│ Actions executed: 47 this month       │
│ Research generated: 23 summaries      │
│ API Cost: $0.08 this month           │
│                                       │
│ Privacy: Research uses Claude API.    │
│ All actions use local system tools.   │
└───────────────────────────────────────┘
```

## Implementation Roadmap

### Phase 1: Core Agent (Weeks 1-2)
- [ ] **Pattern Matching & Tool Integration**
  - Implement phone number, time, location detection
  - Integrate with Apple Reminders, Calendar, Contacts
  - Basic AI research generation with Claude

- [ ] **Database & UI**
  - Add AIMetadata structure to Entry model
  - Create action display UI components
  - Add settings for tool permissions

### Phase 2: Research Enhancement (Weeks 3-4)
- [ ] **Improved Research Generation**
  - Context-aware prompts for different content types
  - Markdown formatting and display
  - Research caching to avoid duplicate API calls

- [ ] **Action Management**
  - Undo/reverse functionality for all actions
  - Edit capabilities for created contacts/reminders
  - Action history and analytics

### Phase 3: Polish & Optimization (Weeks 5-6)
- [ ] **Performance & Reliability**
  - Background processing queue
  - Error handling and retry logic
  - Cost monitoring and optimization

- [ ] **User Experience**
  - Better markdown rendering
  - Action status notifications
  - Usage analytics and insights

## Success Metrics

### Tool Execution Metrics
- **Action Success Rate:** > 95% of attempted actions complete successfully
- **User Reversal Rate:** < 10% of actions reversed by users
- **Feature Adoption:** > 70% of users enable auto-actions

### Research Quality Metrics
- **Research Relevance:** > 80% user satisfaction with generated summaries
- **Research Usage:** > 40% of research summaries expanded/read by users

### Performance Metrics
- **Action Speed:** < 2 seconds for tool execution
- **Research Speed:** < 5 seconds for summary generation
- **API Cost:** < $0.03 per user per month

## Privacy & Security

### Data Protection
- **Local Actions:** All tool executions use local system APIs
- **Research Privacy:** Only content (not personal data) sent to Claude API
- **User Control:** Easy opt-out for any tool or research feature

### API Security
- **Key Management:** Claude API key stored in Keychain
- **Rate Limiting:** Prevent API abuse and cost overruns
- **Error Handling:** Graceful degradation when API unavailable

---

This simplified guide focuses on **autonomous action execution** and **intelligent research** rather than complex classification systems. The trigger-based approach eliminates AI classification costs while providing immediate, reliable value through tool integration and helpful research summaries.