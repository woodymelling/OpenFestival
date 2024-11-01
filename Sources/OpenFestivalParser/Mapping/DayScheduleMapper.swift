//
//  File.swift
//
//
//  Created by Woodrow Melling on 6/11/24.
//

import Foundation
import OpenFestivalModels
import Validated

typealias ValidatedDaySchedule = Validated<
    Event.Schedule.Day,
    Validation.ScheduleError.StageDayScheduleError
>

extension Validation.ScheduleError {
    enum DayScheduleError: Error {
        case scheduleDayError(StageDayScheduleError)
    }
}


extension StagelessPerformance {
    func toPerformance(at stage: Event.Stage.ID, on day: CalendarDate?) -> Event.Performance {
        let artistIDsString = String(artistIDs.joined(separator: ","))
        let idString = "\(artistIDsString)-\(startTime)-\(stage)"

        let day = day ?? .today

        return Event.Performance(
            id: .init(idString),
            customTitle: customTitle,
            artistIDs: artistIDs,
            startTime: day.atTime(self.startTime),
            endTime: day.atTime(self.endTime),
            stageID: stage
        )
    }
}


protocol ValidatedMapper {
    associatedtype From
    associatedtype To
    associatedtype ToError: Error

    typealias Output = Validated<To, ToError>

    func map(_ from: From) -> Output
}


