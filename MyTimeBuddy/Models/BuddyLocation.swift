// SPDX-License-Identifier: AGPL-3.0-only
// SPDX-FileCopyrightText: 2026 Steve Clarke <stephenlclarke@mac.com> - https://xyzzy.tools

import Foundation

struct BuddyLocation: Codable, Equatable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var timeZoneIdentifier: String
    var isHome: Bool

    init(
        id: UUID = UUID(),
        name: String,
        timeZoneIdentifier: String,
        isHome: Bool = false
    ) {
        self.id = id
        self.name = name
        self.timeZoneIdentifier = timeZoneIdentifier
        self.isHome = isHome
    }

    var timeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? .current
    }

    var abbreviation: String {
        timeZone.abbreviation() ?? timeZoneIdentifier
    }
}

extension BuddyLocation {
    static let london = BuddyLocation(name: "London", timeZoneIdentifier: "Europe/London", isHome: true)
    static let newYork = BuddyLocation(name: "New York", timeZoneIdentifier: "America/New_York")
    static let sanFrancisco = BuddyLocation(name: "San Francisco", timeZoneIdentifier: "America/Los_Angeles")
    static let tokyo = BuddyLocation(name: "Tokyo", timeZoneIdentifier: "Asia/Tokyo")
}
