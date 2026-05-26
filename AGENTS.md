# iOS Project Guidelines

This file is the single source of truth for architecture, conventions, and workflow rules.
Any AI agent, IDE plugin, or contributor must read and follow all sections before generating,
editing, or reviewing any code in this project.

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

## 3. SOLID Principles

Every class, struct, protocol, and function generated in this project must comply with the five SOLID principles. Violations are treated as architecture defects, not style issues.

### S — Single Responsibility

Each type does exactly one thing. If you need to describe a type with "and", it must be split.

```swift
// Wrong — fetches AND maps AND caches
final class UserManager { ... }

// Correct — one responsibility each
struct FetchUserUseCase { ... }
struct UserMapper { ... }
struct UserCache { ... }
```

### O — Open / Closed

Types are open for extension but closed for modification. Add behaviour through protocols, extensions, and composition — not by editing existing types.

```swift
// Wrong — adding a payment method requires editing this type
struct PaymentProcessor {
    func process(_ method: String) { ... }
}

// Correct — new methods conform to the protocol; processor never changes
protocol PaymentMethod {
    func process() async -> Result<Void, AppError>
}
struct CreditCardPayment: PaymentMethod { ... }
struct ApplePayPayment:   PaymentMethod { ... }
```

### L — Liskov Substitution

Subtypes and protocol conformances must be fully substitutable for their abstractions. A concrete repository must honour every contract defined by its protocol — no partial implementations, no `fatalError` stubs.

```swift
// Wrong — breaks the contract by throwing when the protocol promises Result
final class BrokenUserRepository: UserRepository {
    func fetchUser(id: String) async -> Result<User, AppError> {
        fatalError("not implemented") // violates LSP
    }
}

// Correct — always returns a valid Result
final class DefaultUserRepository: UserRepository {
    func fetchUser(id: String) async -> Result<User, AppError> {
        await dataSource.fetch(id: id).mapError(AppError.network)
    }
}
```

### I — Interface Segregation

Protocols are narrow and focused. Clients must not depend on methods they don't use. Split large protocols into targeted ones.

```swift
// Wrong — forces every conformer to implement both capabilities
protocol UserRepository {
    func fetchUser(id: String) async -> Result<User, AppError>
    func updateAvatar(_ image: Data, for id: String) async -> Result<Void, AppError>
    func deleteAccount(id: String) async -> Result<Void, AppError>
}

// Correct — separate concerns; compose at the use-case level
protocol UserReadRepository: Sendable {
    func fetchUser(id: String) async -> Result<User, AppError>
}
protocol UserWriteRepository: Sendable {
    func updateAvatar(_ image: Data, for id: String) async -> Result<Void, AppError>
    func deleteAccount(id: String) async -> Result<Void, AppError>
}
```

### D — Dependency Inversion

High-level modules (ViewModels, UseCases) depend on abstractions (protocols), never on concrete implementations. All concrete types are injected from outside via initialiser or SwiftUI Environment.

```swift
// Wrong — ViewModel creates its own concrete dependency
@Observable final class ProfileViewModel {
    private let repository = DefaultProfileRepository() // hard dependency
}

// Correct — depends on the protocol; concrete type injected by the caller
@MainActor
@Observable
final class ProfileViewModel {
    private let repository: any ProfileRepository
    init(repository: some ProfileRepository) {
        self.repository = repository
    }
}
```

---

## 4. Documentation (DocC)

All public and internal **types** (classes, structs, enums, actors) and their **non-trivial methods** must be documented with DocC-style triple-slash comments (`///`).

### What to document

| Symbol | Document? |
|---|---|
| `class`, `struct`, `enum`, `actor` | ✅ Always |
| `protocol` | ✅ Always |
| `func` / `async func` (public or internal) | ✅ Always |
| `init` with parameters | ✅ Always |
| `var` / `let` stored properties | ❌ Never — use clear naming instead |
| Private helpers obvious from name | ❌ Omit — do not add noise |

### Format

Use Swift Markdown inside `///` comments. Include `- Parameters:`, `- Returns:`, and `- Throws:` only when they add information beyond the signature. Always include a `## Example` block for non-trivial public APIs.

```swift
// Wrong — documents a stored property (adds noise, not value)
/// The user's email address.
var email: String = ""

// Wrong — Xcode-generated file header (remove these entirely)
//
//  LoginView.swift
//  MyApp
//
//  Created by Nelson on 01/01/26.
//

// Correct — documents a struct with an example
/// Encapsulates the logic for authenticating a user with email and password.
///
/// `LoginUseCase` sits between the ViewModel and the repository layer.
/// It validates inputs before delegating to the repository and maps
/// any network error to a domain-level ``AppError``.
///
/// ## Example
///
/// ```swift
/// let useCase = LoginUseCase(repository: authRepository)
/// let result  = await useCase.execute(email: "user@example.com", password: "secret")
/// ```
struct LoginUseCase {

