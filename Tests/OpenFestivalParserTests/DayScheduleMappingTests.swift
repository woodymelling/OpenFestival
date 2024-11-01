//
//  File.swift
//  
//
//  Created by Woodrow Melling on 6/12/24.
//

import Foundation
import Testing
import OpenFestivalModels
@testable import OpenFestivalParser
import Dependencies
import FileTree
import DependenciesTestSupport
import CustomDump

fileprivate let day = CalendarDate(year: 2024, month: 6, day: 12)

@Suite(.dependency(\.calendar, .current))
struct DayScheduleConversionTests {

    @Test
    func multiStage() throws {
        let dto = FileContent(fileName: "2024-06-12", data: EventDTO.DaySchedule(
            date: CalendarDate(year: 2024, month: 6, day: 12),
            performances: [
                "Bass Haven": [
                    PerformanceDTO(
                        artist: "Sunspear",
                        time: "4:30 PM"
                    ),
                    PerformanceDTO(
                        artist: "Phantom Groove",
                        time: "6:30 PM"
                    ),
                    PerformanceDTO(
                        artist: "Caribou State",
                        time: "8:00 PM",
                        endTime: "9:30 PM"
                    )
                ],
                "Main Stage": [
                    PerformanceDTO(
                        artist: "Oaktrail",
                        time: "8:00 PM"
                    ),
                    PerformanceDTO(
                        artist: "Rhythmbox",
                        time: "10:00 PM",
                        endTime: "11:30 PM"
                    )
                ]
            ]
        ))
        let schedule = Event.Schedule.Day(
            id: .init("2024-06-12"),
            date: day,
            customTitle: nil,
            stageSchedules: [
                "Bass Haven": [
                    Event.Performance(
                        id: .init("Sunspear-16:30-Bass Haven"),
                        customTitle: nil,
                        artistIDs: ["Sunspear"],
                        startTime: day.atTime(ScheduleTime(hour: 16, minute: 30)!),
                        endTime: day.atTime(ScheduleTime(hour: 18, minute: 30)!),
                        stageID: Event.Stage.ID(rawValue: "Bass Haven")
                    ),
                    Event.Performance(
                        id: .init ("Phantom Groove-18:30-Bass Haven"),
                        customTitle: nil,
                        artistIDs: ["Phantom Groove"],
                        startTime: day.atTime(ScheduleTime(hour: 18, minute: 30)!),
                        endTime: day.atTime(ScheduleTime(hour: 20)!),
                        stageID: Event.Stage.ID(rawValue: "Bass Haven")
                    ),
                    Event.Performance(
                        id: .init("Caribou State-20:00-Bass Haven"),
                        customTitle: nil,
                        artistIDs: ["Caribou State"],
                        startTime: day.atTime(ScheduleTime(hour: 20)!),
                        endTime: day.atTime(ScheduleTime(hour: 21, minute: 30)!),
                        stageID: Event.Stage.ID(rawValue: "Bass Haven")
                    )
                ],
                "Main Stage": [
                    Event.Performance(
                        id: .init("Oaktrail-20:00-Main Stage"),
                        customTitle: nil,
                        artistIDs: ["Oaktrail"],
                        startTime: day.atTime(ScheduleTime(hour: 20)!),
                        endTime: day.atTime(ScheduleTime(hour: 22)!),
                        stageID: Event.Stage.ID(rawValue: "Main Stage")
                    ),
                    Event.Performance(
                        id: .init("Rhythmbox-22:00-Main Stage"),
                        customTitle: nil,
                        artistIDs: ["Rhythmbox"],
                        startTime: day.atTime(ScheduleTime(hour: 22)!),
                        endTime: day.atTime(ScheduleTime(hour: 23, minute: 30)!),
                        stageID: Event.Stage.ID(rawValue: "Main Stage")
                    )
                ]
            ]
        )
        let result = try ScheduleDayConversion().apply(dto)


        expectNoDifference(result, schedule)

        let roundTrip = try ScheduleDayConversion().unapply(result)
        expectNoDifference(roundTrip, dto)
    }


    @Test
    func testSingleStage() throws {
        let dto = FileContent(fileName: "2024-06-12", data: EventDTO.DaySchedule(
            date: day,
            performances: [
                "Bass Haven": [
                    PerformanceDTO(
                        artist: "Sunspear",
                        time: "6:30 PM"
                    ),
                    PerformanceDTO(
                        artist: "Phantom Groove",
                        time: "10:30 PM"
                    ),
                    PerformanceDTO(
                        artist: "Oaktrail",
                        time: "12:30 AM"
                    ),
                    PerformanceDTO(
                        artist: "Rhythmbox",
                        time: "4:00 AM",
                        endTime: "7:30 AM"
                    )
                ]
            ]
        ))
        let schedule = Event.Schedule.Day(
            id: "2024-06-12",
            date: CalendarDate(year: 2024, month: 6, day: 12),
            customTitle: nil,
            stageSchedules: [
                "Bass Haven": [
                    Event.Performance(
                        id: .init("Sunspear-18:30-Bass Haven"),
                        customTitle: nil,
                        artistIDs: ["Sunspear"],
                        startTime: day.atTime(ScheduleTime(hour: 18, minute: 30)!),
                        endTime: day.atTime(ScheduleTime(hour: 22, minute: 30)!),
                        stageID: Event.Stage.ID(rawValue: "Bass Haven")
                    ),
                    Event.Performance(
                        id: .init("Phantom Groove-22:30-Bass Haven"),
                        customTitle: nil,
                        artistIDs: ["Phantom Groove"],
                        startTime: day.atTime(ScheduleTime(hour: 22, minute: 30)!),
                        endTime: day.atTime(ScheduleTime(hour: 24, minute: 30)!),
                        stageID: Event.Stage.ID(rawValue: "Bass Haven")
                    ),
                    Event.Performance(
                        id: .init("Oaktrail-24:30-Bass Haven"),
                        customTitle: nil,
                        artistIDs: ["Oaktrail"],
                        startTime: day.atTime(ScheduleTime(hour: 24, minute: 30)!),
                        endTime: day.atTime(ScheduleTime(hour: 28)!),
                        stageID: Event.Stage.ID(rawValue: "Bass Haven")
                    ),
                    Event.Performance(
                        id: .init("Rhythmbox-28:00-Bass Haven"),
                        customTitle: nil,
                        artistIDs: ["Rhythmbox"],
                        startTime: day.atTime(ScheduleTime(hour: 28)!),
                        endTime: day.atTime(ScheduleTime(hour: 31, minute: 30)!),
                        stageID: Event.Stage.ID(rawValue: "Bass Haven")
                    )
                ]
            ]
        )

        let result = try ScheduleDayConversion().apply(dto)


        expectNoDifference(result, schedule)

        let roundTrip = try ScheduleDayConversion().unapply(result)
        expectNoDifference(roundTrip, dto)
    }
}

