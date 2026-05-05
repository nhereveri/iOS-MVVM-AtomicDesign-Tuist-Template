# CLAUDE.md — iOS Project Guidelines

This file defines the architecture, conventions, and workflow rules for this project.
Claude must read and follow all sections before generating, editing, or reviewing any code.

---

## 1. Project Overview

- **Platform**: iOS 18+ (iPhone-first, SwiftUI-native)
- **App type**: B2C consumer application
- **Build system**: Tuist (monolithic single-target project)
- **UI framework**: SwiftUI — no UIKit unless strictly required by a third-party SDK
- **Concurrency**: Swift 6 strict concurrency mode enabled on all targets
- **Language**: Swift 6

---

## 2. Architecture

### 2.1 Pattern: MVVM

Every feature follows a strict MVVM layering:

```
View  →  ViewModel  →  UseCase  →  Repository  →  DataSource
```

- **View**: Pure SwiftUI. No business logic. Reads state from ViewModel via `@State`, `@Environment`, or direct property access.
- **ViewModel**: Annotated with `@Observable`. Owns the feature's UI state. Calls UseCases. Never imports UIKit.
- **UseCase**: A single-responsibility struct/class that encapsulates one business action. Returns `Result<T, AppError>`.
- **Repository**: Protocol-based. Abstracts the data source (network, cache, local DB). Implemented as a concrete type injected via the Environment.
- **DataSource**: Lowest layer. Direct URLSession calls, SwiftData context access, or Keychain wrappers.

### 2.2 Atomic Design (UI layer)

The UI is organized following Atomic Design principles. All components live under `Sources/DesignSystem/`:

```
DesignSystem/
├── Atoms/          # Indivisible UI units: buttons, labels, icons, text fields, dividers
├── Molecules/      # Composed of atoms: form rows, list cells, input groups
├── Organisms/      # Composed of molecules: headers, cards, sections, navigation bars
├── Templates/      # Page scaffolding with placeholder content: layout shells
└── Pages/          # Feature screens: instantiated templates with real ViewModels
```

**Rules:**
- Atoms must have zero business logic and zero ViewModel dependencies.
- Molecules may hold local `@State` for UI interaction only (e.g., focus state).
- Organisms may receive closures or bindings but must not hold a ViewModel.
- Templates define layout only — they receive content via ViewBuilder closures.
- Pages (feature screens) are the only components allowed to access the ViewModel and the SwiftUI Environment.

### 2.3 Navigation: NavigationStack + Coordinator

- Each feature declares a `Route` enum conforming to `Hashable`.
- A `Coordinator` (`@Observable` class) owns the `NavigationPath` and exposes `push(_:)`, `pop()`, `popToRoot()`, and `replace(_:)` methods.
- The `Coordinator` is injected via SwiftUI `Environment`.
- Deep links are resolved in the root `AppCoordinator` and forwarded to the relevant feature coordinator.

```swift
// Example Route
enum AuthRoute: Hashable {
    case login
    case register
    case forgotPassword(email: String)
}

// Example Coordinator
@Observable
final class AuthCoordinator {
    var path = NavigationPath()

    func push(_ route: AuthRoute) { path.append(route) }
    func pop() { path.removeLast() }
    func popToRoot() { path.removeLast(path.count) }
}
```

---

## 3. Project Structure (Tuist Monolithic)

