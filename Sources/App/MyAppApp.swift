//
//  MyAppApp.swift
//  MyApp — @main entry point
//

import SwiftUI

@main
struct MyAppApp: App {

    // MARK: - Properties

    @State private var coordinator = AppCoordinator()

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            AppCoordinatorView()
                .environment(coordinator)
        }
    }
}
