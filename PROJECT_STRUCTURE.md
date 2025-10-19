# Notate Project Structure

## Overview

Notate is now a **multiplatform application** supporting both macOS and iOS/iPadOS. The codebase is organized to maximize code reuse while maintaining platform-specific optimizations.

**Code Reuse**: ~85% shared, ~15% platform-specific

---

## Directory Structure

```
Notate/
├── Shared/                          ← Platform-agnostic code (85%)
│   ├── Models/
│   │   ├── Entry.swift              ✅ Core data model
│   │   └── AIMetadata.swift         ✅ AI processing metadata
│   │
│   ├── Services/
│   │   ├── AIService.swift          ✅ Claude API integration
│   │   ├── AIContentExtractor.swift ✅ AI content extraction
│   │   ├── PromptManager.swift      ✅ AI prompt templates
│   │   ├── AutonomousAIAgent.swift  ⚠️  Platform-specific parts (ToolService)
│   │   ├── ToolService.swift        ⚠️  macOS/iOS API differences
│   │   └── PermissionManager.swift  ⚠️  macOS/iOS permission APIs
│   │
│   ├── Database/
│   │   └── DatabaseManager.swift    ✅ SQLite + AES-256 encryption
│   │
│   ├── Design/
│   │   └── ModernDesignSystem.swift ✅ Design tokens & colors
│   │
│   └── Configuration/
│       └── TriggerConfiguration.swift ⚠️ Platform-specific trigger mechanisms
│
├── macOS/                           ← macOS-specific code
│   ├── NotateApp.swift              macOS app lifecycle (NSApplication)
│   ├── CaptureEngine.swift          Global keyboard event monitoring
│   ├── KeyTranslator.swift          Carbon framework key code translation
│   │
│   └── Views/
│       ├── ContentView.swift        3-column NavigationSplitView
│       ├── EntryDetailView.swift    NSAlert, NSWorkspace APIs
│       ├── SettingsView.swift       macOS System Settings integration
│       └── [Other macOS-specific views]
│
├── iOS/                             ← iOS-specific code
│   ├── NotateApp.swift              iOS app lifecycle (UIApplication)
│   ├── Notate.entitlements          iOS capabilities & permissions
│   ├── Info.plist                   iOS-specific configuration
│   │
│   └── Views/
│       ├── ContentView.swift        TabView (iPhone) / NavigationSplitView (iPad)
│       ├── EntryDetailView.swift    UIKit alerts, UIApplication.open
│       ├── QuickCaptureView.swift   In-app quick capture UI
│       └── [Other iOS-specific views]
│
├── NotateKeyboard/                  ← iOS Keyboard Extension (Phase 3)
│   ├── KeyboardViewController.swift Custom keyboard with "///" trigger
│   ├── Info.plist                   Keyboard extension configuration
│   └── [Keyboard UI components]
│
├── NotateShareExtension/            ← iOS Share Extension (Phase 4)
│   ├── ShareViewController.swift    Share text to Notate
│   └── Info.plist
│
├── NotateWidget/                    ← iOS Widget Extension (Phase 4)
│   ├── NotateWidget.swift           Home screen widget
│   └── Info.plist
│
├── META/                            ← Documentation
│   ├── STATUS.md                    Feature implementation status
│   ├── MOBILE.md                    Mobile implementation plan
│   ├── AI_UNIFIED_IMPLEMENTATION_GUIDE.md
│   ├── DEMO.md
│   └── SECURITY.md
│
├── Assets.xcassets/                 ← Shared assets (icons, images)
├── Notate.xcodeproj/                ← Xcode project file
└── README.md                        ← Main documentation

```

---

## Platform-Specific Implementations

### 1. Input Capture

| Platform | Mechanism | Implementation |
|----------|-----------|----------------|
| **macOS** | Global keyboard monitoring | `NSEvent.addGlobalMonitorForEvents` in `CaptureEngine.swift` |
| **iOS** | Custom Keyboard Extension | Keyboard Extension + App Groups communication |

### 2. App Lifecycle

| Platform | Entry Point | Framework |
|----------|-------------|-----------|
| **macOS** | `macOS/NotateApp.swift` | AppKit (`NSApplication`) |
| **iOS** | `iOS/NotateApp.swift` | UIKit (`UIApplication`) |

