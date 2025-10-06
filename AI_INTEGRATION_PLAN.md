# AI Agent Integration Plan for Notate

## Product Vision
Transform Notate from a simple capture tool into an intelligent agent that:
1. **Detects** dates/times in TODOs and automatically syncs with Calendar
2. **Suggests** relevant web searches for any entry
3. **Keeps it simple** - minimal UI changes, maximum value

## Core Features

### 1. Smart Calendar Integration
**What:** Automatically detect dates/times in TODOs and sync with system Calendar
**How:**
- Use cheap AI model (Claude Haiku) to extract date/time from TODO content
- Leverage EventKit for native Calendar integration
- Simple toggle in settings to enable/disable

**Examples:**
- "Meeting with John tomorrow at 3pm" → Creates calendar event
- "Dentist appointment Friday" → Creates Friday event
- "Buy groceries" → No calendar event (no date detected)

### 2. AI-Powered Web Search
**What:** Suggest relevant searches for entries to help users take action
**How:**
- Use Claude API to analyze entry content and suggest search queries
- Show search suggestions as expandable section in entry detail
- One-click to open searches in default browser

**Examples:**
- "Learn SwiftUI" → Suggests: "SwiftUI tutorial 2024", "SwiftUI documentation"
- "Fix car AC" → Suggests: "car AC repair near me", "car AC troubleshooting"
- "Plan vacation to Japan" → Suggests: "Japan travel guide", "Japan visa requirements"

## UI/UX Design

### Minimal UI Changes
1. **Settings Page:** Add "AI Features" section with:
   - Claude API key input
   - Calendar sync toggle
   - Web search suggestions toggle

2. **Entry Views:** Add subtle enhancements:
   - 📅 Calendar icon for TODOs with detected dates
   - 🔍 Expandable "Suggestions" section with search queries
   - Status indicators (synced, processing, etc.)

3. **New Entry Flow:**
   - Background processing - no blocking
   - Toast notifications for calendar events created
   - Graceful fallbacks if AI fails

### User Experience Flow

#### Calendar Integration Flow:
```
1. User creates TODO: "Lunch with Alice tomorrow 1pm"
2. Background: AI detects "tomorrow 1pm"
3. Background: Creates calendar event
4. UI: Shows 📅 icon next to TODO
5. User marks TODO done → Calendar event removed
```

#### Web Search Flow:
```
1. User taps TODO/Thought
2. Expanded view shows "🔍 Suggestions" section
3. Background: AI generates relevant search queries
4. UI: Shows clickable search suggestions
5. User clicks → Opens in browser
```

## Technical Architecture

### File Structure
```
Notate/
├── Services/
│   ├── AIService.swift              # Claude API client
│   ├── CalendarService.swift        # EventKit integration
│   └── WebSearchService.swift       # Search suggestion logic
├── Models/
│   ├── Entry.swift                  # Extend with AI metadata
│   ├── AIMetadata.swift             # AI-related data models
│   └── CalendarEvent.swift          # Calendar event data
├── Views/
│   ├── AISettingsView.swift         # AI configuration UI
│   ├── SuggestionsView.swift        # Search suggestions UI
│   └── [existing views]             # Minimal modifications
└── Extensions/
    └── Entry+AI.swift               # AI-related Entry methods
```

### Data Models

#### Extended Entry Model
```swift
// Add to existing Entry model
var aiMetadata: AIMetadata?

struct AIMetadata: Codable {
    var hasCalendarEvent: Bool
    var calendarEventId: String?
    var suggestedSearches: [String]?
    var lastProcessed: Date?
    var processingStatus: ProcessingStatus
}

enum ProcessingStatus: String, Codable {
    case pending, processing, completed, failed
}
```

#### New Models
```swift
struct CalendarEvent {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
}

struct SearchSuggestion {
    let query: String
    let description: String
    let confidence: Double
}
```

### Services Architecture

#### AIService
```swift
class AIService {
    func detectDateTime(in text: String) async -> DateTimeInfo?
    func generateSearchSuggestions(for text: String) async -> [SearchSuggestion]
    private func makeClaudeAPICall() async -> String
}
```

#### CalendarService
```swift
class CalendarService {
    func requestPermission() async -> Bool
    func createEvent(from dateTime: DateTimeInfo, title: String) async -> String?
    func updateEvent(id: String, title: String) async
    func deleteEvent(id: String) async
}
```

## Implementation Phases

### Phase 1: Foundation (Week 1)
- [ ] Create AIService with Claude API client
- [ ] Add AI settings to SettingsView
- [ ] Extend Entry model with aiMetadata
- [ ] Basic date/time detection (no calendar yet)

### Phase 2: Calendar Integration (Week 2)
- [ ] Implement CalendarService with EventKit
- [ ] Add calendar permission handling
- [ ] Auto-sync TODOs with detected dates
- [ ] Add calendar status indicators to UI

### Phase 3: Web Search (Week 3)
- [ ] Implement search suggestion generation
- [ ] Add SuggestionsView component
- [ ] Integrate suggestions into entry detail views
- [ ] Add one-click search opening

### Phase 4: Polish & Optimization (Week 4)
- [ ] Error handling and offline mode
- [ ] Performance optimization
- [ ] User feedback and analytics
- [ ] Documentation and help

## Configuration & Privacy

### Settings UI
```
┌─ AI Features ─────────────────────┐
│ □ Enable AI-powered features      │
│                                   │
│ Claude API Key: [____________]    │
│ [Test Connection]                 │
│                                   │
│ □ Calendar sync for TODOs         │
│ □ Web search suggestions          │
│                                   │
│ Privacy: All processing uses      │
│ Anthropic's Claude API. No data   │
│ is stored on external servers.    │
└───────────────────────────────────┘
```

### Privacy Considerations
- API key stored in Keychain
- No data persistence on external servers
- Clear opt-in for each AI feature
- Graceful degradation if AI unavailable

## Success Metrics
1. **Adoption:** % of users who enable AI features
2. **Utility:** % of TODOs that get calendar events created
3. **Engagement:** Search suggestions clicked per entry
4. **Performance:** API response times < 2 seconds
5. **Reliability:** < 5% AI processing failures

## Technical Risks & Mitigation
1. **API Costs:** Use cheapest models, cache results
2. **API Reliability:** Graceful fallbacks, retry logic
3. **Privacy Concerns:** Clear disclosure, local-first approach
4. **Performance:** Background processing, non-blocking UI
5. **Calendar Permissions:** Clear value prop, easy setup

## Next Steps
1. Review this plan and get alignment
2. Set up Claude API account and test integration
3. Start with Phase 1 foundation work
4. Iterate based on user feedback

---
*This plan balances simplicity with powerful AI capabilities, staying true to Notate's local-first philosophy while adding genuine user value.*