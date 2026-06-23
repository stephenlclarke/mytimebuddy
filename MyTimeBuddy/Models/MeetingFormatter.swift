// SPDX-License-Identifier: AGPL-3.0-only
// SPDX-FileCopyrightText: 2026 Steve Clarke <stephenlclarke@mac.com> - https://xyzzy.tools

import Foundation

enum MeetingFormatter {
    static func text(
        start: Date,
        durationHours: Int,
        locations: [BuddyLocation],
        title: String = "My Time Buddy selection"
    ) -> String {
        let end = start.addingTimeInterval(TimeInterval(durationHours * 3600))
        var lines = [title, "Duration: \(durationHours)h"]

        for location in locations {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            formatter.timeZone = location.timeZone

            lines.append("\(location.name): \(formatter.string(from: start)) - \(formatter.string(from: end))")
        }

        return lines.joined(separator: "\n")
    }
}
