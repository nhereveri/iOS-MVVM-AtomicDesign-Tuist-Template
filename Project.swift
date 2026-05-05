import ProjectDescription

// ============================================================
// MARK: - Template Variables
// Edit the values in this block for each new project.
// ============================================================

/// Display name of the app (also the Xcode project name).
let projectName: String = "MyApp"

/// Reverse-DNS prefix used to build all bundle identifiers.
/// The production bundle ID will be "\(bundleIdPrefix).\(projectName.lowercased())".
/// Dev / Staging / UAT append a suffix automatically — see Derived Constants below.
let bundleIdPrefix: String = "com.yourcompany"

/// Human-readable company / team name (appears in Xcode project settings).
let organizationName: String = "Your Company"

/// Version shown to users in the App Store (CFBundleShortVersionString).
let marketingVersion: String = "1.0.0"

/// Build number used by TestFlight and the App Store (CFBundleVersion).
/// Increment for every TestFlight / App Store submission.
let currentProjectVersion: String = "1"

/// Minimum iOS version the app supports.
let iOSDeploymentTarget: String = "18.0"

/// Base language for String Catalogs and Xcode's development region.
let developmentRegion: String = "en"

/// All locales the app supports. The first entry must match `developmentRegion`.
let knownRegions: [String] = ["en", "es"]

// ── API base URLs per environment ────────────────────────────────────────────
// These are injected into Info.plist and read at runtime by APIClient.
// Never hardcode them inside Swift source files.

/// Developer's local server (can also point to a shared dev server).
let apiBaseURLDebug: String = "http://localhost:8080/api/v1"

/// Shared staging server used by the engineering team for integration testing.
let apiBaseURLStaging: String = "https://api.staging.yourcompany.com/api/v1"

/// Pre-production server used by QA and the client for acceptance testing.
let apiBaseURLUAT: String = "https://api.uat.yourcompany.com/api/v1"

/// Live production server. Only the Release scheme points here.
let apiBaseURLProduction: String = "https://api.yourcompany.com/api/v1"

// ============================================================
// MARK: - Derived Constants (do not edit)
// ============================================================

private let appBundleId    = "\(bundleIdPrefix).\(projectName.lowercased())"
private let testsBundleId  = "\(appBundleId).tests"
private let sourcesPath    = "Sources"
private let testsPath      = "Tests"
private let resourcesPath  = "Resources"

/// All 4 builds can be installed on the same device simultaneously
/// because each has a unique bundle identifier.
private let bundleIdDev     = "\(appBundleId).dev"
private let bundleIdStaging = "\(appBundleId).staging"
private let bundleIdUAT     = "\(appBundleId).uat"
private let bundleIdRelease = appBundleId

// ============================================================
// MARK: - Build Settings
// ============================================================

/// Settings shared by every configuration.
private let sharedBaseSettings: SettingsDictionary = [
    "SWIFT_VERSION":                .string("6.0"),
    "SWIFT_STRICT_CONCURRENCY":     .string("complete"),
    "IPHONEOS_DEPLOYMENT_TARGET":   .string(iOSDeploymentTarget),
    "MARKETING_VERSION":            .string(marketingVersion),
    "CURRENT_PROJECT_VERSION":      .string(currentProjectVersion),
    "DEVELOPMENT_LANGUAGE":         .string(developmentRegion),
    "SWIFT_EMIT_LOC_STRINGS":       .string("YES"),
    "ENABLE_PREVIEWS":              .string("YES"),
    "ENABLE_HARDENED_RUNTIME":      .string("YES"),
]

/// Settings shared by distribution configurations (Staging, UAT, Release).
private let sharedReleaseSettings: SettingsDictionary = [
    "DEBUG_INFORMATION_FORMAT":     .string("dwarf-with-dsym"),
    "SWIFT_COMPILATION_MODE":       .string("wholemodule"),
    "SWIFT_OPTIMIZATION_LEVEL":     .string("-O"),
    "VALIDATE_PRODUCT":             .string("YES"),
    "ENABLE_BITCODE":               .string("NO"),
    "COPY_PHASE_STRIP":             .string("NO"),
]

