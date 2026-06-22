// SPDX-License-Identifier: AGPL-3.0-only
// SPDX-FileCopyrightText: 2026 Steve Clarke <stephenlclarke@mac.com> - https://xyzzy.tools

import SwiftUI

@main
struct MyTimeBuddyApp: App {
    @State private var store = TimeBuddyStore()

    var body: some Scene {
        WindowGroup {
            AppView()
                .environment(store)
        }
    }
}
