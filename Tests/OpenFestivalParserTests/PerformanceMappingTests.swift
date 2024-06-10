import XCTest
@testable import OpenFestivalParser
import CustomDump
import OpenFestivalModels
import Validated
import Dependencies

class PerformanceMappingTests: XCTestCase {
    func testMappingSimplestPerformance() {
        let dto = PerformanceDTO(
            artist: "Prism Sound",
            time: "10:00 PM"
        )

        XCTAssertValidAndEqual(
            dto.toPartialPerformance,
            TimelessStagelessPerformance(
                startTime: ScheduleTime(hour: 22)!,
                endTime: nil,
                artistIDs: [Event.Artist.ID("Prism Sound")]
            )
        )
    }

    func testMappingSimplestPerformanceWithEndTime() {
        let dto = PerformanceDTO(
            artist: "Prism Sound",
            time: "10:00 PM",
            endTime: "11:00 PM"
        )

        XCTAssertValidAndEqual(
            dto.toPartialPerformance,
            TimelessStagelessPerformance(
                startTime: ScheduleTime(hour: 22)!,
                endTime: ScheduleTime(hour: 23)!,
                artistIDs: [Event.Artist.ID("Prism Sound")]
            )
        )
    }

    func testMappingMultiArtistPerformanceWithTitle() {
        let dto = PerformanceDTO(
            title: "Subsonic B2B Sylvan",
            artists: ["Subsonic", "Sylvan Beats"],
            time: "11:30 PM"
        )

        XCTAssertValidAndEqual(
            dto.toPartialPerformance,
            TimelessStagelessPerformance(
                startTime: ScheduleTime(hour: 23, minute: 30)!,
                customTitle: "Subsonic B2B Sylvan",
                artistIDs: [
                    "Subsonic", "Sylvan Beats"
                ]
            )
        )
    }

    func testMappingFailureInvalidStartTime() {
        let dto = PerformanceDTO(
            artist: "Prism Sound",
            time: "Blen PM"
        )

        XCTAssertInvalidWithErrors(
            dto.toPartialPerformance,
            [Validation.ScheduleError.PerformanceError.invalidStartTime("Blen PM")]
        )
    }

    func testMappingFailureInvalidEndTime() {
        let dto = PerformanceDTO(
            artist: "Prism Sound",
            time: "10:00 PM",
            endTime: "Blen PM"
        )

        XCTAssertInvalidWithErrors(
            dto.toPartialPerformance,
            [Validation.ScheduleError.PerformanceError.invalidEndTime("Blen PM")]
        )
    
    }

    func testMappingFailureNoArtistsOrTitle() {
        let dto = PerformanceDTO(
            time: "10:00 PM"
        )

        XCTAssertInvalidWithErrors(
            dto.toPartialPerformance,
            [Validation.ScheduleError.PerformanceError.noArtistsOrTitle]
        )
    }

    func testMappingFailureArtistAndArtists() {
        let dto = PerformanceDTO(
            artist: "Prism Sound",
            artists: ["Subsonic", "Sylvan Beats"],
            time: "10:00 PM"
        )

        XCTAssertInvalidWithErrors(
            dto.toPartialPerformance,
            [Validation.ScheduleError.PerformanceError.artistAndArtists]
        )
    }

    func testMappingFailureEmptyArtist() {
        let dto = PerformanceDTO(
            artist: "",
            time: "10:00 PM"
        )

        XCTAssertInvalidWithErrors(
            dto.toPartialPerformance,
            [Validation.ScheduleError.PerformanceError.emptyArtist]
        )
    }

    func testMappingFailureEmptyArtists() {
        let dto = PerformanceDTO(
            artists: [],
            time: "10:00 PM"
        )

        XCTAssertInvalidWithErrors(
            dto.toPartialPerformance,
            [Validation.ScheduleError.PerformanceError.emptyArtists]
        )
    }
}


extension XCTestCase {
    func XCTAssertValidAndEqual<T, E>(
        _ validated: Validated<T, E>,
        _ expected: T,
        file: StaticString = #file,
        line: UInt = #line
    ) where T: Equatable {
        switch validated {
        case .valid(let item):
            XCTAssertNoDifference(item, expected, file: file, line: line)
        case .invalid(let errors):
            XCTFail("Expected valid, got error: \(errors)", file: file, line: line)
        }
    }

    func XCTAssertInvalidWithErrors<T, E>(
        _ validated: Validated<T, E>,
        _ expectedErrors: NonEmptyArray<E>,
        file: StaticString = #file,
        line: UInt = #line
    ) where E: Equatable {
        switch validated {
        case .valid(let item):
            XCTFail("Expected invalid, got: \(item)", file: file, line: line)
        case .invalid(let errors):
            XCTAssertNoDifference(errors, expectedErrors, file: file, line: line)
        }
    }
}
//
//extension Time {
//    // Create a date from specified parameters
//    ///
//    /// - Parameters:
//    ///   - year: The desired year
//    ///   - month: The desired month
//    ///   - day: The desired day
//    /// - Returns: A `Time` object
//    init?(year: Int = 2000, month: Int = 1, day: Int = 1, hour: Int = 0, minute: Int = 0) {
//        let calendar = Calendar.current
//        var dateComponents = DateComponents()
//
//        dateComponents.year = year
//        dateComponents.month = month
//        dateComponents.day = day
//        dateComponents.hour = hour
//        dateComponents.minute = minute
//        dateComponents.timeZone = .gmt
//
//        if let date = calendar.date(from: dateComponents) {
//            self = date
//        } else {
//            return nil
//        }
//    }
//}
