//
//  AppCoordinator.swift
//  MyApp — Root navigation coordinator
//

import SwiftUI

// MARK: - Route

enum AppRoute: Hashable {
    // Add top-level routes here.
    // Example: case home, onboarding, settings
}

// MARK: - Coordinator

@MainActor
@Observable
final class AppCoordinator {

    // MARK: - Properties

    var path = NavigationPath()

    // MARK: - Navigation

    func push(_ route: AppRoute) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path.removeLast(path.count)
    }
}

// MARK: - Root View

struct AppCoordinatorView: View {

    // MARK: - Properties

    @Environment(AppCoordinator.self) private var coordinator

    // MARK: - Body

    var body: some View {
        @Bindable var coordinator = coordinator
        NavigationStack(path: $coordinator.path) {
            // Replace with your initial screen.
            Text("Welcome to MyApp")
                .navigationDestination(for: AppRoute.self) { route in
                    // Handle routes here.
                    // Example: switch route { case .home: HomeView() }
                    EmptyView()
                }
        }
    }
}
