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
    enum StageDayScheduleError: Equatable {
        case unimplemented
        case performanceError(Validation.ScheduleError.PerformanceError)
        case cannotDetermineEndTimeForPerformance
        case overlappingPerformances
    }
}

struct StagelessPerformance: Equatable {
    var customTitle: String?
    var artistIDs: OrderedSet<Event.Artist.ID>
    var startTime: Date
    var endTime: Date
}

extension EventDTO.StageDaySchedule {
    typealias ValidatedStageDaySchedule = Validated<
        [StagelessPerformance],
        Validation.ScheduleError.StageDayScheduleError
    >
    var toStageDaySchedule: ValidatedStageDaySchedule {
        self
            .map(\.toPartialPerformance)
            .sequence()
            .mapErrors { Validation.ScheduleError.StageDayScheduleError.performanceError($0) }
            .flatMap { determineEndTimes(for: $0) }
    }

    private func determineEndTimes(for partialPerformances: [TimelessStagelessPerformance]) -> ValidatedStageDaySchedule {
        var schedule: [StagelessPerformance] = []

        for (index, performance) in partialPerformances.enumerated() {
            var endTime: Date

            // End times can be manually set
            if let staticEndTime = performance.endTime {

                // But they shouldn't overlap with the next set
                if let nextPerformance = partialPerformances[safe: index + 1],
                   nextPerformance.startTime < staticEndTime
                {
                    return .error(Validation.ScheduleError.StageDayScheduleError.overlappingPerformances)
                }

                endTime = staticEndTime

            // If they aren't, find the next performance, and make the endtime but up against it
            } else if let nextPerformance = partialPerformances[safe: index + 1] {
                endTime = nextPerformance.startTime

            // If there isn't any performances after this, we can't determine the endtime
            } else {
                return .error(Validation.ScheduleError.StageDayScheduleError.cannotDetermineEndTimeForPerformance)
            }

            schedule.append(StagelessPerformance(
                customTitle: performance.customTitle,
                artistIDs: performance.artistIDs,
                startTime: performance.startTime,
                endTime: endTime
            ))
        }
        return .valid(schedule)
    }
}