// ── Per-configuration settings ────────────────────────────────────────────────

/// Debug — local development only, never distributed.
private let debugSettings: SettingsDictionary =
    sharedBaseSettings.merging([
        "PRODUCT_BUNDLE_IDENTIFIER":            .string(bundleIdDev),
        "DISPLAY_NAME":                         .string("\(projectName) Dev"),
        "APP_ENV":                              .string("debug"),
        "API_BASE_URL":                         .string(apiBaseURLDebug),
        "DEBUG_INFORMATION_FORMAT":             .string("dwarf"),
        "ENABLE_TESTABILITY":                   .string("YES"),
        "SWIFT_ACTIVE_COMPILATION_CONDITIONS":  .array(["DEBUG"]),
        "MTL_ENABLE_DEBUG_INFO":                .string("INCLUDE_SOURCE"),
        "ONLY_ACTIVE_ARCH":                     .string("YES"),
    ]) { _, new in new }

/// Staging — distributed to the engineering team via TestFlight.
private let stagingSettings: SettingsDictionary =
    sharedBaseSettings.merging(sharedReleaseSettings).merging([
        "PRODUCT_BUNDLE_IDENTIFIER":            .string(bundleIdStaging),
        "DISPLAY_NAME":                         .string("\(projectName) STG"),
        "APP_ENV":                              .string("staging"),
        "API_BASE_URL":                         .string(apiBaseURLStaging),
        "SWIFT_ACTIVE_COMPILATION_CONDITIONS":  .array(["STAGING"]),
    ]) { _, new in new }

/// UAT — distributed to QA and the client via TestFlight for acceptance testing.
private let uatSettings: SettingsDictionary =
    sharedBaseSettings.merging(sharedReleaseSettings).merging([
        "PRODUCT_BUNDLE_IDENTIFIER":            .string(bundleIdUAT),
        "DISPLAY_NAME":                         .string("\(projectName) UAT"),
        "APP_ENV":                              .string("uat"),
        "API_BASE_URL":                         .string(apiBaseURLUAT),
        "SWIFT_ACTIVE_COMPILATION_CONDITIONS":  .array(["UAT"]),
    ]) { _, new in new }

/// Release — App Store production build.
private let releaseSettings: SettingsDictionary =
    sharedBaseSettings.merging(sharedReleaseSettings).merging([
        "PRODUCT_BUNDLE_IDENTIFIER":            .string(bundleIdRelease),
        "DISPLAY_NAME":                         .string(projectName),
        "APP_ENV":                              .string("production"),
        "API_BASE_URL":                         .string(apiBaseURLProduction),
        // Uncomment when the codebase is warning-free:
        // "SWIFT_TREAT_WARNINGS_AS_ERRORS":    .string("YES"),
    ]) { _, new in new }

// ── Assembled Settings objects ────────────────────────────────────────────────

private let appSettings: Settings = .settings(
    configurations: [
        .debug(  name: "Debug",   settings: debugSettings),
        .release(name: "Staging", settings: stagingSettings),
        .release(name: "UAT",     settings: uatSettings),
        .release(name: "Release", settings: releaseSettings),
    ],
    defaultSettings: .recommended(excluding: ["SWIFT_VERSION"])
)

private let testsSettings: Settings = .settings(
    configurations: [
        // Tests always run against the Debug configuration.
        .debug(  name: "Debug",   settings: debugSettings),
        // Mirror release configs so Xcode doesn't warn about missing configurations.
        .release(name: "Staging", settings: stagingSettings),
        .release(name: "UAT",     settings: uatSettings),
        .release(name: "Release", settings: releaseSettings),
    ],
    defaultSettings: .recommended(excluding: ["SWIFT_VERSION"])
)

