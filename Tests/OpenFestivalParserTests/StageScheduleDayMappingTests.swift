//
//  File.swift
//  
//
//  Created by Woodrow Melling on 6/3/24.
//
import XCTest
import Foundation
@testable import OpenFestivalParser
import Validated


class StageScheduleDayMappingTests: XCTestCase {
    func testParsingScheduleSimpleBeforeMidnight() {
        let dto: EventDTO.StageDaySchedule = [
            PerformanceDTO(
                artist: "Sunspear",
                time: "4:30 PM"
            ),
            PerformanceDTO(
                artist: "Phantom Groove",
                time: "6:30 PM"
            ),
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

        XCTAssertValidAndEqual(
            dto.toStageDaySchedule,
            [
                StagelessPerformance(
                    artistIDs: ["Sunspear"],
                    startTime: Date(hour: 16, minute: 30)!,
                    endTime: Date(hour: 18, minute: 30)!
                ),
                StagelessPerformance(
                    artistIDs: ["Phantom Groove"],
                    startTime: Date(hour: 18, minute: 30)!,
                    endTime: Date(hour: 20)!
                ),
                StagelessPerformance(
                    artistIDs: ["Oaktrail"],
                    startTime: Date(hour: 20)!,
                    endTime: Date(hour: 22)!
                ),
                StagelessPerformance(
                    artistIDs: ["Rhythmbox"],
                    startTime: Date(hour: 22)!,
                    endTime: Date(hour: 23, minute: 30)!
                )
            ]
        )
    }

    func testParsingScheduleSimpleThroughMidnight() {
        let dto: EventDTO.StageDaySchedule = [
            PerformanceDTO(
                artist: "Sunspear",
                time: "10:30 PM"
            ),
            PerformanceDTO(
                artist: "Phantom Groove",
                time: "12:30 AM"
            ),
            PerformanceDTO(
                artist: "Oaktrail",
                time: "2:00 AM"
            ),
            PerformanceDTO(
                artist: "Rhythmbox",
                time: "4 AM",
                endTime: "5:30 AM"
            )
        ]

        XCTAssertValidAndEqual(
            dto.toStageDaySchedule,
            [
                StagelessPerformance(
                    artistIDs: ["Sunspear"],
                    startTime: Date(hour: 22, minute: 30)!,
                    endTime: Date(hour: 0, minute: 30)!
                ),
                StagelessPerformance(
                    artistIDs: ["Phantom Groove"],
                    startTime: Date(hour: 0, minute: 30)!,
                    endTime: Date(hour: 2)!
                ),
                StagelessPerformance(
                    artistIDs: ["Oaktrail"],
                    startTime: Date(hour: 2)!,
                    endTime: Date(hour: 4)!
                ),
                StagelessPerformance(
                    artistIDs: ["Rhythmbox"],
                    startTime: Date(hour: 4)!,
                    endTime: Date(hour: 5, minute: 30)!
                )
            ]
        )
    }

    func testParsingScheduleWithOverlappingPerformances() {
        let dto: EventDTO.StageDaySchedule = [
            PerformanceDTO(
                artist: "Rhythmbox",
                time: "4 AM",
                endTime: "5:30 AM"
            ),
            PerformanceDTO(
                artist: "Rhythmbox",
                time: "5:00 AM",
                endTime: "6:30 AM"
            )
        ]

        XCTAssertInvalidWithErrors(
            dto.toStageDaySchedule,
            [.overlappingPerformances]
        )
    }

    func testParsingScheduleOverlappingAtMidnight() {
        let dto: EventDTO.StageDaySchedule = [
            PerformanceDTO(
                artist: "Rhythmbox",
                time: "11:30 PM",
                endTime: "12:30 AM"
            ),
            PerformanceDTO(
                artist: "Rhythmbox",
                time: "11:45 AM",
                endTime: "1:30 AM"
            )
        ]

        XCTAssertInvalidWithErrors(
            dto.toStageDaySchedule,
            [.overlappingPerformances]
        )
    }
}
