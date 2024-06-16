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

/*
 This is decoding a whole file, so the DTO should have access to the Date, whether encoded in the file or in the file title
 */
struct DayScheduleMapper: ValidatedMapper {
    typealias From = (fileName: String, body: EventDTO.DaySchedule)
    typealias To = Event.Schedule.Day
    typealias ToError = Validation.ScheduleError.DayScheduleError

    func map(_ fileContents: From) -> Output {
        fileContents.body
            .performances
            .mapValues(\.toStageDaySchedule)
            .sequence()
            .map { // [String: [StagelessPerformance] -> [Stage.ID: IdentifiedArrayOf<Performance>]]
                $0.reduce(into: [:]) { (
                    partialResult: inout [Event.Stage.ID : [Event.Performance]],
                    tuple: (key: String, value: [StagelessPerformance])
                ) in
                    let stageID: Event.Stage.ID = .init(tuple.key)

                    partialResult[stageID] = tuple.value.map {
                        $0.toPerformance(at: stageID, on: fileContents.body.date)
                    }
                }
            }
            .map {
                Event.Schedule.Day(
                    id: .init(fileContents.fileName),
                    date: fileContents.body.date,
                    customTitle: fileContents.body.customTitle,
                    performances: $0
                )
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


