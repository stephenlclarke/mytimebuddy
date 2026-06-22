// SPDX-License-Identifier: AGPL-3.0-only
// SPDX-FileCopyrightText: 2026 Steve Clarke <stephenlclarke@mac.com> - https://xyzzy.tools

import Foundation

enum HourFormat: String, CaseIterable, Codable, Identifiable {
    case twelve
    case twentyFour
    case mixed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .twelve:
            "12h"
        case .twentyFour:
            "24h"
        case .mixed:
            "Mixed"
        }
    }

    func label(for date: Date, in timeZone: TimeZone) -> HourLabel {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let hour = calendar.component(.hour, from: date)

        switch resolvedFormat(for: timeZone) {
        case .twelve:
            let display = hour % 12 == 0 ? 12 : hour % 12
            return HourLabel(value: "\(display)", suffix: hour < 12 ? "am" : "pm")
        case .twentyFour:
            return HourLabel(value: String(format: "%02d", hour), suffix: "")
        case .mixed:
            return HourLabel(value: "\(hour)", suffix: "")
        }
    }

    private func resolvedFormat(for timeZone: TimeZone) -> HourFormat {
        guard self == .mixed else {
            return self
        }

        if timeZone.identifier.hasPrefix("America/") || timeZone.identifier == "Europe/London" {
            return .twelve
        }

        return .twentyFour
    }
}

struct HourLabel: Equatable {
    var value: String
    var suffix: String
}
