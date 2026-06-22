// SPDX-License-Identifier: AGPL-3.0-only
// SPDX-FileCopyrightText: 2026 Steve Clarke <stephenlclarke@mac.com> - https://xyzzy.tools

import SwiftUI

struct SettingsView: View {
    @Environment(TimeBuddyStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section {
                Picker("Hour Format", selection: hourFormatBinding) {
                    ForEach(HourFormat.allCases) { format in
                        Text(format.title).tag(format)
                    }
                }
                .pickerStyle(.segmented)

                Toggle("Highlight weekends", isOn: showsWeekendsBinding)
                Toggle("Show FX market bands", isOn: showsMarketSessionsBinding)
            }

            Section {
                Stepper(value: selectedDurationBinding, in: 1...12) {
                    Text("Default selection: \(store.selectedDuration)h")
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") {
                    dismiss()
                }
            }
        }
    }

    private var hourFormatBinding: Binding<HourFormat> {
        Binding(
            get: { store.hourFormat },
            set: { store.hourFormat = $0 }
        )
    }

    private var showsWeekendsBinding: Binding<Bool> {
        Binding(
            get: { store.showsWeekends },
            set: { store.showsWeekends = $0 }
        )
    }

    private var showsMarketSessionsBinding: Binding<Bool> {
        Binding(
            get: { store.showsMarketSessions },
            set: { store.showsMarketSessions = $0 }
        )
    }

    private var selectedDurationBinding: Binding<Int> {
        Binding(
            get: { store.selectedDuration },
            set: { store.selectedDuration = $0 }
        )
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environment(TimeBuddyStore.preview)
    }
}
