//
//  File.swift
//  
//
//  Created by Woodrow Melling on 6/12/24.
//

import Foundation
import XCTest
import OpenFestivalModels
@testable import OpenFestivalParser
import Dependencies

class DayScheduleMappingTests: XCTestCase {

    override func perform(_ run: XCTestRun) {
        withDependencies {
            $0.calendar = .current
        } operation: {
            super.perform(run)
        }

    }
    func testMappingDaySchedule() {
        let day = CalendarDate(year: 2024, month: 6, day: 12)
        let dto = EventDTO.DaySchedule(
            date: day,
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
                        time: "10 PM",
                        endTime: "11:30 PM"
                    )
                ]
            ]
        )

        XCTAssertValidAndEqual(DayScheduleMapper().map(dto), [
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
        ])
        
    }
}
