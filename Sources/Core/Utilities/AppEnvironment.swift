//
//  AppEnvironment.swift
//  MyApp — Runtime environment resolver
//
//  Reads build-time values injected into Info.plist by Tuist.
//  Use AppEnvironment instead of #if DEBUG / #if STAGING anywhere in the app.
//

import Foundation

// MARK: - AppEnvironment

enum AppEnvironment {

    // MARK: - API

    /// Base URL for all network requests. Resolved per build configuration.
    static var apiBaseURL: URL {
        guard
            let raw = Bundle.main.infoDictionary?["API_BASE_URL"] as? String,
            let url = URL(string: raw)
        else {
            fatalError("API_BASE_URL is missing or malformed in Info.plist")
        }
        return url
    }

    // MARK: - Environment Name

    /// Current environment identifier: "debug" | "staging" | "uat" | "production".
    static var name: String {
        Bundle.main.infoDictionary?["APP_ENV"] as? String ?? "unknown"
    }

    // MARK: - Helpers

    static var isDebug: Bool { name == "debug" }
    static var isStaging: Bool { name == "staging" }
    static var isUAT: Bool { name == "uat" }
    static var isProduction: Bool { name == "production" }
}
