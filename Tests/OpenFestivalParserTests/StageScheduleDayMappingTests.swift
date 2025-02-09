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
import Testing
import Parsing
import CustomDump


typealias ScheduleError = Validation.ScheduleError.StageDayScheduleError

//
//fileprivate let simpleScheduleBeforeMidnight = [
//    PerformanceDTO(
//        artist: "Sunspear",
//        time: "4:30 PM"
//    ),
//    PerformanceDTO(
//        artist: "Phantom Groove",
//        time: "6:30 PM"
//    ),
//    PerformanceDTO(
//        artist: "Oaktrail",
//        time: "8:00 PM"
//    ),
//    PerformanceDTO(
//        artist: "Rhythmbox",
//        time: "10 PM",
//        endTime: "11:30 PM"
//    )
//]
//fileprivate let simpleScheduleBeforeMidnightResult = [
//    StagelessPerformance(
//        artistIDs: ["Sunspear"],
//        startTime: ScheduleTime(hour: 16, minute: 30)!,
//        endTime: ScheduleTime(hour: 18, minute: 30)!
//    ),
//    StagelessPerformance(
//        artistIDs: ["Phantom Groove"],
//        startTime: ScheduleTime(hour: 18, minute: 30)!,
//        endTime: ScheduleTime(hour: 20)!
//    ),
//    StagelessPerformance(
//        artistIDs: ["Oaktrail"],
//        startTime: ScheduleTime(hour: 20)!,
//        endTime: ScheduleTime(hour: 22)!
//    ),
//    StagelessPerformance(
//        artistIDs: ["Rhythmbox"],
//        startTime: ScheduleTime(hour: 22)!,
//        endTime: ScheduleTime(hour: 23, minute: 30)!
//    )
//]
//
//fileprivate let simpleThroughMidnight = [
//    PerformanceDTO(
//        artist: "Sunspear",
//        time: "10:30 PM"
//    ),
//    PerformanceDTO(
//        artist: "Phantom Groove",
//        time: "12:30 AM"
//    ),
//    PerformanceDTO(
//        artist: "Oaktrail",
//        time: "2:00 AM"
//    ),
//    PerformanceDTO(
//        artist: "Rhythmbox",
//        time: "4 AM",
//        endTime: "5:30 AM"
//    )
//]
//fileprivate let simpleThroughMidnightResult = [
//    StagelessPerformance(
//        artistIDs: ["Sunspear"],
//        startTime: ScheduleTime(hour: 22, minute: 30)!,
//        endTime: ScheduleTime(hour: 24, minute: 30)!
//    ),
//    StagelessPerformance(
//        artistIDs: ["Phantom Groove"],
//        startTime: ScheduleTime(hour: 24, minute: 30)!,
//        endTime: ScheduleTime(hour: 26)!
//    ),
//    StagelessPerformance(
//        artistIDs: ["Oaktrail"],
//        startTime: ScheduleTime(hour: 26)!,
//        endTime: ScheduleTime(hour: 28)!
//    ),
//    StagelessPerformance(
//        artistIDs: ["Rhythmbox"],
//        startTime: ScheduleTime(hour: 28)!,
//        endTime: ScheduleTime(hour: 29, minute: 30)!
//    )
//]
//
//fileprivate let withBackToBackPerformances = [
//    PerformanceDTO(
//        artist: "Sunspear",
//        time: "4:30 PM",
//        endTime: "5:30 PM"
//    ),
//    PerformanceDTO(
//        artist: "Phantom Groove",
//        time: "5:30 PM",
//        endTime: "6:30 PM"
//    )
//]
//fileprivate let withBackToBackPerformancesResult = [
//    StagelessPerformance(
//        artistIDs: ["Sunspear"],
//        startTime: ScheduleTime(hour: 16, minute: 30)!,
//        endTime: ScheduleTime(hour: 17, minute: 30)!
//    ),
//    StagelessPerformance(
//        artistIDs: ["Phantom Groove"],
//        startTime: ScheduleTime(hour: 17, minute: 30)!,
//        endTime: ScheduleTime(hour: 18, minute: 30)!
//    )
//]
//
//// MARK: Errors
//fileprivate let overlappingPerformances = [
//    PerformanceDTO(
//        artist: "Rhythmbox",
//        time: "4 AM",
//        endTime: "5:30 AM"
//    ),
//    PerformanceDTO(
//        artist: "Rhythmbox",
//        time: "5:00 AM",
//        endTime: "6:30 AM"
//    )
//]
//fileprivate let overlappingPerformancesResult = ScheduleError.overlappingPerformances(
//    StagelessPerformance(
//        artistIDs: ["Rhythmbox"],
//        startTime: ScheduleTime(hour: 4, minute: 0)!,
//        endTime: ScheduleTime(hour: 5, minute: 30)!
//    ),
//    StagelessPerformance(
//        artistIDs: ["Rhythmbox"],
//        startTime: ScheduleTime(hour: 5, minute: 0)!,
//        endTime: ScheduleTime(hour: 6, minute: 30)!
//    )
//)
//
//
//fileprivate let scheduleOverlappingAtMidnight = [
//        PerformanceDTO(
//            artist: "Rhythmbox",
//            time: "11:30 PM",
//            endTime: "12:30 AM"
//        ),
//        PerformanceDTO(
//            artist: "Rhythmbox",
//            time: "11:45 PM",
//            endTime: "1:30 AM"
//        )
//    ]
//fileprivate let scheduleOverlappingAtMidnightResult = ScheduleError.overlappingPerformances(
//    StagelessPerformance(
//        artistIDs: ["Rhythmbox"],
//        startTime: ScheduleTime(hour: 11, minute: 30)!,
//        endTime: ScheduleTime(hour: 12, minute: 30)!
//    ),
//    StagelessPerformance(
//        artistIDs: ["Rhythmbox"],
//        startTime: ScheduleTime(hour: 5, minute: 0)!,
//        endTime: ScheduleTime(hour: 6, minute: 30)!
//    )
//
//)
//
//fileprivate let scheduleWithNoEndTime = [
//    PerformanceDTO(
//        artist: "Sunspear",
//        time: "4:30 PM"
//    ),
//    PerformanceDTO(
//        artist: "Phantom Groove",
//        time: "6:30 PM"
//    ),
//    PerformanceDTO(
//        artist: "Oaktrail",
//        time: "8:00 PM"
//    )
//]
//fileprivate let scheduleWithNoEndTimeResult = ScheduleError.cannotDetermineEndTimeForPerformance(
//    TimelessStagelessPerformance(
//        startTime: ScheduleTime(hour: 20)!,
//        artistIDs: ["Oaktrail"]
//    )
//)
//
//struct StageScheduleDayMappingTests {
//
//
//    let conversion = EventFileTree.ScheduleDayConversion.ScheduleDictionaryConversion.StagelessPerformanceConversion()
//
//    @Test(arguments: [
//        (simpleScheduleBeforeMidnight, simpleScheduleBeforeMidnightResult),
//        (simpleThroughMidnight, simpleThroughMidnightResult),
//        (withBackToBackPerformances, withBackToBackPerformancesResult),
//        ([], [])
//    ])
//    fileprivate func successfullyConvert(_ dtos: [PerformanceDTO], expectedResult: [StagelessPerformance]) throws {
//        let result = try conversion.apply(dtos)
//        expectNoDifference(result, expectedResult)
//
//        try expect(expectedResult, toRoundtripUsing: conversion.inverted())
//    }
//
//    @Test(arguments: [
//        (overlappingPerformances, overlappingPerformancesResult),
//        (scheduleOverlappingAtMidnight, scheduleOverlappingAtMidnightResult),
//        (scheduleWithNoEndTime, scheduleWithNoEndTimeResult)
//    ])
//    func testThrowing(_ dtos: [PerformanceDTO], error: ScheduleError) {
//        #expect(throws: error) {
//            try conversion.apply(dtos)
//        }
//    }
//}


