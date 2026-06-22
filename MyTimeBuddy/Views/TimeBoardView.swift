// SPDX-License-Identifier: AGPL-3.0-only
// SPDX-FileCopyrightText: 2026 Steve Clarke <stephenlclarke@mac.com> - https://xyzzy.tools

import SwiftUI
import UIKit

struct TimeBoardView: View {
    @Environment(TimeBuddyStore.self) private var store
    @Binding var sheet: BoardSheet?

    private let tileWidth: CGFloat = 54
    private let tileHeight: CGFloat = 46
    private let labelWidth: CGFloat = 120

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                DateStripView()
                    .padding(.horizontal)

                SelectionSummaryView()
                    .padding(.horizontal)

                timeline

                Button {
                    sheet = .addLocation
                } label: {
                    Label("Add Location", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
            }
            .padding(.vertical, 16)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var timeline: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 8) {
                HourHeaderRow(
                    store: store,
                    labelWidth: labelWidth,
                    tileWidth: tileWidth
                )

                if store.showsMarketSessions {
                    MarketSessionsView(
                        store: store,
                        labelWidth: labelWidth,
                        tileWidth: tileWidth
                    )
                }

                ForEach(store.locations) { location in
                    LocationHourRow(
                        location: location,
                        store: store,
                        labelWidth: labelWidth,
                        tileWidth: tileWidth,
                        tileHeight: tileHeight
                    )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .padding(.horizontal)
        }
    }
}

private struct DateStripView: View {
    @Environment(TimeBuddyStore.self) private var store

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Button {
                    store.previousDay()
                } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Previous day")

                Button {
                    store.goToToday()
                } label: {
                    Label("Today", systemImage: "calendar")
                }
                .buttonStyle(.bordered)

                Button {
                    store.nextDay()
                } label: {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Next day")

                Spacer()
            }

            HStack(spacing: 8) {
                ForEach(-2...4, id: \.self) { offset in
                    DayPill(offset: offset)
                }
            }
        }
    }
}

private struct DayPill: View {
    @Environment(TimeBuddyStore.self) private var store
    let offset: Int

    var body: some View {
        let date = shiftedDate
        let isSelected = Calendar.current.isDate(date, inSameDayAs: store.selectedDate)

        Button {
            store.selectedDate = date
        } label: {
            VStack(spacing: 2) {
                Text(weekday)
                    .font(.caption2.weight(.semibold))
                Text(day)
                    .font(.caption.monospacedDigit())
            }
            .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .background(isSelected ? Color.accentColor.opacity(0.18) : Color(.secondarySystemGroupedBackground))
        .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var shiftedDate: Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = store.homeTimeZone
        return calendar.date(byAdding: .day, value: offset, to: store.selectedDate) ?? store.selectedDate
    }

    private var weekday: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.timeZone = store.homeTimeZone
        return formatter.string(from: shiftedDate).uppercased()
    }

    private var day: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        formatter.timeZone = store.homeTimeZone
        return formatter.string(from: shiftedDate)
    }
}

private struct SelectionSummaryView: View {
    @Environment(TimeBuddyStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Selected Window")
                        .font(.headline)
                    Text("\(store.selectedDuration)h from \(store.homeLocation.name) \(store.hourFormat.label(for: store.selectedStart, in: store.homeTimeZone).value)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Stepper(value: durationBinding, in: 1...12) {
                    EmptyView()
                }
                .labelsHidden()
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                ForEach(store.locations.prefix(4)) { location in
                    HStack {
                        Text(location.name)
                            .font(.caption.weight(.semibold))
                        Spacer()
                        Text(selectionRange(for: location))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            }

            HStack {
                ShareLink(item: store.shareText) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)

                Button {
                    UIPasteboard.general.string = store.shareText
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)

                Spacer()
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var durationBinding: Binding<Int> {
        Binding(
            get: { store.selectedDuration },
            set: { store.selectedDuration = $0 }
        )
    }

    private func selectionRange(for location: BuddyLocation) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE d, h:mm a"
        formatter.timeZone = location.timeZone
        let end = store.selectedStart.addingTimeInterval(TimeInterval(store.selectedDuration * 3_600))
        return "\(formatter.string(from: store.selectedStart)) - \(formatter.string(from: end))"
    }
}

private struct HourHeaderRow: View {
    let store: TimeBuddyStore
    let labelWidth: CGFloat
    let tileWidth: CGFloat

