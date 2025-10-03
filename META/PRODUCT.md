# Product Requirement Document - MVP
This file serves as the ultimate instruction and guideline for MVP development; this file outlines the initiative and key features needed to be satisfied by developer.

## 1) Context & Problem

- **Background**: Note apps multiply but capturing is still slow—finding the app, opening, formatting, tagging—so ideas evaporate. Modern OS accessibility and input methods allow safe, permissioned hooks to detect user-defined triggers. Local embedding models can classify snippets efficiently without external dependencies.
- **Problem Statement (1–2 sentences)**: Ideas and micro-tasks appear in moments, but current tools add friction, so users forget to capture or misplace notes. We need a zero-friction, type-anywhere capture that auto-categorizes using local embeddings.
- **Target Users/Segments**:
    1. **Knowledge workers** (todos during meetings, random thoughts while coding)
    2. **Students** (quick todos, fleeting thoughts during study)
- **User Pain Points & Evidence** (MVP focus):
    - P1: Context switching to a notes app interrupts flow.
    - P2: Manual categorizing between actionable todos and random thoughts is tedious.

## 2) Value Proposition & Principles

- **MVP Unique Value**:
    - Type-anywhere capture with a **simple trigger**—zero app switching.
    - **Local embedding-based** classification between TODOs and Random Thoughts.
    - Timestamped capture with clean, tasteful UI.
- **MVP Product Principles**:
    1. **Serverless & Local**: no external dependencies; all processing on-device.
    2. **Embedding-based classification**: local embedding model with similarity scoring algorithm.
    3. **Simple categorization**: only TODO vs Random Thoughts.
    4. **Focus on scoring system**: extensible classification architecture for future expansion.

## 4) MVP Solution Overview

- **Summary**: Users type a configurable trigger (default `///`) anywhere. The app detects the trigger and captures the following text until a terminator (Enter/timeout). The snippet is classified as either TODO or Random Thought using local embedding similarity scoring against pre-generated sample embeddings. Data is stored locally with timestamp and displayed in a clean, tasteful frontend.
- **Key Use Cases**: Quick TODO capture, fleeting thought capture, timestamped review of all captures.
- **Technical Architecture**:
    - **Classification Engine**: Local embedding model generates embeddings for captured text
    - **Scoring Algorithm**: Compares input embedding against sample embeddings for each category using similarity metrics
    - **Sample Database**: Pre-generated embeddings for typical TODO and Random Thought examples
    - **Frontend**: Simple, good-taste UI displaying categorized items with timestamps

## 5) MVP Scope & Requirements

- **MVP Functional Requirements (numbered, testable)**:
    1. The system SHALL detect a configurable trigger token (default `///`) in any focused text field and begin capture mode within **<50ms**.
    2. The system SHALL capture characters after the trigger until one of: Enter, configurable terminator, or **3s** idle timeout.
    3. The system SHALL strip the trigger from stored text and persist the snippet with **timestamp only**.
    4. The system SHALL run on **macOS (13+)** initially.
    5. The system SHALL classify the snippet into {TODO, Random Thought} using **local embedding similarity scoring** with **≥80% accuracy**.
    6. The system SHALL maintain a **sample embedding database** with pre-generated embeddings for each category.
    7. The system SHALL implement a **similarity scoring algorithm** (placeholder for future enhancement) that compares input embeddings against sample embeddings.
    8. The system SHALL provide a simple, tasteful **frontend view** displaying categorized items with timestamps.
    9. The system SHALL store data **locally** (no encryption required for MVP).
    10. The system SHALL operate **serverless** with no external API dependencies.

- **MVP Technical Requirements**:
    - **Embedding Model**: Local lightweight embedding model (e.g., sentence-transformers)
    - **Scoring System**: Extensible architecture allowing algorithm improvements
    - **Data Storage**: Simple local storage (JSON/SQLite)
    - **Frontend**: Clean, minimal UI showing TODO vs Random Thought categorization

- **MVP Non-Functional Requirements**:
    - **Latency**: trigger detect <50ms; capture persist <100ms; classify <200ms p95
    - **Privacy**: capture only after trigger; no continuous keystroke logging
    - **Performance**: local processing only; minimal CPU/RAM footprint
    - **Reliability**: consistent classification results; stable embedding generation

- **MVP Data Requirements**:
    - **Local-only**: all data stored and processed locally
    - **Simple storage**: timestamp + text + classification
    - **No encryption**: simplified MVP data handling

- **Deferred Features (Post-MVP)**:
    - Reminders and notifications
    - Multi-platform support (Windows)
    - Data encryption and export
    - Advanced UI features (search, filters, tags)
    - App context capture (URLs, window titles)
    - Privacy controls and app allow/deny lists

## 6) MVP UX & Content

- **MVP User Flows**:
    1. **Capture**: User types `///` + text → Enter → classification happens → item appears in UI
    2. **Review**: Open app → see TODOs and Random Thoughts with timestamps
    3. **Setup**: First-run → set trigger → test capture → ready to use

- **MVP UI (textual wireframe)**:
    - **Main View**: Two sections - "TODOs" and "Random Thoughts"
    - **Item Display**: Text + timestamp for each captured item
    - **Simple Layout**: Clean, minimal design focusing on content readability

- **MVP Content Style**:
    - Minimal, clear: "TODO captured" / "Thought captured"
    - Focus on content, not features

## 7) MVP Development Focus

- **Primary Development Areas**:
    1. **Embedding Pipeline**: Local model integration and embedding generation
    2. **Scoring Algorithm**: Similarity calculation and classification logic
    3. **Sample Database**: Curated TODO vs Random Thought training examples
    4. **Classification Accuracy**: Iterative improvement of scoring methodology
    5. **Performance Optimization**: Fast, local processing without external dependencies