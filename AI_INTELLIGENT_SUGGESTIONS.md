# Intelligent AI Suggestion System for Notate

## Product Vision

Transform Notate into an intelligent assistant that understands user intent and provides contextually relevant, actionable suggestions. The system should be smart enough to differentiate between a phone number (which needs contact creation) and a romantic thought (which needs restaurant suggestions), providing 5-15 varied, useful recommendations.

## Core Principles

### 1. Content-Aware Intelligence
The AI analyzes content to understand **what type of information** it is, not just **what it says**.

### 2. Contextual Relevance
Suggestions should be:
- **Locally relevant** (nearby restaurants, stores)
- **Actionable** (specific apps, websites, actions)
- **Diverse** (different types of help for the same need)
- **Personalized** (based on user patterns and preferences)

### 3. Smart Actions
For specific content types, the system should:
- **Act automatically** with user consent
- **Provide reversible actions** to maintain user control
- **Offer editing capabilities** for refinement

## Content Classification System

### Content Types

#### 1. **Phone Numbers**
- **Pattern:** `555-123-4567`, `(555) 123-4567`, `+1-555-123-4567`
- **Smart Action:** Auto-add to Contacts
- **Suggestions:** None (action-focused)
- **UI:** Reverse button + Edit contact

#### 2. **Actionable Tasks**
- **Examples:** "buy milk", "get groceries", "book dentist appointment"
- **Smart Action:** Optional calendar event creation
- **Suggestions:** 8-12 varied suggestions (stores, apps, guides)

#### 3. **Romantic/Social Content**
- **Examples:** "date night ideas", "anniversary planning", "romantic dinner"
- **Smart Action:** None
- **Suggestions:** 10-15 diverse suggestions (venues, books, activities)

#### 4. **Learning/Research Topics**
- **Examples:** "learn SwiftUI", "understand quantum physics", "cooking techniques"
- **Smart Action:** None
- **Suggestions:** 8-12 educational resources (tutorials, books, courses)

#### 5. **Location/Travel**
- **Examples:** "visit Tokyo", "weekend getaway", "coffee shops nearby"
- **Smart Action:** Optional map search
- **Suggestions:** 10-15 location-based suggestions

#### 6. **General Thoughts**
- **Examples:** Random observations, ideas, notes
- **Smart Action:** None
- **Suggestions:** 5-8 loosely related suggestions

### Classification Confidence Levels
- **High (0.8-1.0):** Clear pattern match, confident suggestions
- **Medium (0.5-0.8):** Probable match, offer suggestions with lower confidence
- **Low (0.0-0.5):** Unclear content, minimal or no suggestions

## Suggestion Types & Examples

### 1. **Actionable Task: "buy milk"**
```
🛒 Grocery Stores
- Whole Foods (0.3 mi) - Open until 10pm
- Safeway (0.8 mi) - 24 hours

📱 Delivery Apps
- Instacart - 2-hour delivery
- Amazon Fresh - Same day delivery

💰 Money Saving
- Milk price comparison 2024
- Best store brands vs name brands

📋 Shopping Optimization
- Complete grocery list templates
- Meal planning with dairy products

🥛 Product Research
- Organic vs regular milk health benefits
- Best milk alternatives 2024
```

### 2. **Romantic Content: "anniversary dinner ideas"**
```
🍽️ Fine Dining Nearby
- Le Bernardin (2.1 mi) - French, $$$
- The Modern (1.8 mi) - Contemporary, $$$

🍷 Wine & Ambiance
- Best wine bars for couples NYC
- Romantic rooftop restaurants

💡 Unique Experiences
- Cooking classes for couples
- Private dining experiences

📚 Inspiration
- "The 5 Love Languages" book
- Anniversary gift ideas 2024

🎭 Entertainment
- Live jazz venues nearby
- Couples massage packages

🏨 Staycation Options
- Boutique hotels with packages
- Weekend getaway deals within 2 hours
```

