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
struct PartialPerformance: Equatable {
    var startTime: Date
    var endTime: Date?
    var customTitle: String?
    var artistIDs: NonEmpty<OrderedSet<Event.Artist.ID>>?
}

extension PerformanceDTO {
    var toPartialPerformance: Validated<PartialPerformance, Validation.ScheduleError.PerformanceError> {
        typealias PerformanceError = Validation.ScheduleError.PerformanceError
        typealias ArtistID = Event.Artist.ID
        typealias ArtistCollection = NonEmpty<OrderedSet<ArtistID>>

        let startTime = Validated {
            try parseTimeString(self.time)
        } mappingError: { _ in
            PerformanceError.invalidStartTime(self.time)
        }

        let endTime = Validated {
            try self.endTime.map {
                try parseTimeString($0)
            }
        } mappingError: { _ in
            PerformanceError.invalidEndTime(self.endTime ?? "")
        }

        let artistIDs = Validated {
            switch (self.artist, self.artists) {
            case (.none, .none): return ArtistCollection?.none
            case (.some, .some): throw PerformanceError.artistAndArtists
            case (.some(let artistName), .none):
                guard !artistName.isEmpty
                else { throw PerformanceError.emptyArtist }
                return NonEmpty(arrayLiteral: Event.Artist.ID(artistName))

            case (.none, .some(let artists)):
                guard let artists = NonEmpty(rawValue: OrderedSet(artists.map(ArtistID.init(rawValue:))))
                else { throw PerformanceError.emptyArtists  }

                return artists
            }
        } mappingError: { error in
            (error as? PerformanceError) ?? .unknownError
        }


        return zip(startTime, endTime, artistIDs).flatMap { startTime, endTime, artists in
            guard !(artists == nil && self.title == nil)
            else { return .error(.noArtistsOrTitle) }

            return .valid(PartialPerformance(
                startTime: startTime,
                endTime: endTime,
                customTitle: self.title,
                artistIDs: artists
            ))
        }
    }
}

func parseTimeString(_ time: String) throws ->  Date {
    struct TimeParsingError: Error {}

    let formatter = DateFormatter()
    let formats = ["h:mm a", "HH:mm", "h a", "h:mm", "h"]

    // Ensure the formatter uses UTC time zone for consistency
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
//    formatter.defaultDate = .distantPast


    for format in formats {
        formatter.dateFormat = format
        if let date = formatter.date(from: time) {
            return date
        }
    }

    throw TimeParsingError()
}


extension Validated {
    func flatMap<U>(_ transform: (Value) -> Validated<U, Error>) -> Validated<U, Error> {
        switch self {
        case .valid(let value): return transform(value)
        case .invalid(let error): return .invalid(error)
        }
    }
}