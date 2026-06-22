// SPDX-License-Identifier: AGPL-3.0-only
// SPDX-FileCopyrightText: 2026 Steve Clarke <stephenlclarke@mac.com> - https://xyzzy.tools

import Foundation
import Testing
@testable import MyTimeBuddy

@MainActor
struct TimeBuddyStoreTests {
    @Test
    func testHourConversionAlignsLocationsByInstant() {
        let store = makeStore()
        store.locations = [.london, .newYork]
        store.selectedDate = date(year: 2026, month: 6, day: 22, timeZone: TimeZone(identifier: "Europe/London")!)

        let instant = store.instant(forHourOffset: 12)
        var newYorkCalendar = Calendar(identifier: .gregorian)
        newYorkCalendar.timeZone = TimeZone(identifier: "America/New_York")!

        #expect(newYorkCalendar.component(.hour, from: instant) == 7)
    }

    @Test
    func testWeekendDetectionUsesLocationTimeZone() {
        let store = makeStore()
        let london = TimeZone(identifier: "Europe/London")!
        let saturday = date(year: 2026, month: 6, day: 20, timeZone: london)

        #expect(store.isWeekend(saturday, in: london))
    }

    @Test
    func testSearchFindsTimeZonesByCity() {
        let results = TimeZoneCatalog.search("Kathmandu")

        #expect(results.contains { $0.identifier == "Asia/Kathmandu" })
    }

    @Test
    func testShareTextIncludesAllLocations() {
        let store = makeStore()
        store.locations = [.london, .newYork]
        store.selectedDate = date(year: 2026, month: 6, day: 22, timeZone: TimeZone(identifier: "Europe/London")!)
        store.selectedHour = 12
        store.selectedDuration = 2

        let shareText = store.shareText

        #expect(shareText.contains("London:"))
        #expect(shareText.contains("New York:"))
        #expect(shareText.contains("Duration: 2h"))
    }

    private func makeStore() -> TimeBuddyStore {
        let suite = "mytimebuddy.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return TimeBuddyStore(defaults: defaults)
    }

    private func date(year: Int, month: Int, day: Int, timeZone: TimeZone) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }
}
