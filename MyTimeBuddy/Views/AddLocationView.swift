// SPDX-License-Identifier: AGPL-3.0-only
// SPDX-FileCopyrightText: 2026 Steve Clarke <stephenlclarke@mac.com> - https://xyzzy.tools

import SwiftUI

struct AddLocationView: View {
    @Environment(TimeBuddyStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var results: [TimeZoneCandidate] {
        TimeZoneCatalog.search(query)
    }

    var body: some View {
        List(results) { candidate in
            Button {
                store.addLocation(from: candidate)
                dismiss()
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(candidate.city)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text(candidate.identifier)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text(candidate.offsetDescription(on: store.selectedStart))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
            .disabled(store.locations.contains(where: { $0.timeZoneIdentifier == candidate.identifier }))
        }
        .navigationTitle("Add Location")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "City or time zone")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AddLocationView()
            .environment(TimeBuddyStore.preview)
    }
}