```
ProjectName/
├── Project.swift                  # Tuist project manifest
├── Tuist/
│   ├── Config.swift
│   └── Dependencies.swift         # SPM dependencies declared here
├── Sources/
│   ├── App/
│   │   ├── ProjectNameApp.swift   # @main entry point
│   │   ├── AppCoordinator.swift   # Root coordinator
│   │   └── DependencyContainer.swift
│   ├── Features/
│   │   ├── Auth/
│   │   │   ├── AuthCoordinator.swift
│   │   │   ├── Login/
│   │   │   │   ├── LoginView.swift
│   │   │   │   ├── LoginViewModel.swift
│   │   │   │   └── LoginUseCase.swift
│   │   │   └── Register/
│   │   │       ├── RegisterView.swift
│   │   │       ├── RegisterViewModel.swift
│   │   │       └── RegisterUseCase.swift
│   │   └── [FeatureName]/
│   │       └── ...
│   ├── Domain/
│   │   ├── Entities/              # Pure Swift models (Sendable, Codable)
│   │   ├── Repositories/          # Repository protocols
│   │   └── UseCases/              # Shared use cases (if any)
│   ├── Data/
│   │   ├── Network/
│   │   │   ├── APIClient.swift    # URLSession wrapper
│   │   │   ├── Endpoint.swift     # Endpoint builder protocol
│   │   │   └── Repositories/     # Concrete repository implementations
│   │   └── Persistence/           # SwiftData or Keychain wrappers
│   ├── DesignSystem/
│   │   ├── Atoms/
│   │   ├── Molecules/
│   │   ├── Organisms/
│   │   ├── Templates/
│   │   └── Extensions/            # Color+, Font+, ViewModifier extensions
│   └── Core/
│       ├── Extensions/            # Swift stdlib extensions
│       ├── Utilities/             # Generic helpers (DateFormatter, etc.)
│       └── Coordinators/          # Base coordinator types
├── Tests/
│   └── [FeatureName]Tests/
│       ├── ViewModelTests/
│       ├── UseCaseTests/
│       └── RepositoryTests/
└── Resources/
    ├── Assets.xcassets
    ├── Localizable.xcstrings      # String catalogs
    └── Fonts/
```

---

## 4. Naming Conventions

### Types and Files

| Layer | Suffix | Example |
|---|---|---|
| View | `View` | `LoginView.swift` |
| ViewModel | `ViewModel` | `LoginViewModel.swift` |
| UseCase | `UseCase` | `LoginUseCase.swift` |
| Repository (protocol) | `Repository` | `AuthRepository.swift` |
| Repository (impl) | `Repository` | `DefaultAuthRepository.swift` |
| DataSource | `DataSource` | `AuthRemoteDataSource.swift` |
| Coordinator | `Coordinator` | `AuthCoordinator.swift` |
| Route enum | `Route` | `AuthRoute.swift` |
| Entity / Model | (no suffix) | `User.swift`, `Product.swift` |
| Error type | `Error` | `NetworkError.swift`, `AuthError.swift` |
| Extension | `+TypeName` | `Color+Brand.swift`, `Font+App.swift` |
| ViewModifier | `Modifier` | `CardModifier.swift` |

### General Rules

- Use `UpperCamelCase` for types, `lowerCamelCase` for properties and functions.
- Protocols use descriptive nouns or adjectives: `AuthRepository`, `Loadable`, `Refreshable`.
- `async` functions do not need an `async` suffix; the call site makes it obvious.
- Boolean properties are prefixed with `is`, `has`, `can`, or `should`: `isLoading`, `hasError`.
- Avoid abbreviations except for universally accepted ones (`URL`, `ID`, `UI`).

---

## 5. State Management

### ViewModel State with @Observable

Every ViewModel is an `@Observable final class`. Never use `ObservableObject` or `@Published`.

```swift
@Observable
final class LoginViewModel {
    // MARK: - Output (UI State)
    var email: String = ""
    var password: String = ""
    var isLoading: Bool = false
    var alertMessage: String?

    // MARK: - Dependencies
    private let loginUseCase: LoginUseCase

    init(loginUseCase: LoginUseCase) {
        self.loginUseCase = loginUseCase
    }

    // MARK: - Input
    func loginTapped() async {
        isLoading = true
        defer { isLoading = false }
        let result = await loginUseCase.execute(email: email, password: password)
        switch result {
        case .success:
            break // coordinator handles navigation
        case .failure(let error):
            alertMessage = error.localizedMessage
        }
    }
}
```

### Global State via Environment

Shared state (authenticated user session, theme, locale) is passed via SwiftUI `Environment`:

```swift
// Declaration
extension EnvironmentValues {
    @Entry var userSession: UserSession = .unauthenticated
}

// Injection
ContentView()
    .environment(\.userSession, session)

// Consumption (in a Page only)
@Environment(\.userSession) private var session
```

---

## 6. Networking

### APIClient

All network calls go through a single `APIClient` using `URLSession` and `async/await`. It returns `Result<T, NetworkError>`.

```swift
struct APIClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func request<T: Decodable>(_ endpoint: some Endpoint) async -> Result<T, NetworkError> {
        do {
            let request = try endpoint.urlRequest()
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                return .failure(.invalidResponse)
            }
            guard (200..<300).contains(http.statusCode) else {
                return .failure(.httpError(statusCode: http.statusCode, data: data))
            }
            let decoded = try JSONDecoder.app.decode(T.self, from: data)
            return .success(decoded)
        } catch let error as NetworkError {
            return .failure(error)
        } catch {
            return .failure(.underlying(error))
        }
    }
}
```

