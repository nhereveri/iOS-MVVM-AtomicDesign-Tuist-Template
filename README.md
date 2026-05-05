# iOS MVVM · Atomic Design · Tuist Template

A production-ready iOS project template built with **SwiftUI**, **MVVM**, **Atomic Design**, and **Tuist**. Designed to be cloned or forked once and re-used as the starting point for any new B2C iOS application.

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Getting the Template](#2-getting-the-template)
   - [Option A — Fork on GitHub](#option-a--fork-on-github)
   - [Option B — Clone and push to a new repository](#option-b--clone-and-push-to-a-new-repository)
3. [Configure Your Project](#3-configure-your-project)
4. [Install Dependencies](#4-install-dependencies)
5. [Generate the Xcode Project](#5-generate-the-xcode-project)
6. [Environments and Schemes](#6-environments-and-schemes)
7. [Project Structure](#7-project-structure)
8. [Daily Development Workflow](#8-daily-development-workflow)
9. [Adding External Packages](#9-adding-external-packages)
10. [CI/CD — GitHub Actions](#10-cicd--github-actions)
11. [Architecture Reference](#11-architecture-reference)

---

## 1. Prerequisites

Install the following tools before starting. All are available via [Homebrew](https://brew.sh).

```bash
# Install Homebrew if you don't have it
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

| Tool | Version | Install |
|---|---|---|
| Xcode | 16.0+ | App Store |
| Xcode Command Line Tools | — | `xcode-select --install` |
| Tuist | 4.x | See below |
| SwiftLint | Latest | `brew install swiftlint` |
| SwiftFormat | Latest | `brew install swiftformat` |

### Installing Tuist

```bash
curl -Ls https://install.tuist.io | bash
```

Verify the installation:

```bash
tuist version
# Expected: 4.x.x
```

---

## 2. Getting the Template

Choose **one** of the two options below.

---

### Option A — Fork on GitHub

Use this option if you want to keep a connection to the template and pull future improvements.

1. Open the template repository on GitHub and click **Fork**.
2. Name your fork after your app (e.g. `MyPersonalApp`), then click **Create fork**.
3. Clone your fork locally:

```bash
git clone https://github.com/your-username/MyPersonalApp.git
cd MyPersonalApp
```

---

### Option B — Clone and push to a new repository

Use this option if you want a clean, independent repository with no link to the template.

**Step 1 — Clone the template**

```bash
git clone https://github.com/your-username/iOS-MVVM-AtomicDesign-Tuist-Template.git MyPersonalApp
cd MyPersonalApp
```

**Step 2 — Replace the Git history**

```bash
# Remove the template's git history
rm -rf .git

# Start a fresh repository
git init
git branch -M main
```

**Step 3 — Create a new repository on GitHub**

Go to [github.com/new](https://github.com/new), name it `MyPersonalApp`, leave it **empty** (no README, no .gitignore), then run:

```bash
git remote add origin https://github.com/your-username/MyPersonalApp.git
```

**Step 4 — Make the initial commit**

```bash
git add .
git commit -m "chore: initial project from iOS MVVM Atomic Design Tuist template"
git push -u origin main
```

---

## 3. Configure Your Project

Open `Project.swift` in any text editor. At the very top you will find the **Template Variables** block — this is the only section you need to edit:

```swift
// ============================================================
// MARK: - Template Variables
// Edit the values in this block for each new project.
// ============================================================

let projectName: String = "MyPersonalApp"
let bundleIdPrefix: String = "cl.hereveri"
let organizationName: String = "Hereveri"
let marketingVersion: String = "0.0.1"
let currentProjectVersion: String = "1"
let iOSDeploymentTarget: String = "18.0"
let developmentRegion: String = "en"
let knownRegions: [String] = ["en", "es"]
```

> **How bundle IDs are derived**
> The app bundle ID is built automatically as `"\(bundleIdPrefix).\(projectName.lowercased())"`.
> With the values above this resolves to `cl.hereveri.mypersonalapp`.

After saving `Project.swift`, also update `Tuist/Config.swift` if you want to pin a specific Xcode version:

```swift
let config = Config(
    compatibleXcodeVersions: .upToNextMajor("16.0"),
    swiftVersion: "6.0"
)
```

---

## 4. Install Dependencies

Tuist manages external Swift packages separately from the Xcode project. Run this once after cloning (and again whenever you add or update a package):

```bash
tuist install
```

This resolves and caches all packages declared in the `packages` array inside `Project.swift`.

---

## 5. Generate the Xcode Project

**Never open a `.xcodeproj` file directly.** Always use Tuist to generate it:

```bash
tuist generate
```

This will:
1. Resolve the project manifest (`Project.swift`)
2. Generate `MyPersonalApp.xcodeproj` (git-ignored)
3. Open Xcode automatically

> The generated `.xcodeproj` and `.xcworkspace` files are **not committed** to the repository. Every developer on the team runs `tuist generate` after cloning.

Add the following to your `.gitignore` (already included in this template):

```
*.xcodeproj
*.xcworkspace
DerivedData/
.build/
```

---

## 6. Environments and Schemes

The template ships with **4 build configurations** and **4 Xcode schemes**, one per environment. Every configuration has its own bundle ID so all four builds can be installed on the same device simultaneously.

| Scheme | Configuration | Bundle ID suffix | Display name | Server | Distributed via |
|---|---|---|---|---|---|
| `MyApp (Dev)` | `Debug` | `.dev` | `MyApp Dev` | `localhost` / mock | Developer only |
| `MyApp (Staging)` | `Staging` | `.staging` | `MyApp STG` | Staging server | TestFlight (team) |
| `MyApp (UAT)` | `UAT` | `.uat` | `MyApp UAT` | Pre-production server | TestFlight (QA / client) |
| `MyApp` | `Release` | _(none)_ | `MyApp` | Production server | App Store |

### How environment values are injected

The API base URL, environment name, and display name are set as **Xcode build settings** per configuration inside `Project.swift` and then forwarded into `Info.plist` via variable substitution (e.g. `$(API_BASE_URL)`). At runtime your `APIClient` reads them from the bundle — no `#if DEBUG` needed anywhere in Swift code:

```swift
// Core/Utilities/AppEnvironment.swift
enum AppEnvironment {
    static var apiBaseURL: URL {
        guard
            let raw = Bundle.main.infoDictionary?["API_BASE_URL"] as? String,
            let url = URL(string: raw)
        else { fatalError("API_BASE_URL missing from Info.plist") }
        return url
    }

    static var name: String {
        Bundle.main.infoDictionary?["APP_ENV"] as? String ?? "unknown"
    }
}
```

### Changing API URLs

Open the **Template Variables** block at the top of `Project.swift` and update the four URL constants:

```swift
let apiBaseURLDebug:      String = "http://localhost:8080/api/v1"
let apiBaseURLStaging:    String = "https://api.staging.yourcompany.com/api/v1"
let apiBaseURLUAT:        String = "https://api.uat.yourcompany.com/api/v1"
let apiBaseURLProduction: String = "https://api.yourcompany.com/api/v1"
```

Then regenerate the project:

```bash
tuist generate
```

### Conditional compilation flags

Each configuration defines its own `SWIFT_ACTIVE_COMPILATION_CONDITIONS` flag. Use these sparingly and only for development tooling — never for business logic:

| Configuration | Flag |
|---|---|
| Debug | `DEBUG` |
| Staging | `STAGING` |
| UAT | `UAT` |
| Release | _(none)_ |

```swift
// Example: show a debug overlay only in Dev builds
#if DEBUG
DebugOverlayView()
#endif
```

---

## 7. Project Structure

```
MyPersonalApp/
├── Project.swift                        # ← Tuist project manifest (edit template vars here)
├── Tuist/
│   └── Config.swift                     # ← Tuist global config (Xcode & Swift versions)
├── Sources/
│   ├── App/
│   │   ├── MyPersonalAppApp.swift       # @main entry point
│   │   ├── AppCoordinator.swift         # Root navigation coordinator
│   │   └── DependencyContainer.swift    # Environment wiring
│   ├── Features/
│   │   └── [FeatureName]/
│   │       ├── [FeatureName]Coordinator.swift
│   │       └── [ScreenName]/
│   │           ├── [ScreenName]View.swift
│   │           ├── [ScreenName]ViewModel.swift
│   │           └── [ScreenName]UseCase.swift
│   ├── Domain/
│   │   ├── Entities/                    # Pure Swift models (Sendable, Codable)
│   │   ├── Repositories/               # Repository protocols
│   │   └── UseCases/                   # Shared use cases
│   ├── Data/
│   │   ├── Network/
│   │   │   ├── APIClient.swift
│   │   │   ├── Endpoint.swift
│   │   │   └── Repositories/           # Concrete repository implementations
│   │   └── Persistence/                # SwiftData / Keychain wrappers
│   ├── DesignSystem/
│   │   ├── Atoms/                      # Buttons, labels, icons, text fields
│   │   ├── Molecules/                  # Form rows, list cells, input groups
│   │   ├── Organisms/                  # Headers, cards, sections
│   │   ├── Templates/                  # Layout shells (ViewBuilder)
│   │   └── Extensions/                 # Color+, Font+, CGFloat+, ViewModifier
│   └── Core/
│       ├── Extensions/                 # Swift stdlib extensions
│       ├── Utilities/                  # DateFormatter, validators, etc.
│       └── Coordinators/              # Base coordinator types
├── Tests/
│   └── [FeatureName]Tests/
│       ├── ViewModelTests/
│       ├── UseCaseTests/
│       └── RepositoryTests/
├── Resources/
│   ├── Assets.xcassets                 # Colors (light/dark), images, icons
│   ├── Localizable.xcstrings           # String catalogs (base: English)
│   └── Fonts/
├── .swiftlint.yml                      # SwiftLint rules
├── .swiftformat                        # SwiftFormat rules
└── CLAUDE.md                           # Architecture guidelines for Claude
```

---

## 8. Daily Development Workflow

### Start of day / after pulling changes

```bash
tuist install       # Fetch any new or updated packages
tuist generate      # Re-generate the Xcode project
```

### Running the app

Open the generated `MyPersonalApp.xcodeproj` and press **⌘R**, or from the terminal:

```bash
tuist run MyPersonalApp
```

### Running tests

```bash
tuist test MyPersonalApp
```

Or from Xcode with **⌘U**.

### Linting and formatting (manual)

SwiftLint and SwiftFormat run automatically on every Xcode build. To run them manually:

```bash
# Format all source files
swiftformat --config .swiftformat Sources/

# Lint (report only, no auto-fix)
swiftlint lint --config .swiftlint.yml

# Lint with auto-correct for safe fixes
swiftlint --fix --config .swiftlint.yml
```

### Cleaning the generated project

```bash
tuist clean
```

---

## 9. Adding External Packages

1. Open `Project.swift` and add the package to the `packages` array:

```swift
packages: [
    .remote(
        url: "https://github.com/onevcat/Kingfisher",
        requirement: .upToNextMajor(from: "7.0.0")
    ),
],
```

2. Add the dependency to the target that needs it:

```swift
dependencies: [
    .external(name: "Kingfisher"),
],
```

3. Fetch and regenerate:

```bash
tuist install
tuist generate
```

---

## 10. CI/CD — GitHub Actions

Workflow files live in `.github/workflows/`. Two pipelines are included:

| File | Trigger | Steps |
|---|---|---|
| `pr.yml` | Every PR to `main` / `develop` | Lint → Build → Test |
| `release.yml` | Merge to `main` | Lint → Build → Test → Archive → Export IPA → Upload to TestFlight |

### Required GitHub Secrets

Add these in **Settings → Secrets and variables → Actions**:

| Secret | Description |
|---|---|
| `APPLE_ID` | Apple ID email used for TestFlight upload |
| `APP_SPECIFIC_PASSWORD` | App-specific password from appleid.apple.com |
| `MATCH_PASSWORD` | Fastlane Match passphrase (if using Match for code signing) |
| `TUIST_CONFIG_TOKEN` | Tuist Cloud token (if using Tuist Cloud) |

---

## 11. Architecture Reference

This template enforces **MVVM + Atomic Design** with **Swift 6 strict concurrency**. The full architecture specification — including layer rules, naming conventions, error handling, dependency injection, and what Claude must never do — is documented in [`CLAUDE.md`](./CLAUDE.md).

### Quick Reference

| Layer | Rule |
|---|---|
| View | Zero logic. Reads state from ViewModel only. |
| ViewModel | `@MainActor @Observable`. No SwiftUI imports. |
| UseCase | Single responsibility. Returns `Result<T, AppError>`. |
| Repository | Protocol only. Concrete impl lives in `Data/`. |
| DataSource | Direct URLSession / SwiftData / Keychain calls. |

### Atomic Design Layers

| Layer | Contains | ViewModel access |
|---|---|---|
| Atom | Buttons, labels, icons | ✗ |
| Molecule | Composed atoms (form rows, cells) | ✗ |
| Organism | Composed molecules (cards, headers) | ✗ |
| Template | Layout shell via `@ViewBuilder` | ✗ |
| Page | Feature screen wired to real data | ✓ |

---

## License

MIT — use freely, attribution appreciated.
