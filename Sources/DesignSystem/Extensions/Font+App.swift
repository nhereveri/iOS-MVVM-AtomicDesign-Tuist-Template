//
//  Font+App.swift
//  MyApp — Typography scale
//

import SwiftUI

extension Font {

    // MARK: - Display

    static let displayLarge:  Font = .system(size: 34, weight: .bold)
    static let displayMedium: Font = .system(size: 28, weight: .semibold)

    // MARK: - Headline

    static let headlineLarge:  Font = .system(size: 22, weight: .semibold)
    static let headlineMedium: Font = .system(size: 18, weight: .semibold)

    // MARK: - Body

    static let bodyLarge:  Font = .system(size: 17, weight: .regular)
    static let bodyMedium: Font = .system(size: 15, weight: .regular)

    // MARK: - Label / Caption

    static let caption:     Font = .system(size: 12, weight: .regular)
    static let labelSmall:  Font = .system(size: 11, weight: .medium)
}