### Endpoint Protocol

```swift
protocol Endpoint {
    var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String] { get }
    var body: Encodable? { get }

    func urlRequest() throws -> URLRequest
}
```

### Rules

- Never call `URLSession` directly from a ViewModel or UseCase.
- All `Codable` models use `snake_case` decoding via a shared `JSONDecoder.app` with `keyDecodingStrategy = .convertFromSnakeCase`.
- API responses are **never** returned directly to the ViewModel. Repositories map them to domain entities.
- Network errors are mapped to `AppError` at the repository boundary.

---

## 7. Error Handling

Use `Result<Success, Failure>` throughout the data and domain layers. Map all errors to a domain-level `AppError` before they reach the ViewModel.

```swift
enum AppError: Error, LocalizedError {
    case network(NetworkError)
    case unauthorized
    case notFound
    case validation(String)
    case unknown

    var localizedMessage: String {
        switch self {
        case .network: return String(localized: "error.network")
        case .unauthorized: return String(localized: "error.unauthorized")
        case .notFound: return String(localized: "error.not_found")
        case .validation(let msg): return msg
        case .unknown: return String(localized: "error.unknown")
        }
    }
}
```

**Rules:**
- Do not use `throw` / `try` across layer boundaries — use `Result` instead so error propagation is explicit and type-safe.
- Only ViewModels and the top-level error boundary may catch `AppError` and translate it to UI state.
- Never `fatalError` in production paths. Use `assertionFailure` for developer mistakes in debug builds.

---

## 8. Dependency Injection

Dependencies are injected via:
1. **Initializer injection** — preferred for UseCases and Repositories.
2. **SwiftUI Environment** — preferred for cross-cutting concerns (session, coordinators, feature flags).

```swift
// Repository protocol
protocol AuthRepository: Sendable {
    func login(email: String, password: String) async -> Result<User, AppError>
}

// Environment key
extension EnvironmentValues {
    @Entry var authRepository: any AuthRepository = DefaultAuthRepository()
}

// UseCase consuming the protocol
struct LoginUseCase {
    let repository: any AuthRepository

    func execute(email: String, password: String) async -> Result<User, AppError> {
        await repository.login(email: email, password: password)
    }
}

// ViewModel receiving the use case
@Observable
final class LoginViewModel {
    private let loginUseCase: LoginUseCase
    init(loginUseCase: LoginUseCase) { self.loginUseCase = loginUseCase }
}

// Page wiring it up
struct LoginPage: View {
    @Environment(\.authRepository) private var authRepository
    @State private var viewModel: LoginViewModel?

    var body: some View {
        Group {
            if let vm = viewModel {
                LoginView(viewModel: vm)
            }
        }
        .onAppear {
            viewModel = LoginViewModel(loginUseCase: LoginUseCase(repository: authRepository))
        }
    }
}
```

---

## 9. Design System

The design system uses **SwiftUI extensions** — no external dependencies.

### Colors (`Color+Brand.swift`)

```swift
extension Color {
    // Brand
    static let brandPrimary = Color("BrandPrimary", bundle: .main)
    static let brandSecondary = Color("BrandSecondary", bundle: .main)

    // Semantic
    static let textPrimary = Color("TextPrimary", bundle: .main)
    static let textSecondary = Color("TextSecondary", bundle: .main)
    static let backgroundPrimary = Color("BackgroundPrimary", bundle: .main)
    static let backgroundSecondary = Color("BackgroundSecondary", bundle: .main)
    static let destructive = Color("Destructive", bundle: .main)
    static let success = Color("Success", bundle: .main)
}
```

All colors must be defined in `Assets.xcassets` with light/dark variants. Never use hardcoded hex values.

### Typography (`Font+App.swift`)

```swift
extension Font {
    static let displayLarge: Font = .system(size: 34, weight: .bold, design: .default)
    static let displayMedium: Font = .system(size: 28, weight: .semibold)
    static let headlineLarge: Font = .system(size: 22, weight: .semibold)
    static let bodyLarge: Font = .system(size: 17, weight: .regular)
    static let bodyMedium: Font = .system(size: 15, weight: .regular)
    static let caption: Font = .system(size: 12, weight: .regular)
    static let labelSmall: Font = .system(size: 11, weight: .medium)
}
```

