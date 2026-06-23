// SPDX-License-Identifier: AGPL-3.0-only
// SPDX-FileCopyrightText: 2026 Steve Clarke <stephenlclarke@mac.com> - https://xyzzy.tools

import Foundation
@testable import MyTimeBuddy
import Testing

@MainActor
struct TimeBuddyStoreTests {
    @Test
    func hourConversionAlignsLocationsByInstant() throws {
        let store = makeStore()
        store.locations = [.london, .newYork]
        let london = try #require(TimeZone(identifier: "Europe/London"))
        store.selectedDate = date(year: 2026, month: 6, day: 22, timeZone: london)

        let instant = store.instant(forHourOffset: 12)
        var newYorkCalendar = Calendar(identifier: .gregorian)
        newYorkCalendar.timeZone = try #require(TimeZone(identifier: "America/New_York"))

        #expect(newYorkCalendar.component(.hour, from: instant) == 7)
    }

    @Test
    func weekendDetectionUsesLocationTimeZone() throws {
        let store = makeStore()
        let london = try #require(TimeZone(identifier: "Europe/London"))
        let saturday = date(year: 2026, month: 6, day: 20, timeZone: london)

        #expect(store.isWeekend(saturday, in: london))
    }

    @Test
    func searchFindsTimeZonesByCity() {
        let results = TimeZoneCatalog.search("Kathmandu")

        #expect(results.contains { $0.identifier == "Asia/Kathmandu" })
    }

    @Test
    func shareTextIncludesAllLocations() throws {
        let store = makeStore()
        store.locations = [.london, .newYork]
        let london = try #require(TimeZone(identifier: "Europe/London"))
        store.selectedDate = date(year: 2026, month: 6, day: 22, timeZone: london)
        store.selectedHour = 12
        store.selectedDuration = 2

        let shareText = store.shareText

        #expect(shareText.contains("London:"))
        #expect(shareText.contains("New York:"))
        #expect(shareText.contains("Duration: 2h"))
    }

    @Test
    func hourFormatsResolveExpectedLabels() throws {
        let london = try #require(TimeZone(identifier: "Europe/London"))
        let newYork = try #require(TimeZone(identifier: "America/New_York"))
        let tokyo = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let noon = date(year: 2026, month: 1, day: 12, hour: 12, timeZone: london)
        let midnight = date(year: 2026, month: 1, day: 12, hour: 0, timeZone: london)

        #expect(HourFormat.twelve.id == "twelve")
        #expect(HourFormat.twelve.title == "12h")
        #expect(HourFormat.twentyFour.title == "24h")
        #expect(HourFormat.mixed.title == "Mixed")
        #expect(HourFormat.twelve.label(for: noon, in: london) == HourLabel(value: "12", suffix: "pm"))
        #expect(HourFormat.twelve.label(for: midnight, in: london) == HourLabel(value: "12", suffix: "am"))
        #expect(HourFormat.twentyFour.label(for: midnight, in: london) == HourLabel(value: "00", suffix: ""))
        #expect(HourFormat.mixed.label(for: noon, in: newYork) == HourLabel(value: "7", suffix: "am"))
        #expect(HourFormat.mixed.label(for: noon, in: tokyo) == HourLabel(value: "21", suffix: ""))
    }

    @Test
    func marketSessionSegmentsClipToVisibleBoard() throws {
        let london = try #require(TimeZone(identifier: "Europe/London"))
        let boardStart = date(year: 2026, month: 6, day: 22, timeZone: london)
        let session = MarketSession(name: "London FX", timeZoneIdentifier: london.identifier, startHour: 8, endHour: 17)
        let partial = MarketSession(name: "Early FX", timeZoneIdentifier: london.identifier, startHour: -2, endHour: 3)

        #expect(session.id == "London FX")
        #expect(session.timeZone.identifier == london.identifier)
        #expect(session.timelineSegments(boardStart: boardStart) == [8.0 ... 17.0])
        #expect(partial.timelineSegments(boardStart: boardStart, hoursVisible: 4) == [0.0 ... 3.0])
        #expect(MarketSession.fxDefaults.map(\.name).contains("Tokyo FX"))
    }

