# Unified AI Implementation Guide for Notate

## Product Vision

Transform Notate into an intelligent assistant that understands user intent and provides contextually relevant, actionable suggestions. The system differentiates between content types (phone numbers need contact creation, romantic thoughts need restaurant suggestions) and provides 5-15 varied, useful recommendations with smart automated actions.

## Core Principles

### 1. Content-Aware Intelligence
The AI analyzes content to understand **what type of information** it is, not just **what it says**.

### 2. Progressive Enhancement
Start simple (calendar + search), evolve to sophisticated (smart actions + contextual suggestions).

### 3. Smart Actions with User Control
- **Act automatically** with user consent for clear patterns (phone numbers → contacts)
- **Provide reversible actions** to maintain user control
- **Offer editing capabilities** for refinement

## Technical Architecture

### Unified Data Model

#### Enhanced Entry Metadata (Single Source of Truth)
```json
{
  "ai_analysis": {
    "content_type": "actionable_task",
    "confidence": 0.95,
    "processed_at": "2024-01-15T10:00:00Z",
    "processing_version": "v1.0",
    "extracted_entities": {
      "task": "buy milk",
      "urgency": "normal",
      "location_relevant": true
    }
  },

  "calendar_integration": {
    "event_id": "ABC123",
    "due_date": "2024-01-15T14:30:00Z",
    "synced": true,
    "last_sync": "2024-01-15T10:00:00Z",
    "detected_datetime": {
      "has_datetime": true,
      "raw_date": "2024-01-15",
      "raw_time": "14:30",
      "is_relative": false,
      "confidence": 0.95,
      "description": "tomorrow at 2:30pm"
    }
  },

  "smart_actions": [
    {
      "id": "action_001",
      "type": "add_to_contacts",
      "status": "executed",
      "data": {
        "phone": "555-123-4567",
        "name": "Unknown Contact",
        "contact_id": "ABC123"
      },
      "executed_at": "2024-01-15T10:05:00Z",
      "reversible": true,
      "reverse_data": {
        "contact_existed": false,
        "original_name": null
      }
    }
  ],

  "ai_suggestions": [
    {
      "id": "sug_001",
      "type": "location",
      "category": "grocery_store",
      "title": "Whole Foods Market",
      "description": "Organic groceries, 0.3 miles away",
      "action": {
        "type": "open_maps",
        "data": {"query": "Whole Foods near me"}
      },
      "confidence": 0.9,
      "clicked": false,
      "generated_at": "2024-01-15T10:00:00Z"
    }
  ],

  "analytics": {
    "total_suggestions_generated": 12,
    "total_suggestions_clicked": 3,
    "user_location": "New York, NY",
    "generation_cost": 0.002,
    "processing_time_ms": 1250,
    "processing_history": [
      {
        "action": "content_classification",
        "timestamp": "2024-01-15T10:00:00Z",
        "result": "success",
        "model": "claude-3-haiku",
        "cost": 0.001
      }
    ]
  }
}
```

### Swift Data Models

```swift
// MARK: - Main AI Metadata Structure
struct AIMetadata: Codable {
    var analysis: ContentAnalysis?
    var calendarIntegration: CalendarIntegration?
    var smartActions: [SmartAction] = []
    var suggestions: [AISuggestion] = []
    var analytics: AnalyticsData?
}

// MARK: - Content Analysis
struct ContentAnalysis: Codable {
    let contentType: ContentType
    let confidence: Double
    let processedAt: Date
    let processingVersion: String
    let extractedEntities: [String: FlexibleCodable]
}

enum ContentType: String, CaseIterable, Codable {
    case phoneNumber = "phone_number"
    case email = "email"
    case actionableTask = "actionable_task"
    case romanticSocial = "romantic_social"
    case learningResearch = "learning_research"
    case locationTravel = "location_travel"
    case generalThought = "general_thought"
    case personName = "person_name"
    case dateTime = "date_time"
}

// MARK: - Calendar Integration
struct CalendarIntegration: Codable {
    var eventId: String?
    var dueDate: Date?
    var synced: Bool = false
    var lastSync: Date?
    var detectedDateTime: DetectedDateTime?
}

struct DetectedDateTime: Codable {
    let hasDateTime: Bool
    let rawDate: String?
    let rawTime: String?
    let isRelative: Bool
    let confidence: Double
    let description: String?
}

// MARK: - Smart Actions
struct SmartAction: Codable {
    let id: String
    let type: SmartActionType
    var status: ActionStatus
    let data: [String: FlexibleCodable]
    let reversible: Bool
    let reverseData: [String: FlexibleCodable]?
    let executedAt: Date?
}

enum SmartActionType: String, CaseIterable, Codable {
    case addToContacts = "add_to_contacts"
    case addToCalendar = "add_to_calendar"
    case openMap = "open_map"
    case createReminder = "create_reminder"
}

enum ActionStatus: String, Codable {
    case pending, executing, executed, failed, reversed
}

// MARK: - AI Suggestions
struct AISuggestion: Codable {
    let id: String
    let type: SuggestionType
    let category: String
    let title: String
    let description: String
    let action: SuggestionAction
    let confidence: Double
    var clicked: Bool = false
    let generatedAt: Date
    var clickedAt: Date?
}

enum SuggestionType: String, CaseIterable, Codable {
    case location, app, webSearch, product, learning, entertainment, tool
}

struct SuggestionAction: Codable {
    let type: ActionType
    let data: [String: FlexibleCodable]

    enum ActionType: String, CaseIterable, Codable {
        case openApp, openURL, openMaps, webSearch, showInApp
    }
}
```

