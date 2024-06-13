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
    Event.DaySchedule,
    Validation.ScheduleError.StageDayScheduleError
>

extension Validation.ScheduleError {
    enum DayScheduleError: Error {
        case scheduleDayError(StageDayScheduleError)
    }
}

/*
 This is decoding a whole file, so the DTO should have access to the Date, whether encoded in the file or in the file title
 */
struct DayScheduleMapper: ValidatedMapper {
    typealias From = EventDTO.DaySchedule
    typealias To = [Event.Stage.ID: IdentifiedArrayOf<Event.Performance>]
    typealias ToError = Validation.ScheduleError.DayScheduleError

    func map(_ value: EventDTO.DaySchedule) -> Output {
        value
            .performances
            .mapValues(\.toStageDaySchedule)
            .sequence()
            .map { // [String: [StagelessPerformance] -> [Stage.ID: IdentifiedArrayOf<Performance>]]
                $0.reduce(into: [:]) { (partialResult: inout Event.DaySchedule, tuple: (key: String, value: [StagelessPerformance])) in
                    let stageID = Event.Stage.ID(rawValue: tuple.key)



                    partialResult[stageID] = IdentifiedArray(
                        uniqueElements: tuple.value.map {
                            $0.toPerformance(at: stageID, on: value.date)
                        }
                    )
                }
            }
            .mapErrors { ToError.scheduleDayError($0) }
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


import Dependencies
extension CalendarDate {
    func atTime(_ time: ScheduleTime) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = time.hour % 24
        components.minute = time.minute
        components.second = 0
        @Dependency(\.calendar) var calendar
        var date = calendar.date(from: components)!

        if time.hour >= 24 {
            date.addTimeInterval(24 * 60 * 60)
        }

        return date
    }
}

