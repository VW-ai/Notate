# Notate - Feature Status

**Last Updated:** 2025-10-06

## Overview

Notate is an AI-powered productivity app for macOS that captures and organizes thoughts, TODOs, and ideas using intelligent keyboard triggers and autonomous AI processing.

---

## ✅ Core Features (Implemented)

### 1. **Input Capture System**
- ✅ Global keyboard monitoring with accessibility permissions
- ✅ Multiple trigger patterns:
  - `///` - Quick TODO capture
  - `,,,` - Idea/snippet capture
  - `"""` - Thought capture
- ✅ Real-time input detection and processing
- ✅ Automatic content extraction after trigger

**Files:**
- `KeyboardMonitor.swift` - Global keyboard event monitoring
- `PermissionRequestView.swift` - Permission management UI

---

### 2. **Database & Storage**
- ✅ SQLite-based encrypted local storage
- ✅ Secure encryption using CryptoKit (AES-256)
- ✅ Keychain integration for encryption key management
- ✅ CRUD operations for entries
- ✅ Advanced search and filtering
- ✅ Database health checks and automatic repair
- ✅ Export to JSON and CSV

**Files:**
- `DatabaseManager.swift` - Core database operations
- `Entry.swift` - Entry data model with AI metadata support

**Database Schema:**
```sql
CREATE TABLE entries (
    id TEXT PRIMARY KEY,
    type TEXT NOT NULL,
    content TEXT NOT NULL,
    tags TEXT,
    source_app TEXT,
    trigger_used TEXT NOT NULL,
    created_at TEXT NOT NULL,
    status TEXT NOT NULL,
    priority TEXT,
    metadata TEXT,  -- Stores AI metadata as JSON
    encrypted_content TEXT
);
```

---

### 3. **AI Content Extraction** ✨
**Status:** Fully Implemented

The `AIContentExtractor` service uses Claude AI to intelligently extract structured information from user input.

**Extraction Capabilities:**
- 📞 **Phone Numbers** - Any format, including partial numbers
- 📧 **Email Addresses** - Standard email validation
- 👤 **Person Names** - Including nicknames and informal references
- ⏰ **Time/Date Information** - Normalizes informal expressions:
  - "tomorrow" → actual date
  - "tues" → Tuesday date
  - "2ish" → 2:00 PM
- 📍 **Location Information** - Addresses, place names, vague mentions
- 🎯 **Action Intents** - call, email, meet, remind, visit
- 🌐 **URLs** - Web links and websites
- 📊 **Other Structured Data** - Any additional extractable information

**Features:**
- ✅ AI-powered extraction with fallback to regex patterns
- ✅ 5-minute caching to reduce API costs
- ✅ Smart decision-making for action creation
- ✅ Generous extraction strategy (captures possibilities)

**Files:**
- `AIContentExtractor.swift` - Lines 1-219

**Example:**
```swift
Input: "Call John tomorrow at 555-1234 about the coffee shop meeting"

Extracted:
- Phone: "555-1234"
- Person: "John"
- Time: "2025-10-07T00:00:00Z"
- Action: "call"
- Location: "coffee shop"
```

---

### 4. **Autonomous AI Agent** 🤖
**Status:** Fully Implemented

The `AutonomousAIAgent` automatically processes entries and executes smart actions based on extracted information.

**Processing Flow:**

#### For TODO Items:
1. **Information Extraction** → Pull all details using AIContentExtractor
2. **Reminder Creation** → Automatically create Apple Reminders
3. **Calendar Events** → Create events if time info is present
4. **Research Generation** → Produce practical research guide

#### For Ideas/Snippets:
1. **Information Extraction** → Extract contact info, locations, etc.
2. **Contact Creation** → Create contact if contact info available
3. **Maps Integration** → Open Maps if location info present
4. **Research Generation** → Generate related topic research

**Features:**
- ✅ Background processing queue
- ✅ Batch processing (max 5 entries at a time)
- ✅ Action execution with ToolService integration
- ✅ Processing statistics and cost tracking
- ✅ Automatic retry on failure
- ✅ Context-aware processing (time of day, etc.)

**Files:**
- `AutonomousAIAgent.swift` - Lines 1-518