// ============================================================
// MARK: - Info.plist
// ============================================================
// Build-setting variables ($(VAR)) are resolved by Xcode at build time,
// so each configuration gets its own value without any #if in Swift code.

private let appInfoPlist: InfoPlist = .extendingDefault(with: [
    "CFBundleDisplayName":          .string("$(DISPLAY_NAME)"),
    "CFBundleShortVersionString":   .string(marketingVersion),
    "CFBundleVersion":              .string(currentProjectVersion),
    // Read in AppEnvironment.swift via Bundle.main.infoDictionary
    "APP_ENV":                      .string("$(APP_ENV)"),
    "API_BASE_URL":                 .string("$(API_BASE_URL)"),
    // Scene-based lifecycle
    "UIApplicationSceneManifest": .dictionary([
        "UIApplicationSupportsMultipleScenes": .boolean(false),
        "UISceneConfigurations":               .dictionary([:]),
    ]),
    // Restrict to HTTPS; add NSExceptionDomains for local dev if needed
    "NSAppTransportSecurity": .dictionary([
        "NSAllowsArbitraryLoads": .boolean(false),
    ]),
    "UIUserInterfaceStyle": .string("Automatic"),
    // Portrait only — add landscape entries here if required
    "UISupportedInterfaceOrientations": .array([
        .string("UIInterfaceOrientationPortrait"),
    ]),
])

// ============================================================
// MARK: - Build Phase Scripts
// ============================================================

private let swiftLintScript: TargetScript = .pre(
    script: """
    if which swiftlint > /dev/null; then
        swiftlint lint --config "${SRCROOT}/.swiftlint.yml" --quiet
    else
        echo "warning: SwiftLint not installed — run: brew install swiftlint"
    fi
    """,
    name: "SwiftLint",
    basedOnDependencyAnalysis: false
)

private let swiftFormatScript: TargetScript = .pre(
    script: """
    if which swiftformat > /dev/null; then
        swiftformat --config "${SRCROOT}/.swiftformat" "${SRCROOT}/\(sourcesPath)" --quiet
    else
        echo "warning: SwiftFormat not installed — run: brew install swiftformat"
    fi
    """,
    name: "SwiftFormat",
    basedOnDependencyAnalysis: false
)

// ============================================================
// MARK: - Targets
// ============================================================

private let appTarget: Target = .target(
    name: projectName,
    destinations: [.iPhone],
    product: .app,
    // Base bundle ID; overridden per configuration via PRODUCT_BUNDLE_IDENTIFIER.
    bundleId: appBundleId,
    deploymentTargets: .iOS(iOSDeploymentTarget),
    infoPlist: appInfoPlist,
    sources: ["\(sourcesPath)/**"],
    resources: ["\(resourcesPath)/**"],
    scripts: [
        swiftFormatScript,
        swiftLintScript,
    ],
    dependencies: [
        // Add external SPM dependencies here after declaring them in `packages` below.
        // Example: .external(name: "Kingfisher"),
    ],
    settings: appSettings
)

private let testsTarget: Target = .target(
    name: "\(projectName)Tests",
    destinations: [.iPhone],
    product: .unitTests,
    bundleId: testsBundleId,
    deploymentTargets: .iOS(iOSDeploymentTarget),
    infoPlist: .default,
    sources: ["\(testsPath)/**"],
    resources: [],
    dependencies: [
        .target(name: projectName),
    ],
    settings: testsSettings
)

// ============================================================
// MARK: - Schemes
// ============================================================
// One scheme per environment. Each scheme pins its run/archive actions
// to the matching build configuration so there is no ambiguity.