    @Test
    func timeZoneCandidateFormattingAndMatching() throws {
        let kathmandu = TimeZoneCandidate(identifier: "Asia/Kathmandu", city: "Kathmandu", region: "Asia")
        let newYork = TimeZoneCandidate(identifier: "America/New_York", city: "New York", region: "America")
        let invalid = TimeZoneCandidate(identifier: "Not/AZone", city: "Nowhere", region: "Invalid")
        let winter = try date(year: 2026, month: 1, day: 12, timeZone: #require(TimeZone(identifier: "UTC")))

        #expect(kathmandu.id == "Asia/Kathmandu")
        #expect(kathmandu.offsetDescription(on: winter) == "GMT+5:45")
        #expect(newYork.offsetDescription(on: winter) == "GMT-5")
        #expect(invalid.offsetDescription(on: winter) == "GMT")
        #expect(kathmandu.matches(""))
        #expect(kathmandu.matches("kath"))
        #expect(kathmandu.matches("asia"))
        #expect(kathmandu.matches("Asia/Kathmandu"))
        #expect(!kathmandu.matches("london"))
    }

    @Test
    func timeZoneCatalogHelpersAndSearchLimits() {
        let limited = TimeZoneCatalog.search("", limit: 3)
        let kathmandu = TimeZoneCatalog.search("Kathmandu")

        #expect(limited.count == 3)
        #expect(kathmandu.contains { $0.identifier == "Asia/Kathmandu" })
        #expect(TimeZoneCatalog.cityName(for: "America/Los_Angeles") == "Los Angeles")
        #expect(TimeZoneCatalog.cityName(for: "UTC") == "UTC")
        #expect(TimeZoneCatalog.regionName(for: "America/Argentina/Buenos_Aires") == "America / Argentina")
        #expect(TimeZoneCatalog.regionName(for: "UTC") == "Time zone")
    }

    @Test
    func storeSelectionNavigationAndLabels() throws {
        let store = makeStore()
        let london = try #require(TimeZone(identifier: "Europe/London"))
        store.locations = [.london]
        store.selectedDate = date(year: 2026, month: 6, day: 22, timeZone: london)

        store.select(hour: -4)
        #expect(store.selectedHour == 0)
        store.select(hour: 30)
        #expect(store.selectedHour == 23)
        #expect(store.localDateLabel(for: store.selectedDate, in: london) == "Mon 22")

        store.previousDay()
        #expect(store.localDateLabel(for: store.selectedDate, in: london) == "Sun 21")
        store.nextDay()
        #expect(store.localDateLabel(for: store.selectedDate, in: london) == "Mon 22")

        store.goToToday()
        #expect(abs(store.selectedDate.timeIntervalSinceNow) < 5)
    }

    @Test
    func storeLocationMutationsKeepSingleHome() throws {
        let store = makeStore()
        store.locations = [.london, .newYork, .tokyo]
        let kathmandu = TimeZoneCandidate(identifier: "Asia/Kathmandu", city: "Kathmandu", region: "Asia")

        store.addLocation(from: TimeZoneCandidate(identifier: "America/New_York", city: "New York", region: "America"))
        #expect(store.locations.count == 3)

        store.addLocation(from: kathmandu)
        #expect(store.locations.map(\.name).contains("Kathmandu"))

        let newYork = try #require(store.locations.first { $0.timeZoneIdentifier == "America/New_York" })
        store.rename(newYork, to: "  NYC  ")
        #expect(store.locations.contains { $0.name == "NYC" })

        let renamed = try #require(store.locations.first { $0.timeZoneIdentifier == "America/New_York" })
        store.rename(renamed, to: "   ")
        #expect(store.locations.contains { $0.name == "New York" })

        store.rename(BuddyLocation(name: "Missing", timeZoneIdentifier: "UTC"), to: "Ignored")
        store.markHome(renamed)
        #expect(store.homeLocation.timeZoneIdentifier == "America/New_York")
        #expect(store.locations.filter(\.isHome).count == 1)

        store.moveLocations(from: IndexSet(integer: 0), to: store.locations.count)
        #expect(store.locations.last?.timeZoneIdentifier == "Europe/London")

        store.removeLocations(at: IndexSet([0, 99]))
        #expect(store.locations.filter(\.isHome).count == 1)

        store.removeLocations(at: IndexSet(integersIn: 0 ..< store.locations.count))
        #expect(!store.locations.isEmpty)
        #expect(store.locations.filter(\.isHome).count == 1)
    }

    @Test
    func storeLoadsPersistedLocationsAndPreferences() throws {
        let suite = "mytimebuddy.tests.persisted.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        let savedLocations = [
            BuddyLocation(name: "First", timeZoneIdentifier: "Europe/London", isHome: true),
            BuddyLocation(name: "Second", timeZoneIdentifier: "America/New_York", isHome: true)
        ]
        let preferences = StoredPreferences(
            selectedHour: 9,
            selectedDuration: 3,
            showsWeekends: false,
            showsMarketSessions: false,
            hourFormat: .twentyFour
        )
        try defaults.set(JSONEncoder().encode(savedLocations), forKey: "mytimebuddy.locations")
        try defaults.set(JSONEncoder().encode(preferences), forKey: "mytimebuddy.preferences")

        let store = TimeBuddyStore(defaults: defaults)
        #expect(store.locations.map(\.name) == ["First", "Second"])
        #expect(store.locations.filter(\.isHome).count == 1)
        #expect(store.homeLocation.name == "First")
        #expect(store.selectedHour == 9)
        #expect(store.selectedDuration == 3)
        #expect(!store.showsWeekends)
        #expect(!store.showsMarketSessions)
        #expect(store.hourFormat == .twentyFour)

        store.selectedHour = 18
        store.selectedDuration = 4
        store.showsWeekends = true
        store.showsMarketSessions = true
        store.hourFormat = .mixed

        let reloaded = TimeBuddyStore(defaults: defaults)
        #expect(reloaded.selectedHour == 18)
        #expect(reloaded.selectedDuration == 4)
        #expect(reloaded.showsWeekends)
        #expect(reloaded.showsMarketSessions)
        #expect(reloaded.hourFormat == .mixed)
    }

    @Test
    func storeFallsBackFromEmptyLocationsAndInvalidPreferences() throws {
        let suite = "mytimebuddy.tests.invalid.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        try defaults.set(JSONEncoder().encode([BuddyLocation]()), forKey: "mytimebuddy.locations")
        defaults.set(Data("not-json".utf8), forKey: "mytimebuddy.preferences")

        let store = TimeBuddyStore(defaults: defaults)

        #expect(!store.locations.isEmpty)
        #expect(store.locations.filter(\.isHome).count == 1)
        #expect(store.selectedHour == 12)
        #expect(store.selectedDuration == 1)
        #expect(store.showsWeekends)
        #expect(store.showsMarketSessions)
        #expect(store.hourFormat == .mixed)
    }

    private func makeStore() -> TimeBuddyStore {
        let suite = "mytimebuddy.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return TimeBuddyStore(defaults: defaults)
    }

    private func date(year: Int, month: Int, day: Int, hour: Int = 0, timeZone: TimeZone) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    private struct StoredPreferences: Codable {
        var selectedHour: Int
        var selectedDuration: Int
        var showsWeekends: Bool
        var showsMarketSessions: Bool
        var hourFormat: HourFormat
    }
}
