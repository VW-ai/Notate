# AI-Native Evolution for Notate

## Vision
- Provide a single, natural capture gesture (text, voice, or command palette) that hands the rest of the flow to an autonomous agent.
- Let Notate feel like an active teammate: it understands intent, plans the work, executes across apps, and keeps the user in the loop only when decisions are needed.
- Preserve the local-first, privacy-conscious foundation while enabling optional cloud capabilities for users who opt in.

## Agentic Spine
- **AgentOrchestrator**: A background service that subscribes to capture notifications (`Notate.didFinishCapture`) and turns each entry into a task graph (intent → context → plan → execution → follow-up).
- **Capability Adapters**: Pluggable actions for Calendar, Mail, Reminders, Shortcuts, browser automation, third-party APIs, etc. The orchestrator selects and sequences adapters using an LLM planner with guardrails.
- **Stateful Plans**: Extend entry metadata (`metadata.agent_state`) to track lifecycle (detected, waiting for context, executing, succeeded, blocked). Surface the state to the UI and allow resumption after restart.
- **Feedback Loop**: Log agent outcomes and user interventions to refine prompts, adjust confidence thresholds, and personalize automation without exposing users to configuration screens.

## Doing Real Work
- **Calendar Automation**: Parse intent like “move lunch with Alice to tomorrow” and auto-update calendar events, prompting only when ambiguity exists.
- **Follow-up Execution**: For “email Y about Z”, draft the message, attach relevant docs, and queue it for one-tap send inside Mail or the Activity Feed.
- **Checklist Expansion**: Turn vague TODOs into structured subtasks, automatically handling straightforward steps (creating docs, gathering links) and returning progress updates.
- **Meeting Intelligence**: Before meetings, assemble briefs from recent entries; afterward, synthesize notes and push resultant tasks into the queue.
- **Cross-App Sync**: Sync critical actions with a user’s preferred task system (Things, Todoist, Jira) and reconcile status bi-directionally.

## Frictionless Interaction
- **Universal Capture**: Replace multiple triggers with a single hotkey command palette that understands natural language, voice, or quick shorthand. Triggers remain as fallbacks.
- **“Just Do It” Mode**: By default, the agent executes low-risk tasks immediately. Use inline toasts for status, escalate to confirmations only for high-impact actions.
- **Context Sniffers**: Watch clipboard, active window titles, calendar context, and recent conversations to auto-fill missing entities (people, files, deadlines) with zero extra input.
- **Activity Feed**: A minimal timeline that shows what the agent is doing (planned → in progress → done) with a single control to undo or edit—no deep settings pages.
- **Progressive Trust**: Adapt confirmation behavior based on user acceptance history, learning when silent execution is appropriate.

## Implementation Roadmap
1. **Agent Skeleton**: Implement AgentOrchestrator, task schema, and metadata updates. Start with mocked capability execution to validate flow.
2. **LLM Planner Integration**: Add an intent-to-plan layer (local model if possible) that maps captured text + context to structured tasks with confidence scores.
3. **Core Capabilities**: Ship Calendar and Mail adapters first, each behind a clear permission prompt. Log outcomes for iterative tuning.
4. **Activity Feed UI**: Surface agent actions within the existing SwiftUI layout, leveraging `AppState` to bind metadata to views.
5. **Semantic & Context Layers**: Introduce embeddings for search, context gatherers (clipboard/active window), and optional voice capture.
6. **Expansion & Personalization**: Add third-party connectors, introduce daily AI digests/summaries, and refine automation thresholds using feedback data.

## Guiding Principles
- Default to privacy: run on-device when feasible and ask before touching external services.
- Fail gracefully: every automation must produce a reversible artifact (draft email, staged calendar change) so users never lose control.
- Keep cognition low: one capture gesture, one activity feed, everything else hidden unless it matters.
- Iterate with humans-in-the-loop: start with semi-automated flows, gather data on trust, and ramp autonomy where users show confidence.
