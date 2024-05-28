import Foundation
import Yams
import CustomDump


public struct Event {}

struct EventDTO: Decodable, Equatable {
    var name: String
    var address: String?
    var timeZone: String?
    
    var imageURL: URL?
    var siteMapImageURL: URL?

    var colorScheme: ColorScheme?
    
    struct ColorScheme: Equatable, Decodable {
        var primaryColor: String?
        var workshopsColor: String?
    }
}

struct Stage: Decodable, Equatable {
    var name: String
    var color: String?
    var imageURL: URL?
}

struct ContactInfo: Decodable, Equatable {
    var phoneNumber: String
    var title: String
    var description: String?
}

struct Performance: Decodable, Equatable {
    var title: String?
    var artist: String?
    var artists: [String]?
    var time: String
    var endTime: String?
}

import Dependencies
import DependenciesMacros

@DependencyClient
public struct OpenFestivalParser {
    public var parse: (_ from: String) async throws -> Event
}

extension OpenFestivalParser {
    enum ValidationFailure: Error, CustomStringConvertible {
        case noEventInfoFile
        case noSchedulesDirectory

        var description: String {
            switch self {
            case .noEventInfoFile: "No event-info.yaml file found in the provided directory"
            case .noSchedulesDirectory: "No schedule directory found in the provided directory"
            }
        }
    }
}

extension OpenFestivalParser: DependencyKey {
    public static var liveValue: OpenFestivalParser {
        OpenFestivalParser(
            parse: Self.parseEvent(from:)
        )
    }
}

extension OpenFestivalParser {
    private static func parseEvent(from path: String) async throws -> Event {
        let url = URL(fileURLWithPath: path)


        // let event = try await parseEventInfo(fromDirectory: url)
        // let stages = try await parseStages(fromDirectory: url)
        let performances = try await parseSchedule(fromDirectory: url)

        return Event()
    }

    typealias ScheduleDay = [String: [Performance]]
    typealias Schedule = [String: ScheduleDay]

    private static func parseSchedule(fromDirectory url: URL) async throws -> Schedule {
        @Dependency(\.fileManager) var fileManager

        let urls = try fileManager.contentsOfDirectory(in: url.appendingPathComponent("schedule"))
       
        let performances: Schedule = try Dictionary(
            uniqueKeysWithValues: urls.map { url in
                let data = try Data(contentsOf: url)
                let performances = try YAMLDecoder().decode(ScheduleDay.self, from: data)

                return (url.lastPathComponent, performances)
            }
        ) 

        customDump(performances)

        return performances
    }   

    private static func parseStages(fromDirectory url: URL) async throws -> [Stage] {
        @Dependency(\.fileManager) var fileManager

        let urls = try fileManager.contentsOfDirectory(in: url)
       
        guard let stagesURL = urls.first(where: { $0.lastPathComponent == "stages.yaml" })
        else { return [] }

        let data = try Data(contentsOf: stagesURL)
        let stages = try YAMLDecoder().decode([Stage].self, from: data)

        customDump(stages)

        return stages
    }


    private static func parseEventInfo(fromDirectory url: URL) async throws -> EventDTO {
        @Dependency(\.fileManager) var fileManager

        let urls = try fileManager.contentsOfDirectory(in: url)
       
        guard let eventInfoURL = urls.first(where: { $0.lastPathComponent == "event-info.yaml" })
        else { throw ValidationFailure.noEventInfoFile }


        let data = try Data(contentsOf: eventInfoURL)
        let eventDTO = try YAMLDecoder().decode(EventDTO.self, from: data)

        customDump(eventDTO)

        return eventDTO
    }
}