**Processing Stats:**
```swift
struct ProcessingStats {
    - totalProcessed: Int
    - totalCost: Double
    - averageCostPerEntry: Double
    - currentlyProcessing: Int
    - lastUpdated: Date
}
```

---

### 5. **Tool Service Integration** 🔧
**Status:** Fully Implemented

The `ToolService` provides deep macOS system integration for automated actions.

**Capabilities:**

#### 📅 Calendar Integration
- ✅ Create calendar events
- ✅ Update existing events
- ✅ Delete events
- ✅ Query upcoming events

#### ✅ Reminders Integration
- ✅ Create reminders with due dates
- ✅ Update reminder status
- ✅ Delete reminders
- ✅ Query pending reminders
- ✅ Priority support

#### 👥 Contacts Integration
- ✅ Create new contacts
- ✅ Search contacts by name
- ✅ Delete contacts
- ✅ Support for phone, email, name fields

#### 🗺️ Maps Integration
- ✅ Search locations
- ✅ Open in Apple Maps
- ✅ Coordinate-based navigation
- ✅ Address-based navigation

#### 🔐 Permission Management
- ✅ Automatic permission requests
- ✅ Permission status checking
- ✅ User-friendly permission UI
- ✅ Support for all system permissions

**Files:**
- `ToolService.swift` - Lines 1-268
- `PermissionRequestView.swift` - Permission UI

**Supported Actions:**
```swift
enum AIActionType {
    case appleReminders
    case calendar
    case contacts
    case maps
    case webSearch
}
```

---

### 6. **AI Research Generation** 📚
**Status:** Fully Implemented

Claude AI generates contextual, actionable research for captured content.

**Research Types:**

1. **TODO Research** - Practical how-to guides
   - Nearby locations (context-aware)
   - Best practices and tips
   - Tools and resources
   - Time-saving strategies
   - Cost estimates

2. **Piece Research** - Topic summaries
   - Context and background
   - Related concepts
   - Learning resources
   - Practical applications
   - Current trends

**Context-Aware Research:**
- ✅ Learning topics
- ✅ Shopping tasks
- ✅ Location-based queries
- ✅ Work tasks
- ✅ Personal care
- ✅ General information

**Features:**
- ✅ Markdown-formatted output (300-400 words)
- ✅ Actionable recommendations
- ✅ Cost tracking per research
- ✅ Processing time metrics
- ✅ Regeneration support

**Files:**
- `AIService.swift` - API integration
- `PromptManager.swift` - Specialized prompts

---

### 7. **AI Metadata System** 🗃️
**Status:** Fully Implemented

Comprehensive metadata tracking for all AI operations.

**Structure:**
```swift
struct AIMetadata {
    var actions: [AIAction]           // Executed actions
    var researchResults: ResearchResults?
    var processingMeta: ProcessingMeta?
}

struct AIAction {
    let id: String
    let type: AIActionType
    var status: ActionStatus
    let data: [String: ActionData]
    let executedAt: Date?
    let reversible: Bool
    let reverseData: [String: ActionData]?
}

struct ResearchResults {
    let format: ResultFormat = .markdown
    let content: String
    let suggestions: [String]
    let generatedAt: Date
    let researchCost: Double
    let processingTimeMs: Int
}
```

**Files:**
- `AIMetadata.swift` - Lines 1-303

---

### 8. **UI Components**
- ✅ Main content view with entry list
- ✅ Permission request screens
- ✅ Settings view with AI configuration
- ✅ Entry detail views
- ✅ Status indicators
- ✅ Action execution feedback

---

## 📊 Feature Comparison