    private let repository: any AuthRepository

    init(repository: some AuthRepository) {
        self.repository = repository
    }

    /// Authenticates the user and returns the authenticated ``User`` on success.
    ///
    /// Validation is performed before the network call. If either field is empty
    /// the method returns `.failure(.validation(...))` without hitting the network.
    ///
    /// - Parameters:
    ///   - email: The user's email address. Must be non-empty.
    ///   - password: The user's plaintext password. Must be non-empty.
    /// - Returns: `.success(User)` on successful authentication,
    ///   or `.failure(AppError)` for validation or network errors.
    func execute(email: String, password: String) async -> Result<User, AppError> {
        guard !email.isEmpty, !password.isEmpty else {
            return .failure(.validation(String(localized: "error.validation.empty_credentials")))
        }
        return await repository.login(email: email, password: password)
    }
}
```

### File headers

**Remove all Xcode-generated file header comments.** Files must start directly with `import` statements or the first type declaration. The repository history, git blame, and Xcode's file inspector provide all the authorship and date information needed.

```swift
// Wrong — Xcode template header, must be deleted
//
//  LoginViewModel.swift
//  MyApp
//
//  Created by Nelson on 01/01/26.
//

import SwiftUI

// Correct — file starts immediately with imports
import SwiftUI
```

---

## 5. Project Structure (Tuist Monolithic)

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

## 6. Naming Conventions

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

## 7. State Management

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

## 8. Networking

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

## 9. Error Handling

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

## 10. Dependency Injection

Dependencies are injected via:
1. **Initializer injection** — preferred for UseCases and Repositories.
2. **SwiftUI Environment** — preferred for cross-cutting concerns (session, coordinators, feature flags).

The pattern for both mechanisms is identical: define a **protocol** in `Domain/`, create a **concrete implementation** in `Data/`, register an **Environment key** in `Core/`, wire it in `DependencyContainer`, and consume it in a **Page**.

---

### 10.1 Initializer Injection

Use initializer injection for UseCases and any type with a single dependency resolved at construction time.

```swift
// Protocol — Domain/Repositories/AuthRepository.swift
protocol AuthRepository: Sendable {
    func login(email: String, password: String) async -> Result<User, AppError>
}

// UseCase receives the protocol via init
struct LoginUseCase {
    private let repository: any AuthRepository

    init(repository: some AuthRepository) {
        self.repository = repository
    }

    func execute(email: String, password: String) async -> Result<User, AppError> {
        await repository.login(email: email, password: password)
    }
}

// ViewModel receives the UseCase via init
@MainActor
@Observable
final class LoginViewModel {
    private let loginUseCase: LoginUseCase

    init(loginUseCase: LoginUseCase) {
        self.loginUseCase = loginUseCase
    }
}
```

---

### 10.2 SwiftUI Environment Injection

Use Environment injection for cross-cutting services. Every service must be exposed through a protocol — **never** put a concrete type as an Environment value.

```swift
// Environment key — Core/Extensions/EnvironmentValues+Repositories.swift
extension EnvironmentValues {
    @Entry var authRepository: any AuthRepository = DefaultAuthRepository()
}

// Page wires the ViewModel at appear time
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
            viewModel = LoginViewModel(
                loginUseCase: LoginUseCase(repository: authRepository)
            )
        }
    }
}
```

---

### 10.3 Adding a new injectable service — end-to-end

Follow these six steps every time a new cross-cutting service (feature flags, analytics, remote config, A/B testing, push notifications) is introduced. The example below uses a `FeatureFlagRepository` backed by either **Firebase Remote Config** or **LaunchDarkly**.

**Required file locations:**

```
Sources/
├── Domain/
│   └── FeatureFlags/
│       ├── FeatureFlagKey.swift               ← Step 1 — key enum
│       └── FeatureFlagRepository.swift        ← Step 2 — protocol
├── Data/
│   └── Repositories/
│       ├── FirebaseFeatureFlagRepository.swift    ← Step 3a
│       └── LaunchDarklyFeatureFlagRepository.swift ← Step 3b
└── Core/
    └── Extensions/
        └── EnvironmentValues+Repositories.swift  ← Step 4
Sources/App/
    └── DependencyContainer.swift              ← Step 5
Tests/
    └── Mocks/
        └── MockFeatureFlagRepository.swift    ← Step 6
