// SPDX-License-Identifier: AGPL-3.0-only
// SPDX-FileCopyrightText: 2026 Steve Clarke <stephenlclarke@mac.com> - https://xyzzy.tools

import Foundation

struct TimeZoneCandidate: Identifiable, Hashable {
    var id: String {
        identifier
    }

    var identifier: String
    var city: String
    var region: String

    func offsetDescription(on date: Date = .now) -> String {
        guard let timeZone = TimeZone(identifier: identifier) else {
            return "GMT"
        }

        let seconds = timeZone.secondsFromGMT(for: date)
        let sign = seconds >= 0 ? "+" : "-"
        let absolute = abs(seconds)
        let hours = absolute / 3600
        let minutes = (absolute % 3600) / 60

        if minutes == 0 {
            return "GMT\(sign)\(hours)"
        }

        return String(format: "GMT%@%d:%02d", sign, hours, minutes)
    }

    func matches(_ query: String) -> Bool {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else {
            return true
        }

        return city.lowercased().contains(normalized)
            || region.lowercased().contains(normalized)
            || identifier.lowercased().contains(normalized)
    }
}

enum TimeZoneCatalog {
    static let all: [TimeZoneCandidate] = TimeZone.knownTimeZoneIdentifiers
        .filter { !$0.hasPrefix("Etc/") }
        .map { identifier in
            TimeZoneCandidate(
                identifier: identifier,
                city: cityName(for: identifier),
                region: regionName(for: identifier)
            )
        }
        .sorted { lhs, rhs in
            if lhs.city == rhs.city {
                return lhs.region < rhs.region
            }

            return lhs.city < rhs.city
        }

    static func search(_ query: String, limit: Int = 80) -> [TimeZoneCandidate] {
        all.filter { $0.matches(query) }.prefix(limit).map(\.self)
    }

    static func cityName(for identifier: String) -> String {
        identifier
            .split(separator: "/")
            .last
            .map(String.init)?
            .replacingOccurrences(of: "_", with: " ") ?? identifier
    }

    static func regionName(for identifier: String) -> String {
        let parts = identifier.split(separator: "/")

        if parts.count > 1 {
            return parts.dropLast().joined(separator: " / ").replacingOccurrences(of: "_", with: " ")
        }

        return "Time zone"
    }
}