### 3. Navigation UI

| Platform | Layout | Implementation |
|----------|--------|----------------|
| **macOS** | 3-column NavigationSplitView | Sidebar → List → Detail |
| **iPhone** | TabView + NavigationStack | Bottom tabs, full-screen navigation |
| **iPad** | NavigationSplitView (like macOS) | Adaptive layout |

### 4. System Integration

#### Calendar & Reminders
- **Both platforms**: EventKit framework (same API)
- Implementation: `Shared/Services/ToolService.swift` with `#if os()` directives

#### Contacts
- **Both platforms**: Contacts framework (same API)
- Implementation: `Shared/Services/ToolService.swift`

#### Maps
- **Both platforms**: MapKit framework
- **Difference**: URL schemes differ
  - macOS: `maps://` + `NSWorkspace.shared.open()`
  - iOS: `maps://` + `UIApplication.shared.open()`

#### Alerts
- **macOS**: `NSAlert`
- **iOS**: `UIAlertController` or SwiftUI `.alert()` modifier

### 5. Permissions

| Permission | macOS API | iOS API |
|------------|-----------|---------|
| Calendar | `EKEventStore.requestFullAccessToEvents()` | Same |
| Reminders | `EKEventStore.requestFullAccessToReminders()` | Same |
| Contacts | `CNContactStore.requestAccess(for:)` | Same |
| Location | `CLLocationManager.requestWhenInUseAuthorization()` | Same |

---

## Xcode Targets

### Current Targets

1. **Notate (macOS)** - Original macOS application
   - Bundle ID: `com.notate.macos`
   - Deployment Target: macOS 14.0+

2. **Notate iOS** - New iOS/iPadOS application
   - Bundle ID: `com.notate.ios`
   - Deployment Target: iOS 17.0+
   - Supports: iPhone, iPad

### Future Targets (Phase 3-4)

3. **NotateKeyboard** - iOS Keyboard Extension
   - Bundle ID: `com.notate.ios.keyboard`
   - Container App: Notate iOS

4. **NotateShareExtension** - iOS Share Extension
   - Bundle ID: `com.notate.ios.share`
   - Container App: Notate iOS

5. **NotateWidget** - iOS Widget Extension
   - Bundle ID: `com.notate.ios.widget`
   - Container App: Notate iOS

---

## App Groups Configuration

**App Group ID**: `group.com.notate.shared`

### Purpose
Enable data sharing between:
- Main iOS app
- Keyboard Extension
- Share Extension
- Widget Extension

### Shared Resources
- Pending captures from keyboard
- Recent entries for widget
- User preferences

### Implementation
```swift
// Access App Group shared storage
let userDefaults = UserDefaults(suiteName: "group.com.notate.shared")
userDefaults?.set(content, forKey: "pendingCapture")
```

---

## Code Sharing Strategy

### ✅ Fully Shared (100% reuse)

**Models**
- `Entry.swift` - Core entry data model
- `AIMetadata.swift` - AI processing metadata
- All data structures are platform-agnostic

**AI Services**
- `AIService.swift` - Claude API integration
- `AIContentExtractor.swift` - Content extraction logic
- `PromptManager.swift` - Prompt templates
- Pure Swift, no platform dependencies

**Database**
- `DatabaseManager.swift` - SQLite + encryption
- Works identically on macOS and iOS

**Design System**
- `ModernDesignSystem.swift` - Colors, typography, spacing
- Minor size adjustments for mobile via `#if os(iOS)`

### ⚠️ Platform-Specific Adaptations

**ToolService.swift** - System integration
```swift
func openURL(_ url: URL) {
    #if os(macOS)
    NSWorkspace.shared.open(url)
    #elseif os(iOS)
    UIApplication.shared.open(url)
    #endif
}
```

**AutonomousAIAgent.swift** - Uses ToolService
- Core logic shared
- Platform differences handled by ToolService

**PermissionManager.swift** - Permission UI
- Core status checking shared
- UI presentation platform-specific

### ❌ Platform-Exclusive