### Service Architecture

```swift
// MARK: - Main Intelligent Service
@MainActor
class IntelligentSuggestionService: ObservableObject {
    private let aiService: AIService
    private let calendarService: CalendarService
    private let contactService: ContactService
    private let locationService: LocationService
    private let cacheService: AICacheService

    func processEntry(_ entry: Entry) async -> ProcessingResult {
        // 1. Check cache first
        if let cached = await checkCache(for: entry.content) {
            return cached
        }

        // 2. Classify content
        let analysis = await classifyContent(entry.content)

        // 3. Execute smart actions if needed
        let actions = await executeSmartActions(for: analysis, entry: entry)

        // 4. Generate contextual suggestions
        let suggestions = await generateSuggestions(for: analysis)

        // 5. Cache results
        let result = ProcessingResult(analysis: analysis, actions: actions, suggestions: suggestions)
        await cacheResult(result, for: entry.content)

        return result
    }

    private func classifyContent(_ content: String) async -> ContentAnalysis {
        // AI classification logic
    }

    private func executeSmartActions(for analysis: ContentAnalysis, entry: Entry) async -> [SmartAction] {
        var actions: [SmartAction] = []

        switch analysis.contentType {
        case .phoneNumber:
            if let phoneAction = await createContactAction(from: content) {
                actions.append(phoneAction)
            }
        case .dateTime:
            if let calendarAction = await createCalendarAction(from: analysis) {
                actions.append(calendarAction)
            }
        default:
            break
        }

        return actions
    }

    private func generateSuggestions(for analysis: ContentAnalysis) async -> [AISuggestion] {
        // Context-aware suggestion generation
    }
}

// MARK: - Basic AI Service
class AIService {
    private let apiKey: String
    private let baseURL = "https://api.anthropic.com/v1/messages"

    func classifyContent(_ text: String) async throws -> ContentAnalysis {
        let prompt = buildClassificationPrompt(text)
        let response = try await makeAPICall(prompt: prompt, model: "claude-3-haiku-20240307")
        return try parseClassificationResponse(response)
    }

    func generateSuggestions(for analysis: ContentAnalysis, userLocation: String?) async throws -> [AISuggestion] {
        let prompt = buildSuggestionPrompt(analysis: analysis, location: userLocation)
        let response = try await makeAPICall(prompt: prompt, model: "claude-3-haiku-20240307")
        return try parseSuggestionsResponse(response)
    }

    private func makeAPICall(prompt: String, model: String) async throws -> String {
        // Claude API implementation
    }
}

// MARK: - Cache Service
class AICacheService {
    private var contentCache: [String: ProcessingResult] = [:]
    private var cacheTimestamps: [String: Date] = [:]
    private let cacheExpiry: TimeInterval = 24 * 60 * 60 // 24 hours

    func getCached(for content: String) -> ProcessingResult? {
        let key = content.sha256
        guard let result = contentCache[key],
              let timestamp = cacheTimestamps[key],
              Date().timeIntervalSince(timestamp) < cacheExpiry else {
            return nil
        }
        return result
    }

    func cache(_ result: ProcessingResult, for content: String) {
        let key = content.sha256
        contentCache[key] = result
        cacheTimestamps[key] = Date()
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
            guard let aiMetadata = getAIMetadata(for: entry) else { return true }
            return aiMetadata.analysis == nil
        }
    }

    func getEntriesWithCalendarEvents() -> [Entry] {
        return entries.filter { entry in
            guard let aiMetadata = getAIMetadata(for: entry) else { return false }
            return aiMetadata.calendarIntegration?.eventId != nil
        }
    }

    // MARK: - AI Indexes (for performance)
    private func createAIIndexes() {
        let indexes = [
            "CREATE INDEX IF NOT EXISTS idx_ai_processed ON entries(json_extract(metadata, '$.ai.analysis.processedAt'));",
            "CREATE INDEX IF NOT EXISTS idx_calendar_synced ON entries(json_extract(metadata, '$.ai.calendarIntegration.synced'));",
            "CREATE INDEX IF NOT EXISTS idx_content_type ON entries(json_extract(metadata, '$.ai.analysis.contentType'));"
        ]

        for indexSQL in indexes {
            sqlite3_exec(db, indexSQL, nil, nil, nil)
        }
    }
}
```

