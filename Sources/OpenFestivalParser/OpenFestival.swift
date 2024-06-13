import Foundation
import Yams
import CustomDump
import OpenFestivalModels

import Dependencies
import DependenciesMacros

@DependencyClient
public struct OpenFestivalParser {
    public var parse: (_ from: URL) async throws -> Event

    public func parse(from path: String) async throws -> Event {
        try await self.parse(from: URL(fileURLWithPath: path))
    }
}



extension OpenFestivalParser {
    enum ValidationFailure: Error, CustomStringConvertible {
        case noEventInfoFile
        case noSchedulesDirectory
        case noStagesFile

        var description: String {
            switch self {
            case .noEventInfoFile: "No event-info.yaml file found in the provided directory"
            case .noSchedulesDirectory: "No schedule directory found in the provided directory"
            case .noStagesFile: "No stages.yaml file found in the provided directory"
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
    private static func parseEvent(from path: URL) async throws -> Event {
        let eventDTO = try await parseEventDTO(fromPath: path)

        print("Properly parsed files, attempting to extract schedule info...")

        switch EventMapper().map(eventDTO) {
        case let .valid(event): return event
        case let .invalid(errors): throw errors.first // TODO
        }
    }


    private static func parseEventDTO(fromPath url: URL) async throws -> EventDTO {
        return .init(
            eventInfo: try await parseEventInfo(fromDirectory: url),
            stages: try await parseStages(fromDirectory: url),
            contactInfo: try await parseContactInfo(fromDirectory: url),
            schedule: try await parseSchedule(fromDirectory: url)
        )
    }

    private static func parseSchedule(fromDirectory url: URL) async throws -> EventDTO.Schedule {
        @Dependency(\.fileManager) var fileManager

        let urls = try fileManager.contentsOfDirectory(in: url.appendingPathComponent("schedule"))
       
       let schedule = try EventDTO.Schedule(daySchedules: urls.map { url in
               let data = try Data(contentsOf: url)
               let daySchedule = try YAMLDecoder().decode(EventDTO.DaySchedule.self, from: data)

               return daySchedule
           }
        )

        return schedule
    }   

    private static func parseStages(fromDirectory url: URL) async throws -> [StageDTO] {
        @Dependency(\.fileManager) var fileManager

        let urls = try fileManager.contentsOfDirectory(in: url)
       
        guard let stagesURL = urls.first(where: { $0.lastPathComponent == "stages.yaml" })
        else { throw ValidationFailure.noStagesFile }

        let data = try Data(contentsOf: stagesURL)
        let stages = try YAMLDecoder().decode([StageDTO].self, from: data)

        return stages
    }


    private static func parseEventInfo(fromDirectory url: URL) async throws -> EventInfoDTO {
        @Dependency(\.fileManager) var fileManager

        let urls = try fileManager.contentsOfDirectory(in: url)
       
        guard let eventInfoURL = urls.first(where: { $0.lastPathComponent == "event-info.yaml" })
        else { throw ValidationFailure.noEventInfoFile }


        let data = try Data(contentsOf: eventInfoURL)
        let eventDTO = try YAMLDecoder().decode(EventInfoDTO.self, from: data)

        return eventDTO
    }

    private static func parseContactInfo(fromDirectory url: URL) async throws -> [ContactInfoDTO] {
       []
    }
}
