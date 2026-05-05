//
//  Color+Brand.swift
//  MyApp — Semantic color tokens
//
//  All colors are defined in Assets.xcassets with light/dark variants.
//  Never use hardcoded hex values anywhere in the app.
//

import SwiftUI

extension Color {

    // MARK: - Brand

    static let brandPrimary   = Color("BrandPrimary",   bundle: .main)
    static let brandSecondary = Color("BrandSecondary", bundle: .main)

    // MARK: - Text

    static let textPrimary   = Color("TextPrimary",   bundle: .main)
    static let textSecondary = Color("TextSecondary", bundle: .main)

    // MARK: - Background

    static let backgroundPrimary   = Color("BackgroundPrimary",   bundle: .main)
    static let backgroundSecondary = Color("BackgroundSecondary", bundle: .main)

    // MARK: - Semantic

    static let destructive = Color("Destructive", bundle: .main)
    static let success     = Color("Success",     bundle: .main)
    static let warning     = Color("Warning",     bundle: .main)
}