### 3. **Phone Number: "555-123-4567"**
```
✅ SMART ACTION PERFORMED
Added to Contacts as "Unknown Contact"

[ ↻ Reverse ] [ ✏️ Edit Contact ]

🤖 No additional suggestions needed
(Automatic action was the primary intent)
```

### 4. **Learning Topic: "learn SwiftUI"**
```
📚 Official Resources
- Apple SwiftUI Documentation
- WWDC SwiftUI sessions

🎓 Online Courses
- Stanford CS193p SwiftUI course (Free)
- Udemy SwiftUI Masterclass

📖 Books & Guides
- "SwiftUI by Tutorials" - Ray Wenderlich
- "Thinking in SwiftUI" - Chris Eidhof

🛠️ Practice Platforms
- Hacking with Swift - 100 Days SwiftUI
- SwiftUI Lab challenges

👥 Community
- SwiftUI subreddit discussions
- iOS Developer Slack channels

💻 Development Tools
- Xcode tips for SwiftUI
- SwiftUI preview optimization
```

## Technical Implementation

### Database Schema Enhancement

#### Enhanced Entry Metadata
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

  "smart_actions": [
    {
      "id": "action_001",
      "type": "add_to_contacts",
      "status": "executed", // pending|executed|failed|reversed
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
    },
    {
      "id": "sug_002",
      "type": "app",
      "category": "delivery",
      "title": "Instacart",
      "description": "Get milk delivered in 2 hours",
      "action": {
        "type": "open_app",
        "data": {"app_id": "com.maplebear.iconsumer"}
      },
      "confidence": 0.85,
      "clicked": true,
      "clicked_at": "2024-01-15T10:15:00Z"
    }
  ],

  "suggestion_metadata": {
    "total_generated": 12,
    "total_clicked": 3,
    "user_location": "New York, NY",
    "generation_cost": 0.002,
    "processing_time_ms": 1250
  }
}
```

### Core Service Architecture

```swift
// MARK: - Main Intelligent Suggestion Service
class IntelligentSuggestionService: ObservableObject {
    private let aiService: AIService
    private let locationService: LocationService
    private let contactService: ContactService
    private let calendarService: CalendarService

    func processEntry(_ entry: Entry) async -> ProcessingResult {
        // 1. Classify content
        let analysis = await classifyContent(entry.content)

        // 2. Execute smart actions if needed
        let actions = await executeSmartActions(for: analysis)

        // 3. Generate contextual suggestions
        let suggestions = await generateSuggestions(for: analysis)

        return ProcessingResult(analysis: analysis, actions: actions, suggestions: suggestions)
    }
}

// MARK: - Content Classification
struct ContentAnalysis {
    let type: ContentType
    let confidence: Double
    let extractedEntities: [String: Any]
    let needsSmartAction: Bool
    let suggestedActionCount: Int // 5-15 range
}

enum ContentType: String, CaseIterable {
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

// MARK: - Smart Actions System
struct SmartAction {
    let id: String
    let type: SmartActionType
    let status: ActionStatus
    let data: [String: Any]
    let reversible: Bool
    let reverseData: [String: Any]?
}

enum SmartActionType: String {
    case addToContacts = "add_to_contacts"
    case addToCalendar = "add_to_calendar"
    case openMap = "open_map"
    case createReminder = "create_reminder"
}

enum ActionStatus: String {
    case pending, executing, executed, failed, reversed
}

// MARK: - AI Suggestions System
struct AISuggestion {
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

enum SuggestionType: String {
    case location, app, webSearch, product, learning, entertainment, tool
}

struct SuggestionAction {
    let type: ActionType
    let data: [String: Any]

