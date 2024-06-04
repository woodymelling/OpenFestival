//
//  File.swift
//  
//
//  Created by Woodrow Melling on 5/29/24.
//

import Foundation
import Validated
import OpenFestivalModels
import Dependencies
import Collections
import Prelude

extension EventDTO {
    var extractedEvent: Validated<Event, Validation> {
        .error(.generic)
//        return zip(
//            self.extractedStages,
//            self.extractedArtists,
//            self.extractedSchedule
//        ).map { stages, artists, schedule in
//            Event(
//                id: Tagged(eventInfo.name),
//                name: eventInfo.name,
//                timeZone: self.extractedTimeZone,
//                stages: stages,
//                schedule: schedule
//            )
//        }
    }
}

enum Validation: Error {
    case schedule(ScheduleError)
    case stage(Stage)
    case generic

    enum ScheduleError: Error {
        case invalidScheduleDayName(String)
        case performance(PerformanceDTO, PerformanceError)

    }

    enum Stage: Error {

    }
}

fileprivate extension EventDTO {
    private var extractedTimeZone: TimeZone {
        @Dependency(\.timeZone) var timeZone

        return self.eventInfo.timeZone.flatMap(TimeZone.init(identifier:))
            ?? self.eventInfo.timeZone.flatMap(TimeZone.init(abbreviation:))
            ?? timeZone
    }

    private var extractedStages: Validated<Event.Stages, Validation.Stage> {
        .valid(
            IdentifiedArray(
                uniqueElements: stages.map {
                    Event.Stage(
                        id: Tagged($0.name),
                        name: $0.name,
                        iconImageURL: $0.imageURL
                    )
                }
            )
        )
    }

    private var extractedSchedule: Validated<Event.Schedule, Validation.ScheduleError> {
        var schedule: Event.Schedule = [:]

        for scheduleDay in self.schedule {
            guard let key = CalendarDate(scheduleDay.key)
            else { return .error(.invalidScheduleDayName(scheduleDay.key)) }


            var scheduleDayDict: Event.ScheduleDay = [:]

            for stageSchedule in scheduleDay.value {
//                let stageID = Event.Stage.ID(stageSchedule.key)
//                
//                scheduleDayDict[stageID] = IdentifiedArray(
//                    stageSchedule.value.map {
//                        Event.Performance(
//                            id: Event.Performance.ID("0"),
//                            startTime: <#T##Date#>,
//                            endTime: <#T##Date#>,
//                            artistIDs: <#T##OrderedSet<Event.Artist.ID>#>,
//                            stageID: <#T##Event.Stage.ID#>
//                        )
//                    }
//                )
            }
        }

        return .valid(schedule)
    }

    private var extractedArtists: Validated<IdentifiedArrayOf<Event.Artist>, Validation> {
        .valid([])
    }
}