```

#### Step 1 — Key enum (`Domain/FeatureFlags/FeatureFlagKey.swift`)

Keys are domain concepts. They are independent of the provider. The `rawValue` must match the key string configured in the remote dashboard exactly.

```swift
/// Identifies a remotely configurable feature flag or A/B variant.
///
/// Add a case here whenever a new flag is introduced in the remote config
/// dashboard. The `rawValue` must match the key string in Firebase Remote
/// Config or LaunchDarkly exactly.
enum FeatureFlagKey: String, Sendable {
    case newOnboardingFlow = "new_onboarding_flow"
    case maxUploadSizeMB   = "max_upload_size_mb"
    case premiumPaywallV2  = "premium_paywall_v2"
}
```

#### Step 2 — Protocol (`Domain/FeatureFlags/FeatureFlagRepository.swift`)

The protocol is narrow (ISP), `Sendable`, and contains no reference to any provider type.

```swift
/// Provides access to remotely controlled feature flags and configuration values.
///
/// Concrete implementations (`FirebaseFeatureFlagRepository`,
/// `LaunchDarklyFeatureFlagRepository`) are swappable without touching any
/// UseCase or ViewModel.
///
/// ## Example
///
/// ```swift
/// let isEnabled = await featureFlagRepository.bool(for: .newOnboardingFlow)
/// ```
protocol FeatureFlagRepository: Sendable {

    /// Returns the Boolean value for the given flag, or `false` if the key is absent.
    func bool(for key: FeatureFlagKey) async -> Bool

    /// Returns the String value for the given flag, or `nil` if the key is absent or empty.
    func string(for key: FeatureFlagKey) async -> String?

    /// Returns the Int value for the given flag, or `nil` if the key is absent or not parseable.
    func int(for key: FeatureFlagKey) async -> Int?
}
```

#### Step 3a — Firebase Remote Config (`Data/Repositories/FirebaseFeatureFlagRepository.swift`)

```swift
import FirebaseRemoteConfig

/// Reads feature flags from Firebase Remote Config.
///
/// Call `fetchAndActivate()` once at app launch (in `DependencyContainer`)
/// before the root view appears. Subsequent `bool/string/int` calls read the
/// in-memory activated config synchronously.
///
/// - Note: `@unchecked Sendable` is safe here because `RemoteConfig` is a
///   Firebase-managed singleton that serialises its own internal state.
///   All reads performed by this type are stateless after `fetchAndActivate`.
final class FirebaseFeatureFlagRepository: FeatureFlagRepository, @unchecked Sendable {

    // MARK: - Properties

    private let remoteConfig: RemoteConfig

    // MARK: - Lifecycle

    /// Creates a repository backed by the given `RemoteConfig` instance.
    ///
    /// - Parameter remoteConfig: Defaults to `RemoteConfig.remoteConfig()`.
    ///   Provide a custom instance in unit tests.
    init(remoteConfig: RemoteConfig = .remoteConfig()) {
        self.remoteConfig = remoteConfig
    }

    // MARK: - Public Interface

    /// Fetches the latest remote values and activates them in one call.
    ///
    /// Errors are intentionally swallowed: the app always starts with either
    /// the freshly activated values or the defaults bundled in
    /// `GoogleService-Info.plist`.
    func fetchAndActivate() async {
        _ = try? await remoteConfig.fetchAndActivate()
    }

    func bool(for key: FeatureFlagKey) async -> Bool {
        remoteConfig.configValue(forKey: key.rawValue).boolValue
    }

    func string(for key: FeatureFlagKey) async -> String? {
        let value = remoteConfig.configValue(forKey: key.rawValue).stringValue
        return value.isEmpty ? nil : value
    }

    func int(for key: FeatureFlagKey) async -> Int? {
        let value = remoteConfig.configValue(forKey: key.rawValue)
        guard value.source != .static else { return nil }
        return Int(truncating: value.numberValue)
    }
}
```

#### Step 3b — LaunchDarkly (`Data/Repositories/LaunchDarklyFeatureFlagRepository.swift`)

```swift
import LaunchDarkly

/// Reads feature flags from LaunchDarkly using the iOS SDK.
///
/// The LaunchDarkly SDK streams flag updates in the background once
/// `LDClient.start(config:context:)` is called at launch. No explicit
/// refresh call is needed after that.
///
/// - Note: `@unchecked Sendable` is safe here because `LDClient` is a
///   thread-safe singleton managed by the LaunchDarkly SDK.
final class LaunchDarklyFeatureFlagRepository: FeatureFlagRepository, @unchecked Sendable {

    // MARK: - Properties

    private let client: LDClient

    // MARK: - Lifecycle

    /// Creates a repository backed by the given `LDClient`.
    ///
    /// - Parameter client: The client must already be started via
    ///   `LDClient.start(config:context:)` before this repository is used.
    init(client: LDClient = .get()!) {
        self.client = client
    }

    // MARK: - Public Interface

    func bool(for key: FeatureFlagKey) async -> Bool {
        client.boolVariation(forKey: key.rawValue, defaultValue: false)
    }

    func string(for key: FeatureFlagKey) async -> String? {
        client.stringVariation(forKey: key.rawValue, defaultValue: nil)
    }

    func int(for key: FeatureFlagKey) async -> Int? {
        client.intVariation(forKey: key.rawValue, defaultValue: nil)
    }
}
```

#### Step 4 — Environment key (`Core/Extensions/EnvironmentValues+Repositories.swift`)

All repository Environment keys live in a single file. Add a new `@Entry` here for every new service.

```swift
extension EnvironmentValues {
    @Entry var authRepository: any AuthRepository = DefaultAuthRepository()

