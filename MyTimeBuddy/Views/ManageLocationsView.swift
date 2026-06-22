// SPDX-License-Identifier: AGPL-3.0-only
// SPDX-FileCopyrightText: 2026 Steve Clarke <stephenlclarke@mac.com> - https://xyzzy.tools

import SwiftUI

struct ManageLocationsView: View {
    @Environment(TimeBuddyStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var renameTarget: BuddyLocation?
    @State private var draftName = ""

    var body: some View {
        List {
            ForEach(store.locations) { location in
                HStack(spacing: 12) {
                    Image(systemName: location.isHome ? "house.fill" : "clock")
                        .foregroundStyle(location.isHome ? .green : .secondary)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(location.name)
                            .font(.body.weight(.semibold))
                        Text(location.timeZoneIdentifier)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Menu {
                        Button {
                            store.markHome(location)
                        } label: {
                            Label("Make Home", systemImage: "house")
                        }

                        Button {
                            renameTarget = location
                            draftName = location.name
                        } label: {
                            Label("Rename", systemImage: "pencil")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("Location actions")
                }
            }
            .onDelete(perform: store.removeLocations)
            .onMove(perform: store.moveLocations)
        }
        .navigationTitle("Locations")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
        .alert("Rename Location", isPresented: Binding(
            get: { renameTarget != nil },
            set: { if !$0 { renameTarget = nil } }
        )) {
            TextField("Name", text: $draftName)

            Button("Save") {
                if let renameTarget {
                    store.rename(renameTarget, to: draftName)
                }
                renameTarget = nil
            }

            Button("Cancel", role: .cancel) {
                renameTarget = nil
            }
        }
    }
}

#Preview {
    NavigationStack {
        ManageLocationsView()
            .environment(TimeBuddyStore.preview)
    }
}