## Content Classification & Examples

### 1. **Phone Numbers**
- **Pattern:** `555-123-4567`, `(555) 123-4567`, `+1-555-123-4567`
- **Smart Action:** Auto-add to Contacts
- **Suggestions:** None (action-focused)
- **UI:** Reverse button + Edit contact

### 2. **Actionable Tasks: "buy milk"**
**Suggestions (8-12):**
```
🛒 Nearby Stores
- Whole Foods (0.3 mi) - Open until 10pm
- Safeway (0.8 mi) - 24 hours

📱 Delivery Apps
- Instacart - 2-hour delivery
- Amazon Fresh - Same day delivery

💰 Money Saving
- Milk price comparison 2024
- Best store brands vs name brands

📋 Shopping Help
- Grocery list templates
- Meal planning with dairy
```

### 3. **Romantic Content: "anniversary dinner"**
**Suggestions (10-15):**
```
🍽️ Fine Dining Nearby
- Le Bernardin (2.1 mi) - French, $$$
- The Modern (1.8 mi) - Contemporary

🍷 Experiences
- Wine tasting classes for couples
- Cooking classes nearby

💡 Inspiration
- Anniversary gift ideas 2024
- Romantic date night activities

🏨 Staycation
- Boutique hotels with packages
- Weekend getaway deals
```

### 4. **Learning Topics: "learn SwiftUI"**
**Suggestions (8-12):**
```
📚 Official Resources
- Apple SwiftUI Documentation
- WWDC SwiftUI sessions

🎓 Courses
- Stanford CS193p (Free)
- Udemy SwiftUI Masterclass

📖 Books
- "SwiftUI by Tutorials"
- "Thinking in SwiftUI"

🛠️ Practice
- Hacking with Swift challenges
- SwiftUI Lab projects
```

## AI Processing Prompts

### Content Classification Prompt
```
Analyze this user input and classify it:

Input: "{user_content}"
User context: {location: "NYC", time: "evening"}

Classify into ONE primary type:
- phone_number: Phone numbers in any format
- email: Email addresses
- actionable_task: Things to do, buy, accomplish
- romantic_social: Dating, relationships, social activities
- learning_research: Educational content, how-to questions
- location_travel: Places to go, travel plans
- general_thought: Random observations, ideas
- person_name: Names of people
- date_time: Specific dates, times, appointments

Return JSON:
{
  "type": "actionable_task",
  "confidence": 0.95,
  "entities": {"task": "buy milk", "urgency": "normal"},
  "needs_smart_action": true,
  "suggested_count": 10,
  "reasoning": "Clear actionable task with specific item to purchase"
}
```

### Suggestion Generation Prompt
```
Generate {suggested_count} intelligent, actionable suggestions for:

Content: "{user_content}"
Type: {content_type}
User location: {user_location}
Time: {current_time}

Requirements:
1. Provide DIVERSE suggestion types (locations, apps, web searches, products)
2. Include confidence scores (0.1-1.0)
3. Make suggestions ACTIONABLE with specific apps/URLs/searches
4. Consider user's location for local recommendations
5. Range from immediate actions to broader exploration

Return JSON array with:
- type: location|app|web_search|product|learning|entertainment
- category: specific subcategory
- title: Clear, engaging title
- description: Brief, helpful description
- action: Specific action to take
- confidence: How relevant this suggestion is

Example:
[
  {
    "type": "location",
    "category": "grocery_store",
    "title": "Whole Foods Market",
    "description": "Organic groceries, 0.3 miles away",
    "action": {"type": "open_maps", "query": "Whole Foods near me"},
    "confidence": 0.9
  }
]
```

## User Interface Design

