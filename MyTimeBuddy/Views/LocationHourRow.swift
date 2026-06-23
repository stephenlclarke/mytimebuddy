// SPDX-License-Identifier: AGPL-3.0-only
// SPDX-FileCopyrightText: 2026 Steve Clarke <stephenlclarke@mac.com> - https://xyzzy.tools

import SwiftUI

struct LocationHourRow: View {
    let location: BuddyLocation
    let store: TimeBuddyStore
    let labelWidth: CGFloat
    let tileWidth: CGFloat
    let tileHeight: CGFloat

    var body: some View {
        HStack(spacing: 0) {
            locationLabel

            ForEach(0 ..< 24, id: \.self) { hour in
                hourButton(hour)
            }
        }
    }

    private var locationLabel: some View {
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
    }

    private func hourButton(_ hour: Int) -> some View {
        let instant = store.instant(forHourOffset: hour)
        let label = store.hourFormat.label(for: instant, in: location.timeZone)

        return Button {
            store.select(hour: hour)
        } label: {
            hourCell(instant: instant, label: label)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(location.name), \(label.value) \(label.suffix)")
    }

    private func hourCell(instant: Date, label: HourLabel) -> some View {
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
        .overlay(selectionOverlay(for: instant))
    }

    private func tileColor(for instant: Date) -> Color {
        if store.showsWeekends, store.isWeekend(instant, in: location.timeZone) {
            return Color.pink.opacity(0.14)
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = location.timeZone
        let hour = calendar.component(.hour, from: instant)

        switch hour {
        case 9 ..< 18:
            return Color.yellow.opacity(0.2)
        case 7 ..< 9, 18 ..< 21:
            return Color.cyan.opacity(0.16)
        default:
            return Color.indigo.opacity(0.18)
        }
    }

    private func selectionOverlay(for instant: Date) -> some View {
        let hourOffset = Int(instant.timeIntervalSince(store.boardStart) / 3600)
        let selectedRange = store.selectedHour ..< (store.selectedHour + store.selectedDuration)
        let isSelected = selectedRange.contains(hourOffset)

        return RoundedRectangle(cornerRadius: 6, style: .continuous)
            .stroke(isSelected ? Color.accentColor : Color(.separator), lineWidth: isSelected ? 2 : 0.5)
            .padding(1)
    }
}
