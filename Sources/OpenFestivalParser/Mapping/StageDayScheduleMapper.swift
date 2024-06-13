//
//  File.swift
//
//
//  Created by Woodrow Melling on 6/3/24.
//

import Foundation
import OpenFestivalModels
import Validated
import Collections


extension Validation.ScheduleError {
    enum StageDayScheduleError: Equatable, Error {
        case unimplemented
        case performanceError(Validation.ScheduleError.PerformanceError)
        case cannotDetermineEndTimeForPerformance
        case endTimeBeforeStartTime(ScheduleTime, ScheduleTime)
        case overlappingPerformances

        var localizedDescription: String {
            switch self {
            case .unimplemented:
                return "This feature is not yet implemented"
            case .performanceError(let error):
                return error.localizedDescription
            case .cannotDetermineEndTimeForPerformance:
                return "Cannot determine end time for performance"
            case .endTimeBeforeStartTime(let startTime, let endTime):
                return "End time \(endTime) is before start time \(startTime)"
            case .overlappingPerformances:
                return "Performances are overlapping"
            }
        }
    }
}

struct StagelessPerformance: Equatable {
    var customTitle: String?
    var artistIDs: OrderedSet<Event.Artist.ID>
    var startTime: ScheduleTime
    var endTime: ScheduleTime
}

typealias ValidatedStageDaySchedule = Validated<
    [StagelessPerformance],
    Validation.ScheduleError.StageDayScheduleError
>

extension Collection<PerformanceDTO> {

    var toStageDaySchedule: ValidatedStageDaySchedule {
        self
            .map(\.toPartialPerformance)
            .sequence()
            .mapErrors { Validation.ScheduleError.StageDayScheduleError.performanceError($0) }
            .flatMapish { determineEndTimes(for: $0) }
    }

    private func determineEndTimes(for partialPerformances: [TimelessStagelessPerformance]) -> ValidatedStageDaySchedule {
        var schedule: [StagelessPerformance] = []
        var scheduleStartTime: ScheduleTime?

        for (index, performance) in partialPerformances.enumerated() {
            var startTime = performance.startTime
            var endTime: ScheduleTime

            // End times can be manually set
            if let staticEndTime = performance.endTime {
                endTime = staticEndTime

                // If they aren't, find the next performance, and make the endtime but up against it
            } else if let nextPerformance = partialPerformances[safe: index + 1] {
                endTime = nextPerformance.startTime

                // If there isn't any performances after this, we can't determine the endtime
            } else {
                return .error(Validation.ScheduleError.StageDayScheduleError.cannotDetermineEndTimeForPerformance)
            }

            if let scheduleStartTime {
                if startTime < scheduleStartTime {
                    startTime.hour += 24
                }

                if endTime < scheduleStartTime {
                    endTime.hour += 24
                }
            } else {
                scheduleStartTime = startTime
                if endTime < startTime {
                    endTime.hour += 24
                }
            }

            schedule.append(StagelessPerformance(
                customTitle: performance.customTitle,
                artistIDs: performance.artistIDs,
                startTime: startTime,
                endTime: endTime
            ))
        }

        for (index, performance) in schedule.enumerated() {
            guard let nextPerformance = schedule[safe: index + 1]
            else { continue }

            guard performance.endTime <= nextPerformance.startTime
            else { return .error(.overlappingPerformances) }

            guard performance.startTime < performance.endTime
            else { return .error(.endTimeBeforeStartTime(performance.startTime, performance.endTime))}
        }

        return .valid(schedule)
    }
}
