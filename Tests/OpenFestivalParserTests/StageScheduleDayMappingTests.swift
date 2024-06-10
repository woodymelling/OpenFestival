//
//  File.swift
//
//
//  Created by Woodrow Melling on 6/3/24.
//
import Testing
import Foundation
@testable import OpenFestivalParser
import Validated


struct StageScheduleDayMappingTests {
    @Test
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

        #expect(
            dto.toStageDaySchedule == .valid([
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
            ])
        )
    }

    @Test
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

        #expect(
            dto.toStageDaySchedule == .valid([
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
            ])
        )
    }

    @Test
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

        #expect(
            dto.toStageDaySchedule ==
            .error(.overlappingPerformances)
        )
    }

    @Test
    func testParsingScheduleOverlappingAtMidnight() {
        let dto: EventDTO.StageDaySchedule = [
            PerformanceDTO(
                artist: "Rhythmbox",
                time: "11:30 PM",
                endTime: "12:30 AM"
            ),
            PerformanceDTO(
                artist: "Rhythmbox",
                time: "11:45 PM",
                endTime: "1:30 AM"
            )
        ]

        #expect(
            dto.toStageDaySchedule ==
            .error(.overlappingPerformances)
        )
    }

    func testParsingScheduleWithNoEndTime() {
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
            )
        ]

        #expect(dto.toStageDaySchedule == .error(.cannotDetermineEndTimeForPerformance))
    }


    @Test(
        .disabled("Trying to figure this out while also parsing out midnight stuff is pretty tought")
    )
    func testParsingScheduleWithEndTimeBeforeStartTime() {
        let dto: EventDTO.StageDaySchedule = [
            PerformanceDTO(
                artist: "Rhythmbox",
                time: "4:00 AM",
                endTime: "3:30 AM"
            )
        ]

        #expect(dto.toStageDaySchedule == .error(.endTimeBeforeStartTime))
    }

    @Test()
    func testParsingScheduleWithNoPerformances() {
        let dto: EventDTO.StageDaySchedule = []

        #expect(dto.toStageDaySchedule == .valid([]))
    }

    func testParsingScheduleWithBackToBackPerformances() {
        let dto: EventDTO.StageDaySchedule = [
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

        #expect(
            dto.toStageDaySchedule == .valid(
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
        )
    }
}