    // Swap the default to LaunchDarklyFeatureFlagRepository() if using LaunchDarkly.
    @Entry var featureFlagRepository: any FeatureFlagRepository = FirebaseFeatureFlagRepository()
}
```

#### Step 5 — Wire in DependencyContainer (`App/DependencyContainer.swift`)

`DependencyContainer` is the **only** place where concrete SDK types are created and third-party SDKs are initialised. Everything downstream only sees protocols.

```swift
/// Assembles all concrete dependencies and pushes them into the SwiftUI Environment.
///
/// All third-party SDK bootstrap calls (`FirebaseApp.configure()`,
/// `LDClient.start(...)`) happen here so the rest of the codebase stays
/// provider-agnostic.
struct DependencyContainer: View {

    // MARK: - Properties

    private let featureFlagRepository: any FeatureFlagRepository
    private let authRepository: any AuthRepository

    // MARK: - Lifecycle

    init() {
        // ── Firebase ────────────────────────────────────────────────────────
        // FirebaseApp.configure()
        let firebaseFF = FirebaseFeatureFlagRepository()
        featureFlagRepository = firebaseFF

        // ── LaunchDarkly (alternative) ──────────────────────────────────────
        // Comment out the Firebase lines above and uncomment these to switch.
        // let config  = LDConfig(mobileKey: "mob-YOUR_KEY")
        // let context = try! LDContextBuilder(key: "anonymous").build()
        // LDClient.start(config: config, context: context)
        // featureFlagRepository = LaunchDarklyFeatureFlagRepository()

        authRepository = DefaultAuthRepository()
    }

    // MARK: - Body

    var body: some View {
        AppCoordinatorView()
            .environment(\.featureFlagRepository, featureFlagRepository)
            .environment(\.authRepository, authRepository)
            .task {
                // Prefetch remote config values before the first screen renders.
                await (featureFlagRepository as? FirebaseFeatureFlagRepository)?.fetchAndActivate()
            }
    }
}
```

#### Consuming the service in a UseCase

UseCases receive the repository via initializer injection. They never access the SwiftUI Environment directly.

```swift
/// Resolves which onboarding flow variant to present based on a remote flag.
struct ResolveOnboardingFlowUseCase {

    // MARK: - Properties

    private let featureFlagRepository: any FeatureFlagRepository

    // MARK: - Lifecycle

    init(featureFlagRepository: some FeatureFlagRepository) {
        self.featureFlagRepository = featureFlagRepository
    }

    // MARK: - Public Interface

    /// Returns `true` when the redesigned onboarding flow is active.
    func execute() async -> Bool {
        await featureFlagRepository.bool(for: .newOnboardingFlow)
    }
}
```

#### Consuming the UseCase in a Page

```swift
struct OnboardingPage: View {
    @Environment(\.featureFlagRepository) private var featureFlagRepository
    @State private var viewModel: OnboardingViewModel?

    var body: some View {
        Group {
            if let vm = viewModel {
                OnboardingView(viewModel: vm)
            }
        }
        .onAppear {
            viewModel = OnboardingViewModel(
                resolveFlowUseCase: ResolveOnboardingFlowUseCase(
                    featureFlagRepository: featureFlagRepository
                )
            )
        }
    }
}
```

#### Step 6 — Mock for unit tests (`Tests/Mocks/MockFeatureFlagRepository.swift`)

Every protocol introduced in Step 2 must have a corresponding mock in the test target.

```swift
/// Controllable in-memory implementation of `FeatureFlagRepository` for unit tests.
final class MockFeatureFlagRepository: FeatureFlagRepository {

    // MARK: - Properties

    var boolValues:   [FeatureFlagKey: Bool]   = [:]
    var stringValues: [FeatureFlagKey: String] = [:]
    var intValues:    [FeatureFlagKey: Int]    = [:]

    // MARK: - FeatureFlagRepository

