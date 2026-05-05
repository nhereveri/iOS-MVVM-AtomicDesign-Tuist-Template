import ProjectDescription

// ============================================================
// MARK: - Tuist Configuration
// ============================================================
// This file configures global Tuist behaviour.
// For project-specific settings, see Project.swift.

let config = Config(
    // Uncomment and fill in to enable Tuist Cloud (optional).
    // fullHandle: "organization/project-name",

    // .all accepts any Xcode version (16, 17, 26, ...).
    // Using a fixed range like .upToNextMajor("16.0") breaks
    // when Apple changes version naming (e.g. Xcode 26).
    compatibleXcodeVersions: .all,
    swiftVersion: "6.0"
)
