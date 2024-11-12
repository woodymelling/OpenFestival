import Validated
import Foundation
import Collections
import OpenFestivalModels
import MemberwiseInit

protocol EquatableError: Equatable, Error {}

extension Validation.ScheduleError {
    enum PerformanceError: Error, CustomStringConvertible, Equatable {
        case invalidStartTime(ScheduleTimeDecodingError)
        case invalidEndTime(String)
        case artistAndArtists
        case noArtistsOrTitle
        case emptyArtist
        case emptyArtists
        case unknownError

        var description: String {
            switch self {
            case .invalidStartTime(let time): "Unable to parse start time: \(time)"
            case .invalidEndTime(let time): "Unable to parse end time: \(time)"
            case .artistAndArtists: "Cannot have both artist and artists for a performance"
            case .noArtistsOrTitle: "You must provide at least one artist or a title for each set"
            case .emptyArtist: "artist field must have an artist"
            case .emptyArtists: "artists field must have at least one artist"
            case .unknownError: "Failed to parse performance"
            }
        }
    }
}



@MemberwiseInit
struct TimelessStagelessPerformance: Equatable {
    var startTime: ScheduleTime
    var endTime: ScheduleTime?
    var customTitle: String?
    var artistIDs: OrderedSet<Event.Artist.ID>
}


import Parsing
import FileTree

extension ScheduleDayConversion {
    struct TimelessStagelessPerformanceConversion: Conversion {
        typealias Input = PerformanceDTO
        typealias Output = TimelessStagelessPerformance

        func apply(_ input: PerformanceDTO) throws -> TimelessStagelessPerformance {
            let startTime = try ScheduleTimeConversion().apply(input.time)
            let endTime = try input.endTime.map(ScheduleTimeConversion().apply(_:))
            let artistIDs = try getArtists(artist: input.artist, artists: input.artists)

            guard !(input.title == nil && artistIDs.isEmpty)
            else { throw PerformanceError.noArtistsOrTitle }

            return TimelessStagelessPerformance(
                startTime: startTime,
                endTime: endTime,
                customTitle: input.title,
                artistIDs: artistIDs
            )
        }

        func unapply(_ output: TimelessStagelessPerformance) throws -> PerformanceDTO {
            let artistIDs = output.artistIDs.map(\.rawValue)
            return PerformanceDTO(
                title: output.customTitle,
                artist: artistIDs.count == 1 ? artistIDs.first : nil,
                artists: artistIDs.count > 1 ? artistIDs : nil,
                time: try ScheduleTimeConversion().unapply(output.startTime),
                endTime: try output.endTime.map(ScheduleTimeConversion().unapply(_:))
            )
        }


        typealias PerformanceError = Validation.ScheduleError.PerformanceError

        func getArtists(artist: String?, artists: [String]?) throws -> OrderedSet<Event.Artist.ID> {
            switch (artist, artists) {
            case (.none, .none): return []
            case (.some, .some): throw PerformanceError.artistAndArtists
            case (.some(let artistName), .none):
                guard artistName.hasElements
                else { throw PerformanceError.emptyArtist }

                return OrderedSet([Event.Artist.ID(artistName)])

            case (.none, .some(let artists)):
                guard artists.hasElements
                else { throw PerformanceError.emptyArtists  }

                return OrderedSet(artists.map(Event.Artist.ID.init(rawValue:)))
            }
        }
    }

}


import Parsing