    func bool(for key: FeatureFlagKey) async -> Bool   { boolValues[key]   ?? false }
    func string(for key: FeatureFlagKey) async -> String? { stringValues[key] }
    func int(for key: FeatureFlagKey) async -> Int?    { intValues[key] }
}
```

---

### 10.4 FeatureFlagStore — Local State and Optional Remote Sync

`FeatureFlagStore` is a centralized `@Observable` class that owns and serves all feature flag values for the app. It is **self-sufficient by design**: it works without any remote config provider, serving values from local storage or hard-coded defaults. Firebase Remote Config and LaunchDarkly are optional enhancements that may push new values into the store after a fetch, but they are never required for the store to function.

This means:
- A project that does not use Firebase or LaunchDarkly still uses `FeatureFlagStore` to manage flags.
- Flags that are always hard-coded need no remote key and no storage key.
- Remote sync is wired exclusively in `DependencyContainer` and is invisible to the rest of the codebase.

#### File layout

```
Sources/
├── Domain/
│   └── FeatureFlags/
│       ├── FeatureFlagKey.swift            ← typed key enum for remote-backed flags (§10.3)
│       ├── FeatureFlagRepository.swift     ← optional remote provider protocol (§10.3)
│       ├── FeatureFlagStoring.swift        ← store protocol (this section)
│       └── FeatureFlagEntry.swift          ← BoolFlagEntry / StringFlagEntry / JsonFlagEntry
├── Data/
│   └── FeatureFlags/
│       ├── FeatureFlagStore.swift          ← concrete store
│       ├── BoolRemoteConfigFlag.swift      ← flag object
│       ├── StringRemoteConfigFlag.swift    ← flag object
│       └── JsonRemoteConfigFlag.swift      ← flag object
└── Core/
    └── Storage/
        ├── UserDefaultKeys.swift           ← centralized UserDefaults key registry
        ├── SwiftDataKeys.swift             ← centralized SwiftData model registry
        └── KeychainKeys.swift              ← centralized Keychain service registry
```

---

#### Flag objects — contract

A **flag object** is a lightweight class that holds one flag's current value and knows how to persist it locally. Three concrete types cover all value types:

| Type | Swift type | Typical source |
|---|---|---|
| `BoolRemoteConfigFlag` | `Bool` | Hard-coded default, UserDefaults, or remote bool |
| `StringRemoteConfigFlag` | `String` | Hard-coded default, UserDefaults, or remote string / JSON |
| `JsonRemoteConfigFlag<T: Decodable>` | `T` | Hard-coded default, UserDefaults, or remote JSON |

Every flag object satisfies this contract:

```swift
// Illustrative contract — not a full implementation
class BoolRemoteConfigFlag {

    // Optional — omit when the flag is never backed by a remote provider.
    let remoteKey: FeatureFlagKey?

    // Optional — omit when no local persistence is needed (see Storage backends).
    let storageKey: String?

    // Returned when the flag has never been set remotely or locally.
    // This is also the value used when no remote provider is configured.
    let defaultValue: Bool

    // Current value: reads from local storage if available, otherwise defaultValue.
    // Writing updates local storage when storageKey is present.
    var value: Bool { get set }

    // Fired only when the value changes (old != new).
    // Use for NotificationCenter broadcasts or cache invalidation.
    var onChange: ((_ old: Bool, _ new: Bool) -> Void)?

    // Fired on every remote write, even if the value did not change.
    // Use to sync to Keychain or an external system.
    var onUpdate: ((_ new: Bool) -> Void)?

    // Called by FeatureFlagStore.syncFromRemote(_:) after a successful provider fetch.
    // No-op when remoteKey is nil.
    func syncFrom(remoteConfig: Any)
}
```

`StringRemoteConfigFlag` and `JsonRemoteConfigFlag` follow the identical shape, substituting `Bool` with `String` or `T` respectively.

---

#### Storage backends

Choose the backend at declaration time. The choice is permanent for the lifetime of the flag.

| Backend | How to declare | When to use |
|---|---|---|
| **Hard-coded default only** | Omit both `remoteKey` and `storageKey`; set `defaultValue` | The flag has a fixed value that never changes at runtime and needs no override mechanism. |
| **UserDefaults** | Pass a `storageKey` from `UserDefaultKeys` | Default for most flags — value persists across launches and can be overridden via the Dev Options screen. |
| **Ephemeral** (in-memory only) | Provide `remoteKey` but omit `storageKey`; set `defaultValue` | The value is only meaningful for the current session, or is always re-fetched before first use. Resets to `defaultValue` on next launch. |
| **Keychain** | Omit `storageKey`; wire `onUpdate` in `setupSideEffects()` to write to `KeychainHelper` | The flag value is sensitive and must not appear in plain-text UserDefaults. |
| **SwiftData** | Omit `storageKey`; wire `onUpdate` to persist an `@Model` entity | The flag controls structured data already managed as a SwiftData model (rare). |

Rules:
- **Never hardcode a storage key string** — always reference a `case` from `UserDefaultKeys`, `KeychainKeys`, or `SwiftDataKeys`.
- **Never mix backends** for the same flag — choose one write path and do not add a second.
- **UserDefaults is the default** unless the flag is sensitive (Keychain) or session-scoped (ephemeral).

---

#### Centralized key registries

All local storage keys must be declared in a single enum per backend, organized by domain. This prevents collisions and makes every key searchable.

```swift
// Core/Storage/UserDefaultKeys.swift
enum UserDefaultKeys {
    enum Dev: String {
        case devMode = "Dev.devMode"
    }
    enum Auth: String {
        case byPassLogin = "Auth.byPassLogin"
    }
    enum AppConfig: String {
        case appDisabled  = "AppConfig.appDisabled"
        case forceUpdate  = "AppConfig.forceUpdate"
        case headerColor  = "AppConfig.headerColor"
    }
    // … one nested enum per domain
}

