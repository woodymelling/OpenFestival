import Foundation
import Yams
import CustomDump
import OpenFestivalModels

import Dependencies
import DependenciesMacros

@DependencyClient
public struct OpenFestivalParser {
    public var parse: (_ from: URL) async throws -> Organization

    public func parse(from path: String) async throws -> Organization {
        try await self.parse(from: URL(fileURLWithPath: path))
    }
}

extension OpenFestivalParser {
    enum ValidationFailure: Error, CustomStringConvertible {
        case noEventInfoFile(URL)
        case noSchedulesDirectory
        case noStagesFile
        case noContactInfoFile
        case noOrganizationInfoFile

        var description: String {
            switch self {
            case .noEventInfoFile(let url): "No event-info.yaml file found in \(url.absoluteString)"
            case .noOrganizationInfoFile: "No organization-info.yaml file found in the provided directory"
            case .noSchedulesDirectory: "No schedule directory found in the provided directory"
            case .noStagesFile: "No stages.yaml file found in the provided directory"
            case .noContactInfoFile: "No contact-info.yaml file found in the provided directory"
            }
        }
    }
}

extension OpenFestivalParser: DependencyKey {
    public static var liveValue: OpenFestivalParser {
        OpenFestivalParser(
            parse: Self.parseOrganization(from:)
        )
    }
}

extension OpenFestivalParser {
    private static func parseOrganizationDTO(from path: URL) async throws -> OrganizationDTO {
        @Dependency(\.fileManager) var fileManager

        let eventURLS = try fileManager
            .contentsOfDirectory(in: path)
            .filter { $0.hasDirectoryPath }
            .filter { $0.lastPathComponent.first != "." }


        async let events = withThrowingTaskGroup(of: EventDTO.self) {
            for url in eventURLS {
                $0.addTask {
                    try await parseEventDTO(fromPath: url)
                }
            }

            return try await $0.reduce(into: [EventDTO]()) { $0.append($1) }
        }

        async let organizationInfo = parseOrganizationInfo(from: path)

        return try await OrganizationDTO(
            info: organizationInfo,
            events: events
        )
    }

    private static func parseOrganizationInfo(from path: URL) throws -> OrganizationDTO.OrganizationInfo {
        @Dependency(\.fileManager) var fileManager

        let urls = try fileManager.contentsOfDirectory(in: path)

        guard let organizationInfo = urls.first(where: { $0.lastPathComponent == "organization-info.yaml" })
        else { throw ValidationFailure.noOrganizationInfoFile }

        print("Decoding Orgainzation Info from `\(organizationInfo.absoluteString)`...")

        let data = try Data(contentsOf: organizationInfo)
        let orgInfo = try YAMLDecoder().decode(OrganizationDTO.OrganizationInfo.self, from: data)

        return orgInfo
    }


    private static func parseOrganization(from path: URL) async throws -> Organization {
        let organizationDTO = try await parseOrganizationDTO(from: path)
        
        switch OrganizationMapper().map(organizationDTO) {
        case let .valid(organization): return organization
        case let .invalid(errors): throw errors.first
        }
    }
//    private static func parseEvent(from path: URL) async throws -> Event {
//        let eventDTO = try await parseEventDTO(fromPath: path)
//
//        print("Properly parsed files, attempting to extract schedule info...")
//
//        switch EventMapper().map(eventDTO) {
//        case let .valid(event): return event
//        case let .invalid(errors): throw errors.first // TODO
//        }
//    }

    private static func parseEventDTO(fromPath url: URL) async throws -> EventDTO {

        async let eventInfo = parseEventInfo(fromDirectory: url)
        async let contactInfo = parseContactInfo(fromDirectory: url)
        async let stages = try await parseStages(fromDirectory: url)
        async let artists = try await parseArtists(fromDirectory: url)
        async let schedule = try await parseSchedule(fromDirectory: url)
        return try await .init(
            eventInfo: eventInfo,
            contactInfo: contactInfo,
            stages: stages,
            artists: artists,
            schedule: schedule
        )
    }

    private static func parseSchedule(fromDirectory url: URL) async throws -> EventDTO.Schedule {
        @Dependency(\.fileManager) var fileManager

        let urls = try fileManager.contentsOfDirectory(in: url.appendingPathComponent("schedule"))
       
        let schedule = try EventDTO.Schedule(daySchedules: urls.reduce(into: [:]) { partialResults, url in
            let data = try Data(contentsOf: url)
            let daySchedule = try YAMLDecoder().decode(EventDTO.DaySchedule.self, from: data)
            let fileName = url.deletingPathExtension().lastPathComponent

            partialResults[fileName] = daySchedule
        })

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
        else { throw ValidationFailure.noEventInfoFile(url) }

        let data = try Data(contentsOf: eventInfoURL)
        var eventDTO = try YAMLDecoder().decode(EventInfoDTO.self, from: data)
        
        if eventDTO.name == nil {
            eventDTO.name = url.lastPathComponent
        }

        return eventDTO
    }

    private static func parseArtists(fromDirectory url: URL) async throws -> [ArtistDTO] {
        @Dependency(\.fileManager) var fileManager
        let artistDirectoryURL = url.appendingPathComponent("artists")
        let fileURLs: [URL]
        do {
            fileURLs = try fileManager.contentsOfDirectory(in: artistDirectoryURL)
        } catch {
            return []
        }

        return try fileURLs.compactMap { fileURL in
            let data = try Data(contentsOf: fileURL)
            guard let markdown = String(data: data, encoding: .utf8) else {
                throw NSError(domain: "InvalidData", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to convert data to string"])
            }

            let decoder = MarkdownWithFrontmatterDecoder()
            let decoded = try decoder.decode(ArtistInfoFrontMatter.self, from: markdown)
            return ArtistDTO(
                name: fileURL.deletingPathExtension().lastPathComponent,
                description: decoded.body,
                imageURL: decoded.frontMatter?.imageURL,
                links: decoded.frontMatter?.links ?? []
            )
        }
    }

    private static func parseContactInfo(fromDirectory url: URL) async throws -> [ContactInfoDTO] {
        @Dependency(\.fileManager) var fileManager
        let urls = try fileManager.contentsOfDirectory(in: url)

        guard let contactInfoURL = urls.first(where: { $0.lastPathComponent == "contact-info.yaml" })
        else { return [] }

        let data = try Data(contentsOf: contactInfoURL)
        let contactInfo = try YAMLDecoder().decode([ContactInfoDTO].self, from: data)

        return contactInfo
    }
}
