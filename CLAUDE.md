# CLAUDE.md

[`AGENTS.md`](./AGENTS.md) is the single source of truth for this project.
Read it in full before generating, editing, or reviewing any Swift code.

---

## Claude-specific instructions

### 1. Reading order

On every new task, read `AGENTS.md` completely before writing a single line of Swift.
Do not rely on memory from a previous session — re-read the file each time.

### 2. Sections 18 and 19 apply without modification

"What the Agent Must Always Do" and "What the Agent Must Never Do" in `AGENTS.md`
are binding for Claude exactly as written. They are not suggestions.

### 3. Placement checklist before generating any file

Before creating or editing a file, confirm:

| Question | Where to look in `AGENTS.md` |
|---|---|
| Which layer does this type belong to? | §2 Architecture |
| Does it follow MVVM and Atomic Design? | §2.1, §2.2 |
| Does it comply with all five SOLID principles? | §3 |
| Is it correctly named? | §6 Naming Conventions |
| Does it need DocC comments? | §4 Documentation |
| Is it Sendable-safe under Swift 6? | §13 Swift Concurrency |
| Where does it live in the folder tree? | §5 Project Structure |
| Does it need a matching mock and tests? | §15 Testing |
| Does it persist flag values locally (UserDefaults / Keychain / SwiftData)? | §10.4 FeatureFlagStore |

### 4. When introducing a new injectable service

Follow the six-step checklist in `AGENTS.md §10.3` exactly, in order.
Do not skip the protocol definition (Step 2) or the mock (Step 6),
even if the task description does not mention them.

### 4a. When adding a remote config flag with local persistence

Follow the four-file checklist in `AGENTS.md §10.4` exactly.
Choose the storage backend **before** writing any code:
- UserDefaults — default for most flags.
- Keychain — only for sensitive values; wire via `onUpdate` in `setupSideEffects()`.
- Ephemeral — only for session-scoped values; omit `storageKey`.

Do not hardcode storage key strings. Always reference a `case` from the centralized registry.

### 5. One file per tool call by default

Generate one file at a time unless the task explicitly requests a full feature
scaffold (View + ViewModel + UseCase + Repository + Tests in one go).
Ask for confirmation before generating more than three files at once.

### 6. No content outside `AGENTS.md` scope

Do not introduce patterns, libraries, or conventions not described in `AGENTS.md`
without first flagging them as deviations and explaining the rationale.