// Core/Storage/KeychainKeys.swift
enum KeychainKeys: String {
    case bypassDebugToken = "com.app.bypass.debug"
}
```

Naming rule: `"DomainGroup.camelCaseName"` for UserDefaults; reverse-DNS for Keychain.

---

#### `FeatureFlagStoring` protocol

The protocol is the public contract stored in the SwiftUI Environment. It exposes only value access and the Dev Options manifests. **Remote sync is not part of this contract** — it is an implementation detail of the concrete store.

```swift
// Domain/FeatureFlags/FeatureFlagStoring.swift
protocol FeatureFlagStoring: AnyObject {

    // MARK: - Flag properties (one per flag, get + set)
    var devMode: Bool { get set }
    var byPassLogin: Bool { get set }
    var appDisabled: Bool { get set }
    var forceUpdate: String { get set }
    var headerColor: String { get set }
    // … one entry per flag

    // MARK: - Dev Options manifests
    // Only flags with a UserDefaults storageKey appear in these arrays.
    var boolFlags:   [BoolFlagEntry]   { get }
    var stringFlags: [StringFlagEntry] { get }
    var jsonFlags:   [JsonFlagEntry]   { get }
}
```

`update(from:)` / `syncFromRemote(_:)` does **not** belong to this protocol. It lives on the concrete `FeatureFlagStore` class and is called only when a provider is present.

---

#### Entry types for the Dev Options screen

These lightweight structs describe each flag to the Dev Options UI. They carry no business logic.

```swift
// Domain/FeatureFlags/FeatureFlagEntry.swift

struct BoolFlagEntry: Identifiable {
    let key: FeatureFlagKey
    let storageKey: String          // Must match the UserDefaultKeys entry
    var id: String { key.rawValue }
}

struct StringFlagEntry: Identifiable {
    let key: FeatureFlagKey
    let storageKey: String
    let keyboardType: UIKeyboardType  // .default for text, .numberPad for numeric
    var id: String { key.rawValue }
}

enum JsonFlagSchema {
    case forceUpdate
    case configDisableApp
    // One case per distinct JSON structure served by remote config.
}

struct JsonFlagEntry: Identifiable {
    let key: FeatureFlagKey
    let storageKey: String
    let schema: JsonFlagSchema
    var id: String { key.rawValue }
}
```

Rules:
- Only flags that have a `storageKey` (UserDefaults backend) appear in the entry arrays.
- Flags without a `storageKey` (hard-coded, ephemeral, Keychain, SwiftData) are excluded — the Dev Options screen cannot override them.

---

#### `FeatureFlagStore` — structure and responsibilities

`FeatureFlagStore` is the only concrete type that may instantiate flag objects. Its internal structure is divided into five fixed sections, always in this order:

```swift
// Data/FeatureFlags/FeatureFlagStore.swift
@Observable
final class FeatureFlagStore: FeatureFlagStoring {

    // MARK: - Dev mode (@AppStorage — persists without a flag object)
    @AppStorage(UserDefaultKeys.Dev.devMode.rawValue)
    var devMode: Bool = false

    // MARK: - Flag objects  (one let per flag, alphabetical)
    //
    // Flags without remoteKey:  hard-coded or local-only — work without any provider.
    // Flags without storageKey: ephemeral (remoteKey only) or Keychain (see setupSideEffects).

    let byPassLoginFlag = BoolRemoteConfigFlag(
        remoteKey: .byPassLogin,                            // optional remote sync
        storageKey: UserDefaultKeys.Auth.byPassLogin.rawValue
    )
    let headerColorFlag = StringRemoteConfigFlag(
        remoteKey: .headerColor,
        storageKey: UserDefaultKeys.AppConfig.headerColor.rawValue,
        defaultValue: "red"                                 // served even without a provider
    )
    let byPassDebugFlag = StringRemoteConfigFlag(           // Keychain-backed: no storageKey
        remoteKey: .byPassDebug
    )
    let maintenanceModeFlag = BoolRemoteConfigFlag(         // hard-coded, no remote or storage
        defaultValue: false
    )

    // MARK: - Computed properties  (get/set passthroughs, same order as flag objects)

    var byPassLogin: Bool {
        get { byPassLoginFlag.value }
        set { byPassLoginFlag.value = newValue }
    }
    var headerColor: String {
        get { headerColorFlag.value }
        set { headerColorFlag.value = newValue }
    }
    var maintenanceMode: Bool {
        get { maintenanceModeFlag.value }
        set { maintenanceModeFlag.value = newValue }
    }

    // MARK: - Dev Options manifests  (only UserDefaults-backed flags)

