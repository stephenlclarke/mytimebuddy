// SPDX-License-Identifier: AGPL-3.0-only
// SPDX-FileCopyrightText: 2026 Steve Clarke <stephenlclarke@mac.com> - https://xyzzy.tools

import Foundation
import Observation

@MainActor
@Observable
final class TimeBuddyStore {
    var locations: [BuddyLocation] {
        didSet { saveLocations() }
    }

    var selectedDate: Date
    var selectedHour: Int {
        didSet { savePreferences() }
    }

    var selectedDuration: Int {
        didSet { savePreferences() }
    }

    var showsWeekends: Bool {
        didSet { savePreferences() }
    }

    var showsMarketSessions: Bool {
        didSet { savePreferences() }
    }

    var hourFormat: HourFormat {
        didSet { savePreferences() }
    }

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let locationKey = "mytimebuddy.locations"
    @ObservationIgnored private let preferencesKey = "mytimebuddy.preferences"

    init(defaults: UserDefaults = .standard, now: Date = .now) {
        self.defaults = defaults
        selectedDate = now

        if let data = defaults.data(forKey: locationKey),
           let saved = try? JSONDecoder().decode([BuddyLocation].self, from: data),
           !saved.isEmpty {
            locations = TimeBuddyStore.ensureSingleHome(saved)
        } else {
            locations = TimeBuddyStore.defaultLocations()
        }

        if let data = defaults.data(forKey: preferencesKey),
           let saved = try? JSONDecoder().decode(Preferences.self, from: data) {
            selectedHour = saved.selectedHour
            selectedDuration = saved.selectedDuration
            showsWeekends = saved.showsWeekends
            showsMarketSessions = saved.showsMarketSessions
            hourFormat = saved.hourFormat
        } else {
            selectedHour = 12
            selectedDuration = 1
            showsWeekends = true
            showsMarketSessions = true
            hourFormat = .mixed
        }
    }

    var homeLocation: BuddyLocation {
        locations.first(where: \.isHome) ?? locations.first ?? .london
    }

    var homeTimeZone: TimeZone {
        homeLocation.timeZone
    }

    var boardStart: Date {
        startOfDay(for: selectedDate, in: homeTimeZone)
    }

    var selectedStart: Date {
        instant(forHourOffset: selectedHour)
    }

    var shareText: String {
        MeetingFormatter.text(
            start: selectedStart,
            durationHours: selectedDuration,
            locations: locations
        )
    }

    func instant(forHourOffset hour: Int) -> Date {
        boardStart.addingTimeInterval(TimeInterval(hour * 3_600))
    }

    func select(hour: Int) {
        selectedHour = min(max(hour, 0), 23)
    }

    func previousDay() {
        shiftDay(by: -1)
    }

    func nextDay() {
        shiftDay(by: 1)
    }

    func goToToday() {
        selectedDate = .now
    }

    func shiftDay(by amount: Int) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = homeTimeZone
        selectedDate = calendar.date(byAdding: .day, value: amount, to: selectedDate) ?? selectedDate
    }

    func addLocation(from candidate: TimeZoneCandidate) {
        guard !locations.contains(where: { $0.timeZoneIdentifier == candidate.identifier }) else {
            return
        }

        locations.append(BuddyLocation(name: candidate.city, timeZoneIdentifier: candidate.identifier))
    }

    func removeLocations(at offsets: IndexSet) {
        locations.remove(atOffsets: offsets)
        locations = TimeBuddyStore.ensureSingleHome(locations)
    }

    func moveLocations(from source: IndexSet, to destination: Int) {
        locations.move(fromOffsets: source, toOffset: destination)
    }

    func rename(_ location: BuddyLocation, to name: String) {
        guard let index = locations.firstIndex(where: { $0.id == location.id }) else {
            return
        }

        locations[index].name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if locations[index].name.isEmpty {
            locations[index].name = TimeZoneCatalog.cityName(for: locations[index].timeZoneIdentifier)
        }
    }

    func markHome(_ location: BuddyLocation) {
        for index in locations.indices {
            locations[index].isHome = locations[index].id == location.id
        }
    }

    func isWeekend(_ date: Date, in timeZone: TimeZone) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.isDateInWeekend(date)
    }

    func localDateLabel(for date: Date, in timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE d"
        formatter.timeZone = timeZone
        return formatter.string(from: date)
    }

    private func startOfDay(for date: Date, in timeZone: TimeZone) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return calendar.date(from: components) ?? date
    }

    private func saveLocations() {
        guard let data = try? JSONEncoder().encode(locations) else {
            return
        }

        defaults.set(data, forKey: locationKey)
    }

    private func savePreferences() {
        let preferences = Preferences(
            selectedHour: selectedHour,
            selectedDuration: selectedDuration,
            showsWeekends: showsWeekends,
            showsMarketSessions: showsMarketSessions,
            hourFormat: hourFormat
        )

        guard let data = try? JSONEncoder().encode(preferences) else {
            return
        }

        defaults.set(data, forKey: preferencesKey)
    }

    private static func defaultLocations() -> [BuddyLocation] {
        let current = TimeZone.current.identifier
        let currentLocation = BuddyLocation(
            name: TimeZoneCatalog.cityName(for: current),
            timeZoneIdentifier: current,
            isHome: true
        )

        let defaults: [BuddyLocation] = [
            currentLocation,
            .london,
            .newYork,
            .sanFrancisco,
            .tokyo
        ]

        var seen = Set<String>()
        return defaults.compactMap { location in
            guard !seen.contains(location.timeZoneIdentifier) else {
                return nil
            }

            seen.insert(location.timeZoneIdentifier)
            var copy = location
            copy.isHome = location.timeZoneIdentifier == current
            return copy
        }
    }

    private static func ensureSingleHome(_ locations: [BuddyLocation]) -> [BuddyLocation] {
        guard !locations.isEmpty else {
            return defaultLocations()
        }

        var output = locations
        let homeIndex = output.firstIndex(where: \.isHome) ?? output.startIndex

        for index in output.indices {
            output[index].isHome = index == homeIndex
        }

        return output
    }
}

private struct Preferences: Codable {
    var selectedHour: Int
    var selectedDuration: Int
    var showsWeekends: Bool
    var showsMarketSessions: Bool
    var hourFormat: HourFormat
}

extension TimeBuddyStore {
    static var preview: TimeBuddyStore {
        let defaults = UserDefaults(suiteName: "mytimebuddy.preview") ?? .standard
        defaults.removeObject(forKey: "mytimebuddy.locations")
        defaults.removeObject(forKey: "mytimebuddy.preferences")
        let store = TimeBuddyStore(defaults: defaults)
        store.locations = [.london, .newYork, .sanFrancisco, .tokyo]
        store.selectedHour = 12
        store.selectedDuration = 2
        return store
    }
}