### Entry Detail View with AI Suggestions
```
┌────────────────────────────────────────┐
│ 🟢 TODO: "buy milk"                   │
│ Created 2 hours ago                    │
│ ┌────────────────────────────────────┐ │
│ │ 🤖 AI Analysis: Actionable Task    │ │
│ │ Confidence: 95%                    │ │
│ │ [ Regenerate Suggestions ]         │ │
│ └────────────────────────────────────┘ │
│                                        │
│ 💡 Smart Suggestions (12)             │
│ ┌────────────────────────────────────┐ │
│ │ 🛒 NEARBY STORES                   │ │
│ │ • Whole Foods (0.3 mi) - Open     │ │
│ │ • Safeway (0.8 mi) - 24hrs        │ │
│ │                                    │ │
│ │ 📱 DELIVERY APPS                   │ │
│ │ • Instacart - 2hr delivery        │ │
│ │ • Amazon Fresh - Same day          │ │
│ │                                    │ │
│ │ [Show 8 more suggestions...]       │ │
│ └────────────────────────────────────┘ │
└────────────────────────────────────────┘
```

### Smart Action UI for Phone Numbers
```
┌────────────────────────────────────────┐
│ 📞 "555-123-4567"                     │
│ Created just now                       │
│                                        │
│ ✅ SMART ACTION COMPLETED              │
│ ┌────────────────────────────────────┐ │
│ │ 👤 Added to Contacts               │ │
│ │ Name: "Unknown Contact"            │ │
│ │                                    │ │
│ │ [ ↻ Reverse Action ]               │ │
│ │ [ ✏️ Edit Contact ]                │ │
│ │ [ 📞 Call Now ]                    │ │
│ └────────────────────────────────────┘ │
│                                        │
│ 🤖 No additional suggestions          │
│ (Primary intent fulfilled)             │
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
│ ☑️ Smart actions (auto-add contacts)  │
│ ☑️ Calendar sync for TODOs            │
│ ☑️ Intelligent suggestions           │
│                                       │
│ 📊 Usage Stats                        │
│ Processed: 156 entries this month     │
│ API Cost: $0.23 this month           │
│                                       │
│ Privacy: All processing uses          │
│ Anthropic's Claude API. No data       │
│ is stored on external servers.        │
└───────────────────────────────────────┘
```

## Implementation Roadmap

### Phase 1: Foundation (Weeks 1-2)
- [ ] **Core AI Service & Database**
  - Implement basic AIService with Claude API
  - Add unified AIMetadata structure to Entry model
  - Create database indexes for AI operations
  - Add AI settings to SettingsView

- [ ] **Basic Content Classification**
  - Phone number detection → Contact creation
  - Date/time detection → Calendar integration
  - Simple search suggestions (3-5 per entry)

### Phase 2: Intelligent System (Weeks 3-4)
- [ ] **Advanced Classification**
  - 9 content types with confidence scoring
  - Entity extraction for complex analysis
  - Smart action execution with reversibility

- [ ] **Contextual Suggestions**
  - Location-aware suggestions
  - 5-15 varied suggestions per content type
  - Multiple suggestion categories (apps, locations, products)

### Phase 3: Optimization & Polish (Weeks 5-6)
- [ ] **Performance & Caching**
  - Content hash-based caching
  - Background processing queue
  - Cost optimization and monitoring

- [ ] **Personalization & Analytics**
  - User interaction tracking
  - Suggestion effectiveness analysis
  - Adaptive suggestion generation

## Success Metrics

### Engagement Metrics
- **Suggestion Click Rate:** > 25% of generated suggestions clicked
- **Smart Action Acceptance:** > 80% of smart actions kept (not reversed)
- **Feature Adoption:** > 60% of users enable AI features

### Quality Metrics
- **Classification Accuracy:** > 90% correct content type detection
- **Suggestion Relevance:** > 75% user satisfaction rating
- **Local Suggestion Accuracy:** > 85% for location-based suggestions

### Performance Metrics
- **Response Time:** < 3 seconds for suggestion generation
- **API Cost:** < $0.05 per user per month
- **Cache Hit Rate:** > 60% for repeated similar content

## Privacy & Security

### Data Protection
- **Local Processing:** Content analysis metadata stored locally
- **Encrypted Storage:** AI metadata encrypted with existing system
- **User Control:** Clear opt-in/opt-out for all AI features
- **Data Retention:** AI suggestions expire after 30 days

### API Security
- **Key Management:** Claude API key stored in Keychain
- **Rate Limiting:** Prevent abuse and cost overruns
- **Error Handling:** Graceful degradation when AI unavailable
- **Audit Trail:** Log AI interactions for debugging and cost tracking

---

This unified guide provides a complete, cohesive implementation strategy that combines the best ideas from all three documents while removing outdated or conflicting designs. The progressive enhancement approach ensures rapid user value while building towards a sophisticated AI assistant.