    var body: some View {
        HStack(spacing: 0) {
            Text(store.homeLocation.name)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: labelWidth, alignment: .leading)

            ForEach(0..<24, id: \.self) { hour in
                let instant = store.instant(forHourOffset: hour)
                let label = store.hourFormat.label(for: instant, in: store.homeTimeZone)

                VStack(spacing: 1) {
                    Text(label.value)
                        .font(.caption.weight(.semibold).monospacedDigit())
                    if !label.suffix.isEmpty {
                        Text(label.suffix)
                            .font(.caption2)
                    }
                }
                .foregroundStyle(hour == store.selectedHour ? Color.accentColor : Color.secondary)
                .frame(width: tileWidth, height: 34)
            }
        }
    }
}

private struct MarketSessionsView: View {
    let store: TimeBuddyStore
    let labelWidth: CGFloat
    let tileWidth: CGFloat

    var body: some View {
        HStack(spacing: 0) {
            Text("Markets")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: labelWidth, alignment: .leading)

            ZStack(alignment: .leading) {
                ForEach(MarketSession.fxDefaults) { session in
                    ForEach(session.timelineSegments(boardStart: store.boardStart), id: \.self) { range in
                        sessionBand(session, range: range)
                    }
                }
            }
            .frame(width: tileWidth * 24, height: 64)
        }
    }

    private func sessionBand(_ session: MarketSession, range: ClosedRange<Double>) -> some View {
        let width = CGFloat(range.upperBound - range.lowerBound) * tileWidth
        let x = CGFloat(range.lowerBound) * tileWidth
        let palette = color(for: session.name)

        return Text(session.name)
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 6)
            .frame(width: max(width, 44), height: 18)
            .background(palette)
            .clipShape(Capsule())
            .offset(x: x, y: verticalOffset(for: session.name))
    }

    private func color(for name: String) -> Color {
        switch name {
        case "Sydney FX":
            .teal
        case "Tokyo FX":
            .mint
        case "London FX":
            .green
        default:
            .blue
        }
    }

    private func verticalOffset(for name: String) -> CGFloat {
        switch name {
        case "Sydney FX":
            -22
        case "Tokyo FX":
            -7
        case "London FX":
            8
        default:
            23
        }
    }
}

private struct LocationHourRow: View {
    let location: BuddyLocation
    let store: TimeBuddyStore
    let labelWidth: CGFloat
    let tileWidth: CGFloat
    let tileHeight: CGFloat

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    if location.isHome {
                        Image(systemName: "house.fill")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }

                    Text(location.name)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                }

                Text(location.abbreviation)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: labelWidth, alignment: .leading)

            ForEach(0..<24, id: \.self) { hour in
                let instant = store.instant(forHourOffset: hour)
                let label = store.hourFormat.label(for: instant, in: location.timeZone)

                Button {
                    store.select(hour: hour)
                } label: {
                    VStack(spacing: 1) {
                        Text(label.value)
                            .font(.subheadline.weight(.semibold).monospacedDigit())
                        if !label.suffix.isEmpty {
                            Text(label.suffix)
                                .font(.caption2)
                        }
                        Text(store.localDateLabel(for: instant, in: location.timeZone))
                            .font(.caption2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                    }
                    .frame(width: tileWidth, height: tileHeight)
                    .background(tileColor(for: instant))
                    .overlay(selectionOverlay(for: hour))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(location.name), \(label.value) \(label.suffix)")
            }
        }
    }

    private func tileColor(for instant: Date) -> Color {
        if store.showsWeekends && store.isWeekend(instant, in: location.timeZone) {
            return Color.pink.opacity(0.14)
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = location.timeZone
        let hour = calendar.component(.hour, from: instant)

        switch hour {
        case 9..<18:
            return Color.yellow.opacity(0.2)
        case 7..<9, 18..<21:
            return Color.cyan.opacity(0.16)
        default:
            return Color.indigo.opacity(0.18)
        }
    }

    private func selectionOverlay(for hour: Int) -> some View {
        let selectedRange = store.selectedHour..<(store.selectedHour + store.selectedDuration)
        let isSelected = selectedRange.contains(hour)

        return RoundedRectangle(cornerRadius: 6, style: .continuous)
            .stroke(isSelected ? Color.accentColor : Color(.separator), lineWidth: isSelected ? 2 : 0.5)
            .padding(1)
    }
}

#Preview {
    NavigationStack {
        TimeBoardView(sheet: .constant(nil))
            .environment(TimeBuddyStore.preview)
    }
}