/// Dev scheme — used by developers during local development.
private let devScheme: Scheme = .scheme(
    name: "\(projectName) (Dev)",
    shared: true,
    buildAction: .buildAction(targets: [.target(projectName)]),
    testAction: .targets(
        [
            .testableTarget(
                target: .target("\(projectName)Tests"),
                isParallelizable: true,
                isRandomExecutionOrdering: true
            ),
        ],
        configuration: "Debug",
        options: .options(
            coverage: true,
            codeCoverageTargets: [.target(projectName)]
        )
    ),
    runAction: .runAction(
        configuration: "Debug",
        arguments: .arguments(
            environmentVariables: [
                "MALLOC_STACK_LOGGING": .environmentVariable(value: "0", isEnabled: false),
            ]
        )
    ),
    archiveAction: .archiveAction(configuration: "Debug"),
    profileAction: .profileAction(configuration: "Debug"),
    analyzeAction: .analyzeAction(configuration: "Debug")
)

/// Staging scheme — builds distributed to the engineering team via TestFlight.
private let stagingScheme: Scheme = .scheme(
    name: "\(projectName) (Staging)",
    shared: true,
    buildAction: .buildAction(targets: [.target(projectName)]),
    testAction: .targets(
        [
            .testableTarget(
                target: .target("\(projectName)Tests"),
                isParallelizable: true,
                isRandomExecutionOrdering: true
            ),
        ],
        configuration: "Debug",
        options: .options(
            coverage: true,
            codeCoverageTargets: [.target(projectName)]
        )
    ),
    runAction: .runAction(configuration: "Staging"),
    archiveAction: .archiveAction(configuration: "Staging"),
    profileAction: .profileAction(configuration: "Staging"),
    analyzeAction: .analyzeAction(configuration: "Staging")
)

/// UAT scheme — builds distributed to QA and the client via TestFlight.
private let uatScheme: Scheme = .scheme(
    name: "\(projectName) (UAT)",
    shared: true,
    buildAction: .buildAction(targets: [.target(projectName)]),
    testAction: .targets(
        [
            .testableTarget(
                target: .target("\(projectName)Tests"),
                isParallelizable: true,
                isRandomExecutionOrdering: true
            ),
        ],
        configuration: "Debug",
        options: .options(
            coverage: true,
            codeCoverageTargets: [.target(projectName)]
        )
    ),
    runAction: .runAction(configuration: "UAT"),
    archiveAction: .archiveAction(configuration: "UAT"),
    profileAction: .profileAction(configuration: "UAT"),
    analyzeAction: .analyzeAction(configuration: "UAT")
)

/// Production scheme — App Store release builds only.
private let productionScheme: Scheme = .scheme(
    name: projectName,
    shared: true,
    buildAction: .buildAction(targets: [.target(projectName)]),
    testAction: .targets(
        [
            .testableTarget(
                target: .target("\(projectName)Tests"),
                isParallelizable: true,
                isRandomExecutionOrdering: true
            ),
        ],
        configuration: "Debug",
        options: .options(
            coverage: true,
            codeCoverageTargets: [.target(projectName)]
        )
    ),
    runAction: .runAction(configuration: "Release"),
    archiveAction: .archiveAction(configuration: "Release"),
    profileAction: .profileAction(configuration: "Release"),
    analyzeAction: .analyzeAction(configuration: "Release")
)

// ============================================================
// MARK: - Project
// ============================================================

let project = Project(
    name: projectName,
    organizationName: organizationName,
    options: .options(
        automaticSchemesOptions: .disabled,
        defaultKnownRegions: knownRegions,
        developmentRegion: developmentRegion,
        disableBundleAccessors: false,
        disableSynthesizedResourceAccessors: false,
        textSettings: .textSettings(
            usesTabs: false,
            indentWidth: 4,
            tabWidth: 4,
            wrapsLines: false
        )
    ),
    packages: [
        // Declare remote Swift packages here.
        // Example:
        // .remote(url: "https://github.com/onevcat/Kingfisher", requirement: .upToNextMajor(from: "7.0.0")),
    ],
    settings: appSettings,
    targets: [
        appTarget,
        testsTarget,
    ],
    schemes: [
        devScheme,
        stagingScheme,
        uatScheme,
        productionScheme,
    ],
    additionalFiles: [
        ".swiftlint.yml",
        ".swiftformat",
        "CLAUDE.md",
    ]
)
