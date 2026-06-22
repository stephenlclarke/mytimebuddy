// SPDX-License-Identifier: AGPL-3.0-only
// SPDX-FileCopyrightText: 2026 Steve Clarke <stephenlclarke@mac.com> - https://xyzzy.tools

import Foundation

struct MarketSession: Identifiable, Hashable {
    var id: String { name }
    var name: String
    var timeZoneIdentifier: String
    var startHour: Int
    var endHour: Int

    var timeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? .current
    }

    func timelineSegments(boardStart: Date, hoursVisible: Int = 24) -> [ClosedRange<Double>] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        var segments: [ClosedRange<Double>] = []

        for dayOffset in -1...1 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: boardStart) else {
                continue
            }

            let components = calendar.dateComponents([.year, .month, .day], from: day)
            guard
                let localMidnight = calendar.date(from: components),
                let start = calendar.date(byAdding: .hour, value: startHour, to: localMidnight),
                let end = calendar.date(byAdding: .hour, value: endHour, to: localMidnight)
            else {
                continue
            }

            let startOffset = start.timeIntervalSince(boardStart) / 3_600
            let endOffset = end.timeIntervalSince(boardStart) / 3_600
            let clippedStart = max(0, startOffset)
            let clippedEnd = min(Double(hoursVisible), endOffset)

            if clippedEnd > clippedStart {
                segments.append(clippedStart...clippedEnd)
            }
        }

        return segments
    }
}

extension MarketSession {
    static let fxDefaults: [MarketSession] = [
        MarketSession(name: "Sydney FX", timeZoneIdentifier: "Australia/Sydney", startHour: 8, endHour: 17),
        MarketSession(name: "Tokyo FX", timeZoneIdentifier: "Asia/Tokyo", startHour: 8, endHour: 17),
        MarketSession(name: "London FX", timeZoneIdentifier: "Europe/London", startHour: 8, endHour: 17),
        MarketSession(name: "New York FX", timeZoneIdentifier: "America/New_York", startHour: 8, endHour: 17)
    ]
}