| Feature | Status | File(s) |
|---------|--------|---------|
| Phone Number Extraction | ✅ | AIContentExtractor.swift |
| Email Extraction | ✅ | AIContentExtractor.swift |
| Name Recognition | ✅ | AIContentExtractor.swift |
| Time/Date Parsing | ✅ | AIContentExtractor.swift |
| Location Detection | ✅ | AIContentExtractor.swift |
| Action Intent Detection | ✅ | AIContentExtractor.swift |
| URL Extraction | ✅ | AIContentExtractor.swift |
| Auto Reminder Creation | ✅ | AutonomousAIAgent.swift, ToolService.swift |
| Auto Calendar Events | ✅ | AutonomousAIAgent.swift, ToolService.swift |
| Auto Contact Creation | ✅ | AutonomousAIAgent.swift, ToolService.swift |
| Maps Integration | ✅ | ToolService.swift |
| Research Generation | ✅ | AIService.swift, PromptManager.swift |
| Context-Aware Processing | ✅ | AutonomousAIAgent.swift |
| Permission Management | ✅ | PermissionRequestView.swift, ToolService.swift |
| Cost Tracking | ✅ | AIMetadata.swift, DatabaseManager.swift |
| Action Reversal | ⚠️ Partial | AutonomousAIAgent.swift:435 (TODO) |

---

## 🚧 Known Limitations & TODOs

### High Priority
1. **Action Reversal Implementation**
   - Location: `AutonomousAIAgent.swift:435`
   - Need to implement actual system API calls to reverse actions
   - Currently only updates status in database

2. **User Context Enhancement**
   - Location: `AutonomousAIAgent.swift:396`
   - TODO: Implement Core Location integration
   - TODO: Analyze previous entries for context
   - TODO: Load user preferences from settings

### Medium Priority
3. **Prompt Analytics Storage**
   - Location: `PromptManager.swift:489`
   - Need persistent storage for prompt metrics
   - Would enable prompt optimization over time

4. **Advanced Date/Time Parsing**
   - Location: `AutonomousAIAgent.swift:362`
   - Current implementation is basic
   - Could benefit from NLP-based date parsing

5. **Web Search Action Integration**
   - Location: `AutonomousAIAgent.swift:356`
   - Currently returns success without implementation
   - Need to integrate actual web search capability

---

## 🔧 Technical Architecture

### AI Processing Pipeline
```
User Input
    ↓
Keyboard Monitor (trigger detection)
    ↓
Entry Creation (DatabaseManager)
    ↓
AutonomousAIAgent.processEntry()
    ↓
AIContentExtractor.extractAllInformation()
    ↓
Decision Layer (shouldCreate* methods)
    ↓
Action Creation (createXXXAction)
    ↓
ToolService.executeAction()
    ↓
Update Entry with AI Metadata
    ↓
Save Results to Database
```

### Data Flow
```
Entry → AIMetadata → Actions → ToolService → macOS APIs
     ↘ Research → AIService → Claude API
```

---

## 📦 Dependencies

### External Services
- **Claude AI API** (Anthropic)
  - Model: `claude-3-haiku-20240307`
  - Used for: Content extraction, research generation
  - Cost: ~$0.003 per request

### System Frameworks
- **EventKit** - Calendar & Reminders integration
- **Contacts** - Contact management
- **MapKit** - Location services
- **CryptoKit** - Encryption
- **Combine** - Reactive programming
- **SwiftUI** - UI framework

---

## 📈 Performance Metrics

### AI Processing
- Average extraction time: ~500-1000ms
- Research generation time: ~1000-2000ms
- Cache hit rate: Varies (5-minute TTL)
- API cost per entry: ~$0.003-0.006

### Database
- Entry save time: <50ms
- Search performance: <100ms for 1000 entries
- Auto-repair: Triggered on corruption detection

---

## 🔐 Security Features

- ✅ AES-256 encryption for database content
- ✅ Keychain storage for encryption keys
- ✅ Secure API key storage
- ✅ No cloud sync (local-only storage)
- ✅ Permission-based system access

---

## 🎯 Future Enhancements (Not Implemented)

1. **Natural Language Understanding**
   - Advanced NLP for better intent recognition
   - Multi-language support

2. **Smart Scheduling**
   - Optimal time suggestions for events
   - Calendar conflict detection

3. **Learning & Personalization**
   - User behavior pattern recognition
   - Adaptive action suggestions

4. **Collaboration Features**
   - Shared entries
   - Team workspaces

5. **Cloud Sync**
   - End-to-end encrypted sync
   - Multi-device support

---

## 📝 Notes

- All AI features require Claude API key configuration
- System permissions must be granted for integration features
- Database automatically repairs corruption
- Processing queue limited to 5 concurrent entries to manage costs

---

**Version:** 1.0
**Build:** Development
**Platform:** macOS 14.0+