    var boolFlags: [BoolFlagEntry] {
        [
            BoolFlagEntry(key: .byPassLogin, storageKey: UserDefaultKeys.Auth.byPassLogin.rawValue),
            // maintenanceModeFlag omitted — no storageKey
        ]
    }
    var stringFlags: [StringFlagEntry] {
        [
            StringFlagEntry(key: .headerColor, storageKey: UserDefaultKeys.AppConfig.headerColor.rawValue),
        ]
    }
    var jsonFlags: [JsonFlagEntry] { [] }

    // MARK: - Lifecycle

    init() {
        setupSideEffects()
        registerFlags()
    }

    // MARK: - Remote sync (called only when a provider is configured in DependencyContainer)

    /// Pushes values received from a remote config provider into all registered flag objects.
    ///
    /// Call this once per fetch cycle, after `fetchAndActivate()` completes.
    /// Safe to call when no flags have a `remoteKey` — it is a no-op for those flags.
    func syncFromRemote(_ remoteConfig: Any) {
        remoteBackedFlags.forEach { $0.syncFrom(remoteConfig: remoteConfig) }
    }

    // MARK: - Private

    private var remoteBackedFlags: [any RemoteConfigFlag] = []

    private func setupSideEffects() {
        // Assign onChange / onUpdate here — never at the flag object declaration site.
        byPassDebugFlag.onUpdate = { value in
            guard !value.isEmpty else { return }
            KeychainHelper.standard.save(text: value, service: KeychainKeys.bypassDebugToken.rawValue)
        }
    }

    private func registerFlags() {
        // Only flags with a remoteKey participate in syncFromRemote(_:).
        remoteBackedFlags = [ byPassLoginFlag, headerColorFlag, byPassDebugFlag ]
    }
}
```

---

#### Side-effect callbacks

| Callback | When it fires | Intended use |
|---|---|---|
| `onChange(old, new)` | Only when `old != new` after a remote sync | Post a `NotificationCenter` event, invalidate a cache, re-trigger a UseCase. |
| `onUpdate(new)` | Every remote write, even if value is unchanged | Sync the value to Keychain, SwiftData, or an external SDK. |

Both callbacks are assigned exclusively inside `setupSideEffects()`. Assigning them at the flag object declaration site is forbidden.

---

#### Remote provider integration (optional)

If the project includes Firebase Remote Config or LaunchDarkly, `DependencyContainer` wires the provider to the store after a successful fetch. The store and the rest of the codebase are completely unaware of whether a provider is present.

```swift
// DependencyContainer — with a remote provider
var body: some View {
    AppCoordinatorView()
        .environment(\.featureFlagStore, featureFlagStore)
        // featureFlagRepository is only added when a provider is used
        .environment(\.featureFlagRepository, featureFlagRepository)
        .task {
            await featureFlagRepository.fetchAndActivate()
            featureFlagStore.syncFromRemote(remoteConfigInstance)
        }
}

