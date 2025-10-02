# Product Requirement Document
This file is serve as the ultimate instruction and guideline for my development; this file outlines the initiative and key features needed to be satisfied by developer.
## 1) Context & Problem

- **Background**: Note apps multiply but capturing is still slow—finding the app, opening, formatting, tagging—so ideas evaporate. Hotkey launchers help, but still require switching context; mobile is worse. Modern OS accessibility and input methods allow safe, permissioned hooks to detect user-defined triggers. On-device NLP models can classify snippets instantly.
- **Problem Statement (1–2 sentences)**: Ideas and micro-tasks appear in moments, but current tools add friction, so users forget to capture or misplace notes. We need a zero-friction, type-anywhere capture that auto-organizes and reminds.
- **Target Users/Segments**:
    1. **Students** (lectures, research links, quotes, assignments)
    2. **Knowledge workers** (todos during meetings, ideas while coding, quotes from articles)
- **User Pain Points & Evidence** (designed for you; initial hypotheses):
    - P1: Context switching to a notes app interrupts flow.
    - P2: Manual tagging/categorizing is tedious → chaotic inboxes.
    - P3: Ideas captured in wrong place (email drafts, chat) are lost.
    - P4: Reminders are inconsistent across devices.

## 2) Value Proposition & Principles

- **Unique Value**:
    - Type-anywhere capture with a **simple trigger**—zero app switching.
    - **On-device** instant categorization for privacy + speed.
    - Lightweight reminders and **universal search** across captures.
- **Product Principles**:
    1. **Invisible until needed**: no clutter, minimal CPU/RAM.
    2. **Private by default**: capture only after trigger; on-device inference; encrypted at rest.
    3. **Speed > features**: sub-150ms capture.
    4. **You own your data**: export anytime; local-first with optional sync.

## 4) Solution Overview

- **Summary**: Users type a configurable trigger (default `///`) anywhere. The app detects the trigger and captures the following text until a terminator (Enter/timeout). The snippet is auto-categorized (TODO/IDEA/QUOTE/OTHER), optionally enriched (date, app context, URL), stored locally (encrypted), synced if enabled, and available in an **Inbox** UI for quick edit, reminder, and tag. Universal search and smart lists (Today, This Week, Ideas) help review.
- **Key Use Cases**: Quick TODO, fleeting IDEA, QUOTE save, capture with natural reminder, cross-app context capture (URL from browser, line from IDE).

## 5) Scope & Requirements

- **Functional Requirements (numbered, testable)**:
    1. The system SHALL detect a configurable trigger token (default `///`) in any focused text field and begin capture mode within **<50ms**.
    2. The system SHALL capture characters after the trigger until one of: Enter, configurable terminator, or **3s** idle timeout.
    3. The system SHALL strip the trigger from stored text and persist the snippet with timestamp, app name, window title, and (if browser) URL.
    4. The system SHALL run on **macOS (13+) and Windows (11)** in v1.
    5. The system SHALL classify the snippet into {TODO, IDEA, QUOTE, OTHER} on-device with **≥85% precision** for top-3 classes.
    6. The system SHALL support inline reminder parsing: `@<date/time>` and `in <duration>` (e.g., `in 2h`).
    7. The system SHALL create system notifications for due reminders and support snooze (5/15/60 min).
    8. The system SHALL provide an Inbox view with edit, recategorize, tag, done/archive.
    9. The system SHALL allow per-app allow/deny lists and a global **Pause** toggle.
    10. The system SHALL store data **encrypted at rest** (AES-256) with OS-secure keychain.
    11. The system SHALL export data to JSON/CSV.
    12. The system SHALL operate within **<2% average CPU** and **<200MB RAM** during idle; capture spike **<500ms** CPU spike.
    13. The system SHALL log only product telemetry with user opt-in and **never** store raw keystrokes beyond trigger sessions.
    14. The system SHALL provide full audit of captured events per day for user review.
    15. The system SHOULD support i18n tokenization (English/Chinese) for date/time parsing.
    16. The system SHOULD auto-merge duplicates (same text within 10 min from same app).
    17. The system COULD support mobile keyboard extension (iOS/Android) in Phase 2.
- **Non-Functional Requirements**:
    - Availability: local app; notifications must fire ≥99.9%/week when device awake.
    - Latency: trigger detect <50ms; capture persist <100ms; classify <150ms p95.
    - Security: least-privileged access; code-signed; notarized; sandboxed; no network without consent.
    - A11y: keyboard-only ops; high-contrast mode; screen reader labels.
    - i18n: EN/ZH baseline.
    - Power: no background scanning outside focus fields; adaptive throttling on battery.
- **Data & Privacy Requirements**:
    - D1: Default **capture only after trigger**; no continuous keystroke logging stored.
    - D2: On-device classification; cloud sync optional and end-to-end encrypted.
    - D3: Data export & delete (Right to be Forgotten); clear consent flows; DPIA on file.
    - D4: Sensitive-app denylist on by default (password managers, banking).
- **Telemetry & Experimentation**:
    - Opt-in analytics: event counts (capture_started/saved, classify_result, reminder_fired), timings, errors; **no raw text** unless redacted and user-approved.
    - A/B: default trigger `///` vs `;;`; digest on/off; different reminder nudges.

## 6) UX & Content

- **User Flows**:
    1. **Capture**: User types `///` + text → Enter → toast “Saved” → Inbox item appears.
    2. **Reminder**: User types `@Fri 5pm` → scheduled → system notification → Snooze/Done.
    3. **Review**: Open Inbox → Smart Lists (Today, Upcoming, Ideas) → Edit/Archive.
    4. **Privacy**: First-run → permissions → per-app allow/deny → test trigger.
- **Wireframe Notes (textual)**:
    - **Mini Toast**: bottom-right, 2s, “Captured to TODO · Set reminder?”
    - **Inbox**: Tabs (All, TODO, Ideas, Quotes), filters (app, time), quick actions (bell, tag, done).
    - **Settings**: Trigger, Reminder parsing, Denylist, Export, Privacy, Sync.
- **Content Style & Microcopy**:
    - Short, affirmative, no jargon: “Captured.” “Reminder set.” “Paused in Chrome.”
    - Privacy-forward: “We only listen for your trigger. Nothing else is saved.”