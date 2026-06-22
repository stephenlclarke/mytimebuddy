// SPDX-License-Identifier: AGPL-3.0-only
// SPDX-FileCopyrightText: 2026 Steve Clarke <stephenlclarke@mac.com> - https://xyzzy.tools

import SwiftUI

enum BoardSheet: Identifiable {
    case addLocation
    case manageLocations
    case settings

    var id: String {
        switch self {
        case .addLocation:
            "add-location"
        case .manageLocations:
            "manage-locations"
        case .settings:
            "settings"
        }
    }
}

struct AppView: View {
    @Environment(TimeBuddyStore.self) private var store
    @State private var sheet: BoardSheet?

    var body: some View {
        NavigationStack {
            TimeBoardView(sheet: $sheet)
                .navigationTitle("My Time Buddy")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button {
                            sheet = .addLocation
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("Add location")

                        Button {
                            sheet = .manageLocations
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                        }
                        .accessibilityLabel("Manage locations")

                        Button {
                            sheet = .settings
                        } label: {
                            Image(systemName: "gearshape")
                        }
                        .accessibilityLabel("Settings")
                    }
                }
        }
        .sheet(item: $sheet) { destination in
            NavigationStack {
                switch destination {
                case .addLocation:
                    AddLocationView()
                case .manageLocations:
                    ManageLocationsView()
                case .settings:
                    SettingsView()
                }
            }
            .environment(store)
        }
    }
}

#Preview {
    AppView()
        .environment(TimeBuddyStore.preview)
}