### Spacing (`CGFloat+Spacing.swift`)

```swift
extension CGFloat {
    static let spacing2: CGFloat = 2
    static let spacing4: CGFloat = 4
    static let spacing8: CGFloat = 8
    static let spacing12: CGFloat = 12
    static let spacing16: CGFloat = 16
    static let spacing24: CGFloat = 24
    static let spacing32: CGFloat = 32
    static let spacing48: CGFloat = 48
    static let spacing64: CGFloat = 64
}
```

### ViewModifiers

Reusable modifiers live in `DesignSystem/Extensions/`. Apply them with `.modifier(CardModifier())` or a dedicated view extension.

---

## 10. Localization

- All user-facing strings use **String Catalogs** (`.xcstrings`), never hardcoded literals.
- String key format: `feature.component.description` (all lowercase, dot-separated).
  - Examples: `"login.button.submit"`, `"error.network"`, `"profile.label.email"`
- Use `String(localized:)` in Swift code:

```swift
Text(String(localized: "login.button.submit"))
// or directly in Text views:
Text("login.button.submit")
```

- Base language is defined in `Project.swift` via Tuist's `defaultKnownRegions`.
- Pluralization rules must be defined in the string catalog, not in Swift code.
- All dates, numbers, and currency values must use `FormatStyle` or `Formatter` — never manual string concatenation.

---

## 11. Swift Concurrency

Swift 6 strict concurrency is **enabled on all targets**. All code must compile without warnings under `SWIFT_STRICT_CONCURRENCY = complete`.

### Rules

- All `@Observable` classes that are accessed from the main thread must be annotated `@MainActor`.
- ViewModels are always `@MainActor`:

```swift
@MainActor
@Observable
final class LoginViewModel { ... }
```

- Repositories and UseCases must conform to `Sendable`.
- Use `async/await` exclusively — no callbacks, no `DispatchQueue.main.async`.
- Use structured concurrency (`async let`, `TaskGroup`) for parallel operations.
- Never use `@unchecked Sendable` without a detailed comment explaining why it's safe.
- All entities and value types must be `Sendable` (structs are implicitly `Sendable` when all properties are).

---

## 12. Code Quality

### SwiftLint

Configuration file: `.swiftlint.yml` at the project root. Enforced rules include:

- `force_unwrapping` — **error**: no `!` unwrapping in production code.
- `force_cast` — **error**: no `as!` in production code.
- `implicitly_unwrapped_optional` — **warning**: only permitted in `@IBOutlet` (none expected) or explicit test setup.
- `line_length` — **warning** at 120, **error** at 160.
- `file_length` — **warning** at 400 lines.
- `type_body_length` — **warning** at 200 lines. Split types that exceed this.
- `function_body_length` — **warning** at 40 lines.
- `cyclomatic_complexity` — **warning** at 10.
- `trailing_whitespace`, `vertical_whitespace` — **error**.

### SwiftFormat

Configuration file: `.swiftformat` at the project root. Key rules:

- `--indent 4` — 4-space indentation (no tabs).
- `--wraparguments before-first` — wrap function arguments.
- `--importgrouping testable-last` — group imports: stdlib → third-party → `@testable`.
- `--stripunusedargs closure-only` — remove unused closure args.
- `--semicolons never` — no semicolons.

SwiftFormat runs automatically as a **build phase** in Tuist and as a **pre-commit hook**.

### MARK Comments

Every type must use `// MARK: -` sections to organize code:

```swift
// MARK: - Properties
// MARK: - Lifecycle
// MARK: - Public Interface
// MARK: - Private Helpers
// MARK: - Actions / Intent handlers
```

---

## 13. Testing

All business logic must have unit test coverage. UI tests are not required in the current phase.

### Test File Naming

`{TypeUnderTest}Tests.swift` — e.g., `LoginViewModelTests.swift`, `LoginUseCaseTests.swift`.

### Structure (Given / When / Then)

```swift
final class LoginUseCaseTests: XCTestCase {

    // MARK: - Properties
    private var sut: LoginUseCase!
    private var mockRepository: MockAuthRepository!

    // MARK: - Lifecycle
    override func setUp() {
        super.setUp()
        mockRepository = MockAuthRepository()
        sut = LoginUseCase(repository: mockRepository)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    // MARK: - Tests
    func test_execute_withValidCredentials_returnsUser() async {
        // Given
        mockRepository.loginResult = .success(User.mock)

        // When
        let result = await sut.execute(email: "test@example.com", password: "password")

        // Then
        switch result {
        case .success(let user):
            XCTAssertEqual(user.email, "test@example.com")
        case .failure:
            XCTFail("Expected success, got failure")
        }
    }
}
```

