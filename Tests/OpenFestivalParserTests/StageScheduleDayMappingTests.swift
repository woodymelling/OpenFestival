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
        let dto = [
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
                    startTime: ScheduleTime(hour: 16, minute: 30)!,
                    endTime: ScheduleTime(hour: 18, minute: 30)!
                ),
                StagelessPerformance(
                    artistIDs: ["Phantom Groove"],
                    startTime: ScheduleTime(hour: 18, minute: 30)!,
                    endTime: ScheduleTime(hour: 20)!
                ),
                StagelessPerformance(
                    artistIDs: ["Oaktrail"],
                    startTime: ScheduleTime(hour: 20)!,
                    endTime: ScheduleTime(hour: 22)!
                ),
                StagelessPerformance(
                    artistIDs: ["Rhythmbox"],
                    startTime: ScheduleTime(hour: 22)!,
                    endTime: ScheduleTime(hour: 23, minute: 30)!
                )
            ]
        )
    }

    func testParsingScheduleSimpleThroughMidnight() {
        let dto = [
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
                    startTime: ScheduleTime(hour: 22, minute: 30)!,
                    endTime: ScheduleTime(hour: 24, minute: 30)!
                ),
                StagelessPerformance(
                    artistIDs: ["Phantom Groove"],
                    startTime: ScheduleTime(hour: 24, minute: 30)!,
                    endTime: ScheduleTime(hour: 26)!
                ),
                StagelessPerformance(
                    artistIDs: ["Oaktrail"],
                    startTime: ScheduleTime(hour: 26)!,
                    endTime: ScheduleTime(hour: 28)!
                ),
                StagelessPerformance(
                    artistIDs: ["Rhythmbox"],
                    startTime: ScheduleTime(hour: 28)!,
                    endTime: ScheduleTime(hour: 29, minute: 30)!
                )
            ]
        )
    }

    func testParsingScheduleWithOverlappingPerformances() {
        let dto = [
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
            [.overlappingPerformances(
                StagelessPerformance(
                    artistIDs: ["Rhythmbox"],
                    startTime: ScheduleTime(hour: 4, minute: 0)!,
                    endTime: ScheduleTime(hour: 5, minute: 30)!
                ),
                StagelessPerformance(
                    artistIDs: ["Rhythmbox"],
                    startTime: ScheduleTime(hour: 5, minute: 0)!,
                    endTime: ScheduleTime(hour: 6, minute: 30)!
                )
            )]
        )
    }

//    func testParsingScheduleOverlappingAtMidnight() {
//        let dto = [
//            PerformanceDTO(
//                artist: "Rhythmbox",
//                time: "11:30 PM",
//                endTime: "12:30 AM"
//            ),
//            PerformanceDTO(
//                artist: "Rhythmbox",
//                time: "11:45 PM",
//                endTime: "1:30 AM"
//            )
//        ]
//
//        XCTAssertInvalidWithErrors(
//            dto.toStageDaySchedule,
//            [.overlappingPerformances(
//                StagelessPerformance(
//                    artistIDs: ["Rhythmbox"],
//                    startTime: ScheduleTime(hour: 11, minute: 30)!,
//                    endTime: ScheduleTime(hour: 12, minute: 30)!
//                ),
//                StagelessPerformance(
//                    artistIDs: ["Rhythmbox"],
//                    startTime: ScheduleTime(hour: 5, minute: 0)!,
//                    endTime: ScheduleTime(hour: 6, minute: 30)!
//                )
//
//            )]
//        )
//    }
//
//    func testParsingScheduleWithNoEndTime() {
//        let dto = [
//            PerformanceDTO(
//                artist: "Sunspear",
//                time: "4:30 PM"
//            ),
//            PerformanceDTO(
//                artist: "Phantom Groove",
//                time: "6:30 PM"
//            ),
//            PerformanceDTO(
//                artist: "Oaktrail",
//                time: "8:00 PM"
//            )
//        ]
//
//        XCTAssertInvalidWithErrors(
//            dto.toStageDaySchedule,
//            [.cannotDetermineEndTimeForPerformance]
//        )
//    }
//
//
//    func testParsingScheduleWithEndTimeBeforeStartTime() {
//        let dto = [
//            PerformanceDTO(
//                artist: "Rhythmbox",
//                time: "4:00 AM",
//                endTime: "3:30 AM"
//            )
//        ]
//
//        XCTExpectFailure("Trying to figure this out while also parsing out midnight stuff is pretty tought") {
//            XCTAssertInvalidWithErrors(
//                dto.toStageDaySchedule,
//                [.endTimeBeforeStartTime(ScheduleTime(hour: 4)!, ScheduleTime(hour: 3, minute: 30)!)]
//            )
//        }
//
//    }

    func testParsingScheduleWithNoPerformances() {
        XCTAssertValidAndEqual(
            [].toStageDaySchedule,
            []
        )
    }

    func testParsingScheduleWithBackToBackPerformances() {
        let dto = [
            PerformanceDTO(
                artist: "Sunspear",
                time: "4:30 PM",
                endTime: "5:30 PM"
            ),
            PerformanceDTO(
                artist: "Phantom Groove",
                time: "5:30 PM",
                endTime: "6:30 PM"
            )
        ]

        XCTAssertValidAndEqual(
            dto.toStageDaySchedule,
            [
                StagelessPerformance(
                    artistIDs: ["Sunspear"],
                    startTime: ScheduleTime(hour: 16, minute: 30)!,
                    endTime: ScheduleTime(hour: 17, minute: 30)!
                ),
                StagelessPerformance(
                    artistIDs: ["Phantom Groove"],
                    startTime: ScheduleTime(hour: 17, minute: 30)!,
                    endTime: ScheduleTime(hour: 18, minute: 30)!
                )
            ]
        )
    }
}