**macOS Only**
- `CaptureEngine.swift` - NSEvent keyboard monitoring
- `KeyTranslator.swift` - Carbon framework
- macOS `ContentView.swift` - AppKit integration

**iOS Only**
- Keyboard Extension
- Share Extension
- Widget Extension
- iOS `ContentView.swift` - UIKit integration

---

## Build Configuration

### Preprocessor Flags

Use conditional compilation for platform-specific code:

```swift
#if os(macOS)
// macOS-specific code
import AppKit
#elseif os(iOS)
// iOS-specific code
import UIKit
#endif
```

### Target Membership

**Ensure correct target membership**:
- `Shared/` files: ✅ Both macOS and iOS targets
- `macOS/` files: ✅ macOS target only
- `iOS/` files: ✅ iOS target only

---

## Development Workflow

### Adding New Features

1. **Determine if feature is platform-agnostic**
   - Yes → Add to `Shared/`
   - No → Add to `macOS/` or `iOS/`

2. **Update target memberships in Xcode**
   - Right-click file → Target Membership
   - Check appropriate targets

3. **Use conditional compilation for platform differences**
   ```swift
   #if os(macOS)
   // macOS implementation
   #else
   // iOS implementation
   #endif
   ```

### Testing Strategy

- **Unit Tests**: Focus on `Shared/` code (platform-agnostic)
- **UI Tests**: Separate for macOS and iOS
- **Integration Tests**: Test AI pipeline on both platforms

---

## Current Status (Phase 1 Complete ✅)

### ✅ Completed
- [x] Created multiplatform folder structure
- [x] Separated shared code into `Shared/`
- [x] Created platform-specific folders (`macOS/`, `iOS/`)
- [x] iOS `NotateApp.swift` with URL scheme handling
- [x] iOS `ContentView.swift` with adaptive layout (iPhone/iPad)
- [x] iOS `Info.plist` with all permissions
- [x] iOS `Notate.entitlements` with App Groups
- [x] Project structure documentation

### 🚧 In Progress
- [ ] Xcode project configuration (targets, schemes)
- [ ] Build settings for iOS target
- [ ] Code signing setup

### 📋 Next Steps (Phase 2)
- [ ] Port platform-specific Views to iOS
- [ ] Adapt `EntryDetailView` for iOS
- [ ] Test database operations on iOS simulator
- [ ] Verify AI pipeline on iOS
- [ ] Test EventKit, Contacts, MapKit on iOS

---

## File Naming Conventions

To avoid confusion in multiplatform projects:

1. **Shared files**: No platform suffix
   - `Entry.swift` (not `Entry-Shared.swift`)

2. **Platform-specific files with same name**:
   - Place in platform folder: `macOS/ContentView.swift`, `iOS/ContentView.swift`
   - Xcode will use the correct file based on target membership

3. **iOS-exclusive features**: Descriptive names
   - `QuickCaptureView.swift` (iOS only)
   - `KeyboardViewController.swift` (Keyboard Extension)

---

## Dependencies

### Shared Dependencies (Both Platforms)
- **No external dependencies** - Pure Swift/SwiftUI
- SQLite (built-in)
- Foundation, SwiftUI, Combine

### macOS-Specific
- AppKit
- Carbon.framework (key codes)

### iOS-Specific
- UIKit (for extensions)
- WidgetKit (Phase 4)
- Intents / IntentsUI (Phase 4, Siri Shortcuts)

---

## Troubleshooting

### "File not found" errors
- **Check target membership** in Xcode File Inspector
- Ensure file is included in correct target

### Code signing issues
- **macOS**: Disable sandbox for keyboard monitoring
- **iOS**: Enable App Groups in capabilities

### Build errors with conditional compilation
- Ensure `#if os()` blocks are syntactically correct
- Import correct frameworks in each block

---

## References

- **MOBILE.md** - Detailed mobile implementation plan
- **STATUS.md** - Current feature implementation status
- **Apple Documentation**: [Building Multiplatform Apps](https://developer.apple.com/documentation/swiftui/building-a-multiplatform-app)

---

**Last Updated**: 2025-10-07
**Phase**: 1 (Project Setup) - ✅ Complete
**Next Phase**: 2 (Core iOS App) - Starting