### Mocks

- All repository protocols have a `Mock` implementation in the test target.
- Mock naming: `Mock{ProtocolName}` — e.g., `MockAuthRepository`.
- Mocks expose a `{methodName}Result: Result<T, AppError>` property for controlling behavior.
- Never use third-party mocking frameworks.

### Coverage Targets

| Layer | Minimum Coverage |
|---|---|
| UseCase | 90% |
| ViewModel | 80% |
| Repository (concrete) | 70% |
| View | Not required |

---

## 14. CI/CD (GitHub Actions)

Workflows live in `.github/workflows/`.

### Pull Request Workflow (`pr.yml`)

Triggers on every PR to `main` and `develop`:

1. **Lint** — runs `swiftlint` and `swiftformat --lint`. Fails on any violation.
2. **Build** — `tuist generate` + `xcodebuild build` for the main scheme.
3. **Test** — `xcodebuild test` on iPhone Simulator (latest iOS).

### Merge to Main Workflow (`release.yml`)

Triggers on merge to `main`:

1. All steps from PR workflow.
2. **Archive** — creates an `.xcarchive`.
3. **Export IPA** — exports using the distribution provisioning profile.
4. **Upload to TestFlight** — via `altool` or `xcrun notarytool`.

### Secrets

Stored as GitHub Actions encrypted secrets:
- `APPLE_ID`, `APP_SPECIFIC_PASSWORD` — for TestFlight upload.
- `MATCH_PASSWORD` — for Fastlane Match (if used for code signing).
- `TUIST_CONFIG_TOKEN` — Tuist Cloud token (if applicable).

---

## 15. Git Conventions

### Branch Naming

```
feature/{ticket-id}-short-description     # New features
fix/{ticket-id}-short-description         # Bug fixes
refactor/{ticket-id}-short-description    # Refactoring
chore/{ticket-id}-short-description       # Tooling, deps, config
release/v{major}.{minor}.{patch}          # Release branches
```

### Commit Messages (Conventional Commits)

```
feat(auth): add biometric login support
fix(profile): resolve crash when avatar is nil
refactor(network): extract endpoint builder to protocol
chore(deps): update SwiftLint to 0.56.0
test(login): add tests for invalid credential handling
docs(readme): update setup instructions
```

### Pull Request Rules

- PRs must reference a ticket/issue number.
- Minimum 1 review approval required before merge.
- All CI checks must pass.
- Squash merge into `main`; rebase merge into `develop`.
- PR description must include: **What**, **Why**, and **How to test**.

---

## 16. What Claude Must Always Do

- **Read this file first** before generating or modifying any Swift code.
- **Follow MVVM strictly** — Views have zero logic; ViewModels have zero SwiftUI imports.
- **Use Atomic Design** — create/place components in the correct layer.
- **Use `Result<T, AppError>`** — never `throw` across layer boundaries.
- **Apply `@MainActor`** to all `@Observable` ViewModels.
- **Write Sendable-safe code** — all code must compile under Swift 6 strict concurrency.
- **Use String Catalogs** — never hardcode user-facing strings.
- **Follow naming conventions** — suffix every type with its layer role.
- **Include MARK sections** in every type with more than 3 properties or methods.
- **Write tests** for every new UseCase and ViewModel.

## 17. What Claude Must Never Do

- Create UIKit views, `UIViewController` subclasses, or `AppDelegate` logic (unless bridging to a third-party SDK).
- Use `@Published` or `ObservableObject` — use `@Observable` instead.
- Use `DispatchQueue` — use `async/await` and structured concurrency.
- Force-unwrap (`!`) or force-cast (`as!`) in non-test code.
- Hardcode colors, fonts, or spacing values — use the design system extensions.
- Hardcode user-facing strings — use String Catalogs.
- Add business logic to a View, Atom, Molecule, Organism, or Template.
- Return raw network/data models directly to ViewModels — always map to domain entities first.
- Create files longer than 400 lines — split responsibilities.
- Skip `// MARK: -` sections in types with more than 3 members.