struct StageScheduleDayMappingTests {
    let conversion = ScheduleDayConversion.ScheduleDictionaryConversion.StagelessPerformanceConversion()

    // MARK: - Success Cases

    @Test("Simple schedule before midnight converts successfully")
    func simpleBeforeMidnight() throws {
        let dtos = [
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

        let expected = [
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

        let result = try conversion.apply(dtos)
        expectNoDifference(result, expected)
        try expect(expected, toRoundtripUsing: conversion.inverted())
    }

    @Test("Schedule through midnight converts successfully")
    func throughMidnight() throws {
        let dtos = [
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

        let expected = [
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

        let result = try conversion.apply(dtos)
        expectNoDifference(result, expected)
        try expect(expected, toRoundtripUsing: conversion.inverted())
    }

    @Test("Back to back performances convert successfully")
    func backToBackPerformances() throws {
        let dtos = [
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

        let expected = [
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

        let result = try conversion.apply(dtos)
        expectNoDifference(result, expected)
        try expect(expected, toRoundtripUsing: conversion.inverted())
    }

    @Test("Empty schedule converts successfully")
    func emptySchedule() throws {
        let result = try conversion.apply([])
        expectNoDifference(result, [])
    }

    // MARK: - Error Cases

    @Test("Overlapping performances throw error")
    func overlappingPerformances() throws {
        let dtos = [
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

        let expectedError = ScheduleError.overlappingPerformances(
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
        )

        #expect(throws: expectedError) {
            try conversion.apply(dtos)
        }
    }

    @Test("Overlapping performances at midnight throw error")
    func overlappingAtMidnight() throws {
        let dtos = [
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

        let expectedError = ScheduleError.overlappingPerformances(
            StagelessPerformance(
                artistIDs: ["Rhythmbox"],
                startTime: ScheduleTime(hour: 23, minute: 30)!,
                endTime: ScheduleTime(hour: 24, minute: 30)!
            ),
            StagelessPerformance(
                artistIDs: ["Rhythmbox"],
                startTime: ScheduleTime(hour: 23, minute: 45)!,
                endTime: ScheduleTime(hour: 25, minute: 30)!
            )
        )

        #expect(throws: expectedError) {
            try conversion.apply(dtos)
        }
    }

    @Test("Missing end time throws error")
    func missingEndTime() throws {
        let dtos = [
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

        let expectedError = ScheduleError.cannotDetermineEndTimeForPerformance(
            TimelessStagelessPerformance(
                startTime: ScheduleTime(hour: 20)!,
                artistIDs: ["Oaktrail"]
            )
        )

        #expect(throws: expectedError) {
            try conversion.apply(dtos)
        }
    }
}
