import Validated
import Foundation
import Collections
import OpenFestivalModels
import MemberwiseInit

extension Validation.ScheduleError {
    enum PerformanceError: Error, CustomStringConvertible, Equatable {
        case invalidStartTime(String)
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

extension EventFileTree.ScheduleDayConversion {
    struct TimelessStagelessPerformanceConversion: Conversion {
        typealias Input = PerformanceDTO
        typealias Output = TimelessStagelessPerformance

        func apply(_ input: PerformanceDTO) throws -> TimelessStagelessPerformance {
            TimelessStagelessPerformance(
                startTime: try ScheduleTimeConversion().apply(input.time),
                endTime: try input.endTime.map(ScheduleTimeConversion().apply(_:)),
                customTitle: input.title,
                artistIDs: try getArtists(artist: input.artist, artists: input.artists)
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


extension PerformanceDTO {
    var toPartialPerformance: Validated<TimelessStagelessPerformance, Validation.ScheduleError.PerformanceError> {
        typealias PerformanceError = Validation.ScheduleError.PerformanceError
        typealias ArtistID = Event.Artist.ID
        typealias ArtistCollection = OrderedSet<ArtistID>

        let startTime = Validated {
            try ScheduleTimeConversion().apply(self.time)
        } mappingError: { _ in
            PerformanceError.invalidStartTime(self.time)
        }

        let endTime = Validated {
            try self.endTime.map {
                try ScheduleTimeConversion().apply($0)
            }
        } mappingError: { _ in
            PerformanceError.invalidEndTime(self.endTime ?? "")
        }

        let artistIDs: Validated<ArtistCollection, PerformanceError> = Validated {
            switch (self.artist, self.artists) {
            case (.none, .none): return []
            case (.some, .some): throw PerformanceError.artistAndArtists
            case (.some(let artistName), .none):
                guard artistName.hasElements
                else { throw PerformanceError.emptyArtist }

                return OrderedSet([Event.Artist.ID(artistName)])

            case (.none, .some(let artists)):
                guard artists.hasElements
                else { throw PerformanceError.emptyArtists  }

                return OrderedSet(artists.map(ArtistID.init(rawValue:)))
            }
        } mappingError: { error in
            (error as? PerformanceError) ?? .unknownError
        }


        return zip(startTime, endTime, artistIDs).flatMapish { startTime, endTime, artists in
            guard !(artists.isEmpty && self.title == nil)
            else { return .error(.noArtistsOrTitle) }

            return .valid(TimelessStagelessPerformance(
                startTime: startTime,
                endTime: endTime,
                customTitle: self.title,
                artistIDs: artists
            ))
        }
    }
}


struct ScheduleTimeConversion: Conversion {
    typealias Input = String
    typealias Output = ScheduleTime

    private let formats = ["h:mm a", "HH:mm", "h a", "h:mm", "h"]

    func apply(_ input: Input) throws -> Output {
        struct TimeParsingError: Error {}

        let formatter = DateFormatter()

        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        for format in formats {
            formatter.dateFormat = format
            if let time = ScheduleTime(from: input, using: formatter) {
                return time
            }
        }

        throw TimeParsingError()
    }

    func unapply(_ output: ScheduleTime) throws -> String {
        output.formattedString(dateFormat: formats.first!)
    }
}

import Parsing

extension Validated {
    func flatMapish<U>(_ transform: (Value) -> Validated<U, Error>) -> Validated<U, Error> {
        switch self {
        case .valid(let value): return transform(value)
        case .invalid(let error): return .invalid(error)
        }
    }
}
