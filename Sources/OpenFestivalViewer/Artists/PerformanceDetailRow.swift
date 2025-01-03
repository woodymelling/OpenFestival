//
//  File.swift
//
//
//  Created by Woodrow Melling on 6/15/24.
//

import Foundation
import SwiftUI
import OpenFestivalModels
import Dependencies

public struct PerformanceDetailRow: View {
    public init(for performance: Event.Performance) {
        self.performance = performance
    }

    var performance: Event.Performance

    var timeIntervalLabel: String {
        (performance.startTime..<performance.endTime)
            .formatted(.performanceTime)
    }

    public var body: some View {
        HStack(spacing: 10) {
            StagesIndicatorView(stageIDs: [performance.stageID])
                .frame(width: 5)

            StageIconView(stageID: performance.stageID)
                .frame(square: 60)

            switch performance.artistIDs.count {
            case 1:
                VStack(alignment: .leading) {
                    Text(timeIntervalLabel)

                    Text(performance.startTime, format: .daySegment)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

            default:
                VStack(alignment: .leading) {
                    Text(performance.title)

                    Text(timeIntervalLabel + " " + performance.startTime.formatted(.daySegment))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 5)
        .frame(height: 60)
    }
}

import ComposableArchitecture
extension Event.Performance {
    var title: String {
        @Shared(.event) var event

        func name(for artistReference: Event.Performance.ArtistReference) -> String {
            switch artistReference {
            case .known(let id): event.artists[id: id]?.name ?? id.uuidString
            case .anonymous(let name): name
            }
        }

        return if let customTitle {
            customTitle
        } else if artistIDs.count == 1, let artist = artistIDs.first {
            name(for: artist)

        } else {
            self.artistIDs.map { name(for: $0) }.joined(separator: ", ")
        }
    }
}

extension FormatStyle where Self == DaySegmentStyle {
    static var daySegment: DaySegmentStyle {
        DaySegmentStyle()
    }
}

struct DaySegmentStyle: FormatStyle {
    typealias FormatInput = Date
    typealias FormatOutput = String

    func format(_ value: Date) -> String {
        @Dependency(\.calendar) var calendar

        var date = value
        let hour = calendar.component(.hour, from: date)

        let timeOfDay: String

        guard hour >= 0 && hour < 24 else { return "failed to format" }

        if hour < 6 {
            timeOfDay = "Night"

            // If we're in the early saturday AM, people feel like it's actually friday night still,
            // so show the date as the day before to reduce confusion (I think, this should probably be tested)
            date = calendar.date(byAdding: .day, value: -1, to: date)!
        } else if hour > 6 && hour < 12 {
            timeOfDay = "Morning"
        } else if hour > 12 &&  hour < 17 {
            timeOfDay = "Afternoon"
        } else if hour > 17 && hour < 20 {
            timeOfDay = "Evening"
        } else {
            timeOfDay = "Night"
        }

        return "\(value.formatted(.dateTime.weekday(.wide))) \(timeOfDay)"
    }
}

extension FormatStyle where Self == PerformanceTimeStyle {
    static var performanceTime: PerformanceTimeStyle {
        PerformanceTimeStyle()
    }
}
struct PerformanceTimeStyle: FormatStyle {
    typealias FormatInput = Range<Date>
    typealias FormatOutput = String

    func format(_ value: Range<Date>) -> String {
        var timeFormat = Date.FormatStyle.dateTime.hour().minute()
        timeFormat.timeZone = NSTimeZone.default

        return "\(value.lowerBound.formatted(timeFormat)) - \(value.upperBound.formatted(timeFormat))"
    }

}


#Preview {
    List {
        PerformanceDetailRow(
            for: .init(
                id: Event.Performance.ID(UUID(0)),
                customTitle: nil,
                artistIDs: [.anonymous(name: "Farcaster")],
                startTime: .now,
                endTime: .now + 1.hours,
                stageID: Event.testival.stages.first!.id
            )
        )
    }
    .listStyle(.plain)
}