    enum ActionType: String {
        case openApp, openURL, openMaps, webSearch, showInApp
    }
}
```

### AI Processing Pipeline

#### 1. Content Classification Prompt
```
Analyze this user input and classify it:

Input: "{user_content}"
User context: {location: "NYC", time: "evening", recent_entries: [...]}

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

#### 2. Suggestion Generation Prompt
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

For romantic_social content: Focus on local venues, experiences, inspiration
For actionable_task content: Focus on efficiency, local options, cost savings
For learning_research content: Focus on resources, courses, communities

Return JSON array of suggestions with:
- type: location|app|web_search|product|learning|entertainment
- category: specific subcategory
- title: Clear, engaging title
- description: Brief, helpful description
- action: Specific action to take
- confidence: How relevant this suggestion is

Example output format:
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

## User Experience Design

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
│ │ 💰 MONEY SAVING                    │ │
│ │ • Milk price comparison 2024       │ │
│ │ • Best store brands guide          │ │
│ │                                    │ │
│ │ 📋 SHOPPING HELP                   │ │
│ │ • Grocery list templates           │ │
│ │ • Meal planning with dairy         │ │
│ │                                    │ │
│ │ [Show 4 more suggestions...]       │ │
│ └────────────────────────────────────┘ │
│                                        │
│ 📊 Suggestion Stats                   │
│ 3 clicked • Generated 5 mins ago      │
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

## Implementation Roadmap

### Phase 1: Foundation (Week 1-2)
- [ ] **Content Classification Service**
  - Basic AI prompts for content type detection
  - Confidence scoring system
  - Entity extraction for key data

- [ ] **Database Schema Updates**
  - Extend Entry metadata for AI analysis
  - Add smart actions tracking
  - Add suggestion storage and interaction tracking

- [ ] **Basic Smart Actions**
  - Phone number → Add to Contacts
  - Simple reversible action system

### Phase 2: Core Suggestions (Week 3-4)
- [ ] **Suggestion Generation Engine**
  - AI prompts for contextual suggestions
  - Local business integration (Maps API)
  - App store link generation

- [ ] **UI Components**
  - Expandable suggestions view
  - Action buttons for each suggestion type
  - Click tracking and analytics

- [ ] **Caching & Performance**
  - Content hash-based caching
  - Background processing queue
  - Rate limiting for API calls

### Phase 3: Intelligence & Polish (Week 5-6)
- [ ] **Advanced Smart Actions**
  - Date/time → Calendar events
  - Addresses → Map searches
  - Email addresses → Mail composition

- [ ] **Personalization**
  - Learning from user click patterns
  - Location-based preference learning
  - Time-of-day context awareness

- [ ] **Analytics & Optimization**
  - Suggestion effectiveness tracking
  - Cost monitoring and optimization
  - User satisfaction metrics

## Success Metrics

### Engagement Metrics
- **Suggestion Click Rate:** > 25% of generated suggestions clicked
- **Smart Action Acceptance:** > 80% of smart actions kept (not reversed)
- **User Retention:** Users with AI features enabled have 40% higher retention

### Quality Metrics
- **Classification Accuracy:** > 90% correct content type detection
- **Suggestion Relevance:** > 75% user satisfaction rating
- **Local Suggestion Accuracy:** > 85% for location-based suggestions

### Performance Metrics
- **Response Time:** < 3 seconds for suggestion generation
- **API Cost:** < $0.05 per user per month
- **Cache Hit Rate:** > 60% for repeated similar content

## Privacy & Security Considerations

### Data Protection
- **Local Processing:** Content analysis happens locally when possible
- **Encrypted Storage:** AI metadata encrypted with existing system
- **User Control:** Clear opt-in/opt-out for AI features
- **Data Retention:** AI suggestions expire after 30 days unless explicitly saved

### API Security
- **Key Management:** Claude API key stored in Keychain
- **Rate Limiting:** Prevent abuse and cost overruns
- **Error Handling:** Graceful degradation when AI services unavailable
- **Audit Trail:** Log all AI interactions for debugging and cost tracking

---

This intelligent suggestion system transforms Notate from a simple capture tool into a true AI assistant that understands user intent and provides genuinely helpful, contextual recommendations.