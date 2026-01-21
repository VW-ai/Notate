# ADR-0001: Use Tauri for Desktop Framework

- **Status**: Accepted
- **Date**: 2025-01-20
- **Deciders**: Project Team

## Context

Notate is a desktop application that requires:
- Global hotkey support for Quick Capture overlay
- Native system integration (file system, clipboard)
- Small application bundle size
- Cross-platform support (Mac priority, Windows/Linux later)
- High performance for AI processing and vector search

We need to choose a desktop framework that meets these requirements while allowing efficient development.

## Decision

Use **Tauri 2.0** as the desktop framework with:
- **Frontend**: React 18 + TypeScript
- **Backend**: Rust for native functionality
- **State Management**: Zustand (lightweight)

## Alternatives Considered

### Alternative 1: Electron
- **Pros**:
  - Large ecosystem and community
  - Familiar web development model
  - Many existing examples and libraries
- **Cons**:
  - Large bundle size (~150MB+)
  - Higher memory usage
  - Performance overhead for native operations
- **Why not**: Bundle size and performance requirements make Electron unsuitable for a lightweight "always running" overlay application.

### Alternative 2: Native macOS (Swift/AppKit)
- **Pros**:
  - Best macOS integration
  - Smallest bundle size
  - Best performance
- **Cons**:
  - Mac-only (no cross-platform)
  - Requires learning Swift/AppKit
  - Longer development time
- **Why not**: Cross-platform support is needed for future expansion, and the team has more web development experience.

### Alternative 3: Flutter Desktop
- **Pros**:
  - Cross-platform with single codebase
  - Good performance
  - Growing ecosystem
- **Cons**:
  - Limited desktop ecosystem maturity
  - Dart language learning curve
  - Less native integration options
- **Why not**: Desktop support is still maturing, and native integrations (hotkeys, system tray) are less robust.

## Consequences

### Positive
- Small bundle size (~10MB) suitable for overlay application
- Rust backend provides excellent performance for AI/vector operations
- Strong security model (no Node.js in backend)
- Native system integrations via Rust
- Web-based frontend enables rapid UI development

### Negative
- Learning curve for Rust backend development
- Smaller ecosystem compared to Electron
- Some web libraries may not work out of the box
- Debugging across JS/Rust boundary can be complex

### Risks
- **Risk**: Tauri 2.0 is relatively new, may have undiscovered issues
  - **Mitigation**: Monitor Tauri releases, have fallback plan for critical features
- **Risk**: Team may struggle with Rust
  - **Mitigation**: Keep Rust code focused on core services, use existing libraries

## Related

- [Technical.md](../Core/Technical.md) - Full architecture documentation
- [Tauri Documentation](https://tauri.app/)
- [Product.md](../Core/Product.md) - Product requirements driving this decision
