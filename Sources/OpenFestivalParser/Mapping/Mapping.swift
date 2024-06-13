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

enum Validation: Error {
    case stage(Stage)
    case generic
    case schedule(ScheduleError)


    enum Stage: Error {
        case generic
    }

    enum ScheduleError: Error {
        case daySchedule(DayScheduleError)
    }
}

struct EventMapper: ValidatedMapper {
    typealias From = EventDTO
    typealias To = Event
    typealias ToError = Validation

    func map(_ dto: EventDTO) -> Output {
        zip(
            StagesMapper().map(dto.stages).mapErrors { Validation.stage($0) },
            ScheduleMapper().map(dto.schedule).mapErrors { Validation.schedule($0) },
            TimeZoneMapper().map(dto.eventInfo.timeZone).mapErrors { _ in .generic }
        )
        .map { stages, schedule, timeZone in
            Event(
                id: "TODO",
                name: dto.eventInfo.name,
                timeZone: timeZone,
                stages: stages,
                schedule: schedule
            )
        }
    }
}



struct StagesMapper: ValidatedMapper {
    typealias From = [StageDTO]
    typealias To = IdentifiedArrayOf<Event.Stage>
    typealias ToError = Validation.Stage

    func map(_ dtos: [StageDTO]) -> Output {
        .valid(
            IdentifiedArray(
                uniqueElements: dtos.map {
                    Event.Stage(
                        id: Tagged($0.name),
                        name: $0.name,
                        iconImageURL: $0.imageURL
                    )
                }
            )
        )
    }
}

struct ScheduleMapper: ValidatedMapper {
    typealias From = EventDTO.Schedule
    typealias To = Event.Schedule
    typealias ToError = Validation.ScheduleError

    func map(_ dto: EventDTO.Schedule) -> Output {
        let dayScheduleMapper = DayScheduleMapper()

       return dto.daySchedules
            .map { dayScheduleMapper.map($0) }
            .sequence()
            .map { Event.Schedule(days: $0) }
            .mapErrors { .daySchedule($0) }
    }
}



struct TimeZoneMapper: ValidatedMapper {
    typealias From = String?
    typealias To = TimeZone
    typealias ToError = Error

    func map(_ dto: String?) -> Output {
        @Dependency(\.timeZone) var timeZone

        return .valid(
            dto.flatMap(TimeZone.init(identifier:))
            ?? dto.flatMap(TimeZone.init(abbreviation:))
            ?? timeZone
        )
    }
}

