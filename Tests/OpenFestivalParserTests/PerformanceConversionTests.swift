@testable import OpenFestivalParser
import Testing
import CustomDump
import OpenFestivalModels
import Validated
import Dependencies
import FileTree

struct PerformanceConversionTests {

    let conversion = ScheduleDayConversion.TimelessStagelessPerformanceConversion()
    typealias PerformanceError = Validation.ScheduleError.PerformanceError

    @Test
    func simplestPerformance() throws {
        let dto = PerformanceDTO(
            artist: "Prism Sound",
            time: "10:00 PM"
        )

        let expectedResult = TimelessStagelessPerformance(
            startTime: ScheduleTime(hour: 22)!,
            endTime: nil,
            artistIDs: [Event.Artist.ID("Prism Sound")]
        )

        let result = try conversion.apply(dto)

        expectNoDifference(result, expectedResult)
        try expect(result, toRoundtripUsing: conversion.inverted())
    }

    @Test
    func mappingSimplestPerformanceWithEndTime() throws {
        let dto = PerformanceDTO(
            artist: "Prism Sound",
            time: "10:00 PM",
            endTime: "11:00 PM"
        )

        let expectedResult = TimelessStagelessPerformance(
            startTime: ScheduleTime(hour: 22)!,
            endTime: ScheduleTime(hour: 23)!,
            artistIDs: [Event.Artist.ID("Prism Sound")]
        )

        let result = try conversion.apply(dto)

        expectNoDifference(result, expectedResult)
        try expect(result, toRoundtripUsing: conversion.inverted())
    }


    @Test
    func mappingMultiArtistPerformanceWithTitle() throws {
        let dto = PerformanceDTO(
            title: "Subsonic B2B Sylvan",
            artists: ["Subsonic", "Sylvan Beats"],
            time: "11:30 PM"
        )

        let expectedResult = TimelessStagelessPerformance(
            startTime: ScheduleTime(hour: 23, minute: 30)!,
            endTime: nil,
            customTitle: "Subsonic B2B Sylvan",
            artistIDs: [
                Event.Artist.ID("Subsonic"),
                Event.Artist.ID("Sylvan Beats")
            ]
        )

        let result = try conversion.apply(dto)

        expectNoDifference(result, expectedResult)
        try expect(result, toRoundtripUsing: conversion.inverted())
    }

    struct ConversionErrors {
        typealias PerformanceError = Validation.ScheduleError.PerformanceError
        let conversion = ScheduleDayConversion.TimelessStagelessPerformanceConversion()

        @Test("Invalid start time throws error")
        func invalidStartTime() throws {
            let dto = PerformanceDTO(time: "Night PM")

            #expect(throws: Errors(ScheduleTimeDecodingError.invalidDateString)!) {
                try conversion.apply(dto)
            }
        }

        @Test("Invalid end time throws error")
        func invalidEndTime() throws {
            let dto = PerformanceDTO(
                artist: "Prism Sound",
                time: "10:00 PM",
                endTime: "Dawnish"
            )

            #expect(throws: Errors(ScheduleTimeDecodingError.invalidDateString)!) {
                try conversion.apply(dto)
            }
        }

        @Test("Missing artists and title throws error")
        func missingArtistsAndTitle() throws {
            let dto = PerformanceDTO(time: "10:00 PM")

            #expect(throws: PerformanceError.noArtistsOrTitle) {
                try conversion.apply(dto)
            }
        }

        @Test("Having both artist and artists throws error")
        func bothArtistAndArtists() throws {
            let dto = PerformanceDTO(
                artist: "Prism Sound",
                artists: ["Subsonic", "Sylvan Beats"],
                time: "10:00 PM"
            )

            #expect(throws: Errors(PerformanceError.artistAndArtists)!) {
                try conversion.apply(dto)
            }
        }

        @Test("Empty artist string throws error")
        func emptyArtist() throws {
            let dto = PerformanceDTO(
                artist: "",
                time: "10:00 PM"
            )

            #expect(throws: Errors(PerformanceError.emptyArtist)!) {
                try conversion.apply(dto)
            }
        }

        @Test("Empty artists array throws error")
        func emptyArtistsArray() throws {
            let dto = PerformanceDTO(
                artists: [],
                time: "10:00 PM"
            )

            #expect(throws: Errors(PerformanceError.emptyArtists)!) {
                try conversion.apply(dto)
            }
        }
    }
}