// DependencyContainer — without any remote provider
var body: some View {
    AppCoordinatorView()
        .environment(\.featureFlagStore, featureFlagStore)
        // No .task needed — the store serves defaultValues and UserDefaults immediately.
}
```

`FeatureFlagRepository` (§10.3) is responsible for **fetching** values from the provider.
`FeatureFlagStore` is responsible for **persisting and serving** those values locally.
They are two separate Environment entries with separate, non-overlapping concerns.

---

#### Checklist — adding a new flag

| # | File | What to add |
|---|---|---|
| 1 | `Domain/FeatureFlags/FeatureFlagKey.swift` | New `case` **only if** the flag is backed by a remote provider. `rawValue` must match the remote dashboard key exactly. Skip this file for local-only flags. |
| 2 | `Core/Storage/UserDefaultKeys.swift` (or `KeychainKeys.swift`) | New `case` in the relevant domain group. Skip if the flag is hard-coded or ephemeral. |
| 3 | `Data/FeatureFlags/FeatureFlagStore.swift` | ① Declare the flag object. ② Add the computed property. ③ Register in `registerFlags()` if it has a `remoteKey`. ④ Add to the entry array if it has a `storageKey`. |
| 4 | `Domain/FeatureFlags/FeatureFlagStoring.swift` | Add the new computed property to the protocol. |

Do not create a new file for a single flag. All flag objects live in `FeatureFlagStore`.

---

#### Rules

- `FeatureFlagStore` is the **only** class allowed to instantiate flag objects. ViewModels and UseCases must read and write flag values through the computed properties on `FeatureFlagStoring`, never by accessing a flag object directly.
- `FeatureFlagStoring` must not declare `syncFromRemote(_:)` or any method that references a provider type. Provider integration is a `FeatureFlagStore`-level concern.
- The three entry arrays (`boolFlags`, `stringFlags`, `jsonFlags`) must stay in sync with the flag objects that have a `storageKey`. A persisted flag absent from the arrays will be invisible to Dev Options.
- `syncFromRemote(_:)` must be called **at most once per fetch cycle**, after `fetchAndActivate()` completes. Never call it on every property access.
- A flag's storage backend is fixed at declaration. Changing it (e.g. UserDefaults → Keychain) requires removing the old key entry and migrating existing persisted values.
- `setupSideEffects()` is the single authorized location for `onChange` and `onUpdate` assignments. Callbacks must not be assigned elsewhere.
- `JsonRemoteConfigFlag` values are always decoded against a named `JsonFlagSchema` case. Never decode JSON flags inline in a ViewModel or UseCase.

---

## 11. Design System

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

## 12. Localization

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

## 13. Swift Concurrency

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

## 14. Code Quality

### SwiftLint

Configuration file: `.swiftlint.yml` at the project root. Enforced rules include:

- `force_unwrapping` — **error**: no `!` unwrapping in production code.
- `force_cast` — **error**: no `as!` in production code.
- `implicitly_unwrapped_optional` — **warning**: only permitted in `@IBOutlet` (none expected) or explicit test setup.
- `line_length` — **warning** at 120, **error** at 160.
- `file_length` — **warning** at 300 lines, **error** at 400. Split the file before hitting the warning.
- `type_body_length` — **warning** at 200 lines. Split types that exceed this.
- `function_body_length` — **warning** at 40 lines.
- `cyclomatic_complexity` — **warning** at 10.
- `trailing_whitespace`, `vertical_whitespace` — **error**: no trailing spaces, max one consecutive blank line.

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

## 15. Testing

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

## 16. CI/CD (GitHub Actions)

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

## 17. Git Conventions

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

## 18. What the Agent Must Always Do

- **Read this file in full** before generating or modifying any Swift code.
- **Follow MVVM strictly** — Views have zero logic; ViewModels have zero SwiftUI imports.
- **Use Atomic Design** — create/place components in the correct layer.
- **Apply SOLID principles** — every type has one responsibility, depends on abstractions, and is open for extension.
- **Use `Result<T, AppError>`** — never `throw` across layer boundaries.
- **Apply `@MainActor`** to all `@Observable` ViewModels.
- **Write Sendable-safe code** — all code must compile under Swift 6 strict concurrency.
- **Use String Catalogs** — never hardcode user-facing strings.
- **Follow naming conventions** — suffix every type with its layer role.
- **Include MARK sections** in every type with more than 3 properties or methods.
- **Write DocC comments** (`///`) for every class, struct, enum, actor, protocol, and non-trivial method.
- **Write tests** for every new UseCase and ViewModel.
- **Define a protocol in `Domain/` first** before writing any concrete SDK-wrapping type — this applies to every new injectable service (feature flags, analytics, push, A/B testing, etc.).
- **Place all `EnvironmentValues` entries** for repositories in `Core/Extensions/EnvironmentValues+Repositories.swift` — one entry per service, always typed to the protocol.
- **Annotate SDK-wrapping types `@unchecked Sendable`** only when thread safety is explicitly guaranteed by the SDK documentation, and always include a `/// - Note:` DocC comment explaining why it is safe.
- **Initialise all third-party SDKs** (`FirebaseApp.configure()`, `LDClient.start(...)`, etc.) exclusively inside `DependencyContainer` — never in a ViewModel, UseCase, or View.
- **Provide a `Mock{ProtocolName}` in the test target** for every new protocol introduced in `Domain/`.

## 19. What the Agent Must Never Do

- Create UIKit views, `UIViewController` subclasses, or `AppDelegate` logic (unless bridging to a third-party SDK).
- Use `@Published` or `ObservableObject` — use `@Observable` instead.
- Use `DispatchQueue` — use `async/await` and structured concurrency.
- Force-unwrap (`!`) or force-cast (`as!`) in non-test code.
- Hardcode colors, fonts, or spacing values — use the design system extensions.
- Hardcode user-facing strings — use String Catalogs.
- Add business logic to a View, Atom, Molecule, Organism, or Template.
- Return raw network/data models directly to ViewModels — always map to domain entities first.
- Create files longer than 300 lines — split responsibilities before reaching the limit.
- Skip `// MARK: -` sections in types with more than 3 members.
- Add `///` or `//` comments to stored properties — name them clearly instead.
- Include Xcode-generated file headers (`// Created by … on …`) — delete them entirely.
- Leave consecutive blank lines — maximum one blank line between any two code blocks.
- Violate SOLID — types with more than one responsibility, concrete dependencies in high-level modules, or fat protocols must be refactored before committing.
- **Import Firebase, LaunchDarkly, or any third-party SDK** directly inside a ViewModel, UseCase, View, Atom, Molecule, Organism, or Template — SDK imports are confined to concrete implementations in `Data/Repositories/`.
- **Expose a concrete SDK type as an `EnvironmentValues` entry** — the entry type must always be `any ProtocolName`, never a concrete class.
- **Call `configure()`, `start()`, or any SDK bootstrap method** outside of `DependencyContainer` — doing so in a ViewModel or UseCase creates hidden global side-effects that break testability.
- **Use `@unchecked Sendable` without a `/// - Note:` comment** — every suppression must document why it is safe.
