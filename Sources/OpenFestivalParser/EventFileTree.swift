//
//  FileTree.swift
//  OpenFestival
//
//  Created by Woodrow Melling on 9/30/24.
//

@preconcurrency import FileTree
import OpenFestivalModels
import Yams
import IssueReporting
import Collections
import Conversions
import Foundation

extension Organization {
    @FileTreeBuilder
    var fileTree: some FileTreeViewable {
        Organization.Info.file

        Directory("schedules") {
            Directory.Many {
                EventFileTree()
            }
        }
    }
}

// MARK: Organization
extension Organization.Info {
    static var file: some FileTreeViewable<Organization.Info> {
        File("organization-info", .yaml)
            .convert {
                Conversions.YamlConversion<Self.YamlRepresentation>()

                Convert {
                    Organization.Info(
                        name: $0.name,
                        imageURL: $0.imageURL
                    )
                } unapply: { 
                    YamlRepresentation(
                        name: $0.name,
                        imageURL: $0.imageURL,
                        address: nil,
                        timeZone: nil,
                        siteMapImageURL: nil,
                        colorScheme: nil
                    )
                }
            }
    }

    struct YamlRepresentation: Codable, Equatable {
        var name: String
        var imageURL: URL?
        var address: String?
        var timeZone: String?
        var siteMapImageURL: URL?
        var colorScheme: ColorScheme?
    }
}

typealias Convert = AnyConversion

public enum EventTag: Hashable, Sendable {
    case file(File)
    case directory(Directory)

    public enum File: Hashable, Sendable {
        case eventInfo
        case contactInfo
        case stages
        case schedule(Event.Schedule.ID)
        case artist(Event.Artist.ID)
    }

    public enum Directory: Hashable, Sendable {
        case schedules, artists
    }
}

// MARK: Event
public struct EventFileTree: FileTreeViewable {
    public init() {}

    public var body: some FileTreeComponent<Event> & FileTreeViewable {
        FileTree {
            File("event-info", .yaml)
                .convert(Conversions.YamlConversion(EventInfoDTO.self))
                .tag(EventTag.file(.eventInfo))

            File("contact-info", .yaml)
                .convert(ContactInfoConversion())
                .tag(EventTag.file(.contactInfo))

            File("stages", .yaml)
                .convert(StagesConversion())
                .tag(EventTag.file(.stages))

            Directory("schedules") {
                File.Many(withExtension: .yaml)
                    .map(ScheduleConversion())
                    .tag { EventTag.file(.schedule($0.id)) }

            }
            .tag(EventTag.directory(.schedules))

            Directory("artists") {
                File.Many(withExtension: "md")
                    .map(ArtistConversion())
                    .tag { EventTag.file(.artist($0.id)) }
            }
            .tag(EventTag.directory(.artists))
        }
        .convert(EventConversion())
    }

    struct ScheduleConversion: Conversion {
        var body: some Conversion<FileContent<Data>, StringlyTyped.Schedule> {
            FileContentConversion {
                Conversions.YamlConversion(DTOs.Event.DaySchedule.self)
            }

            ScheduleDayConversion()
        }
    }

    struct EventConversion: Conversion {
        typealias Input = (EventInfoDTO, [Event.ContactNumber], [Event.Stage], [StringlyTyped.Schedule], [Event.Artist])
        typealias Output = Event

        func apply(_ input: Input) throws -> Event {
            let artists = input.4
            let artistIDForName = Dictionary(uniqueKeysWithValues: artists.map { ($0.name, $0.id) })

            let stages = input.2
            let stageIDForName = Dictionary(uniqueKeysWithValues: stages.map { ($0.name, $0.id) } )

            let schedule = input.3.map {
                Event.Schedule(
                    id: $0.id,
                    date: $0.metadata.date,
                    customTitle: $0.metadata.customTitle,
                    stageSchedules: Dictionary(
                        uniqueKeysWithValues: $0.stageSchedules.compactMap { stageName, performances in
                            guard let stageID = stageIDForName[stageName]
                            else {
                                reportIssue("No stage found for \(stageName)")
                                return nil
                            }

                            let performance = performances.map {
                                let artistIDs: [Event.Performance.ArtistReference] = $0.artistNames.map {
                                    artistIDForName[$0].map { .known($0) } ?? .anonymous(name: $0)
                                }

                                return Event.Performance(
                                    id: $0.id,
                                    customTitle: $0.customTitle,
                                    artistIDs: OrderedSet(artistIDs),
                                    startTime: $0.startTime,
                                    endTime: $0.endTime,
                                    stageID: stageID
                                )
                            }

                            return (stageID, performance)
                        }


                    )
                )
            }

            return Event(
                id: .init(),
                name: input.0.name ?? "",
                // TODO?
                timeZone: try TimeZoneConversion().apply(input.0.timeZone) ?? TimeZone.current,
                imageURL: input.0.imageURL,
                siteMapImageURL: input.0.siteMapImageURL,
                address: input.0.address,
                // TODO:
                latitude: nil,
                longitude: nil,
                contactNumbers: input.1,
                artists: IdentifiedArray(uniqueElements: input.4),
                stages: IdentifiedArray(uniqueElements: input.2),
                schedule: IdentifiedArray(uniqueElements: schedule),
                colorScheme: nil // TODO:
            )
        }

        func unapply(_ output: Event) throws -> Input {
            let schedules = output.schedule.map {

                StringlyTyped.Schedule(
                    metadata: $0.metadata,
                    stageSchedules: Dictionary(
                        uniqueKeysWithValues: $0.stageSchedules.map { stageID, performances in
                            guard let stageName = output.stages[id: stageID]?.name else {
                                fatalError("Missing stage name for \(stageID)")
                            }
                            let stringlyTypedPerformances = performances.map { performance in
                                StringlyTyped.Schedule.Performance(
                                    id: performance.id,
                                    artistNames: OrderedSet(performance.artistIDs.compactMap {
                                        switch $0 {
                                        case .known(let artistID):
                                            output.artists[id: artistID]?.name
                                        case .anonymous(let artistName):
                                            artistName
                                        }
                                    }),
                                    startTime: performance.startTime,
                                    endTime: performance.endTime,
                                    stageName: stageName
                                )
                            }

                            return (stageName, stringlyTypedPerformances)
                        })
                )
            }

            return (
                EventInfoDTO(
                    name: output.name,
                    address: output.address,
                    timeZone: output.timeZone.identifier,
                    imageURL: output.imageURL,
                    siteMapImageURL: output.siteMapImageURL,
                    colorScheme: nil
                ),
                output.contactNumbers,
                Array(output.stages),
                schedules,
                Array(output.artists)
            )
        }

        struct TimeZoneConversion: Conversion {
            typealias Input = String?
            typealias Output = TimeZone?

            func apply(_ input: String?) throws -> TimeZone? {
                input.flatMap(TimeZone.init(identifier:)) ?? input.flatMap(TimeZone.init(abbreviation:))
            }

            func unapply(_ output: TimeZone?) throws -> String? {
                output.map { $0.identifier }
            }
        }
    }


    struct StagesConversion: Conversion {
        var body: some Conversion<Data, [Event.Stage]> {
            Conversions.YamlConversion([StageDTO].self)
                .mapValues {
                    Event.Stage(
                        id: .init(),
                        name: $0.name,
                        iconImageURL: $0.imageURL
                    )
                } unapply: {
                    StageDTO(
                        name: $0.name,
                        color: nil, // Needs to get set from the Event Color Scheme?
                        imageURL: $0.iconImageURL
                    )
                }
        }
    }

    struct ContactInfoConversion: Conversion {
        typealias Input = Data
        typealias Output = [Event.ContactNumber]

        var body: some Conversion<Data, [Event.ContactNumber]> {
            Conversions.YamlConversion([ContactInfoDTO].self)
            Conversions.MapValues(ContactNumberDTOConversion())
        }


        struct ContactNumberDTOConversion: Conversion {
            typealias Input = ContactInfoDTO
            typealias Output = Event.ContactNumber
            func apply(_ input: Input) throws -> Output {
                Event.ContactNumber(
                    id: .init(),
                    phoneNumber: input.phoneNumber,
                    title: input.title,
                    description: input.description
                )
            }

            func unapply(_ output: Output) throws -> Input {
                ContactInfoDTO(
                    phoneNumber: output.phoneNumber,
                    title: output.title,
                    description: output.description
                )
            }
        }
    }
}

extension Event {
    
}


extension Dictionary {
    func mapValuesWithKeys<NewValue>(_ transform: (Key, Value) -> NewValue) -> [Key: NewValue] {
        Dictionary<Key, NewValue>(uniqueKeysWithValues: self.map { ($0, transform($0, $1))})
    }
}

extension Tagged {
    struct Conversion: Parsing.Conversion {
        typealias Input = RawValue
        typealias Output = Tagged<Tag, RawValue>

        func apply(_ input: RawValue) throws -> Tagged<Tag, RawValue> {
            Tagged(input)
        }

        func unapply(_ output: Tagged<Tag, RawValue>) throws -> RawValue {
            output.rawValue
        }
    }
}


typealias Identity = Conversions.Identity

extension DTOs.Event.DaySchedule {
    struct TupleConversion: Conversion {
        typealias Input = DTOs.Event.DaySchedule
        typealias Output = (String?, CalendarDate?, [String: [PerformanceDTO]])

        func apply(_ input: Input) throws -> Output {
            (input.customTitle, input.date, input.performances)
        }

        func unapply(_ output: Output) throws -> Input {
            .init(
                customTitle: output.0,
                date: output.1,
                performances: output.2
            )
        }
    }
}

extension Conversions {
    struct FatalError<Input, Output>: Conversion {
        func apply(_ input: Input) throws -> Output {
            fatalError()
        }

        func unapply(_ output: Output) throws -> Input {
            fatalError()
        }
    }
}

extension Conversion {
    func mapValues<OutputElement: Sendable, NewOutput: Sendable>(
        apply: @Sendable @escaping (OutputElement) throws -> NewOutput,
        unapply: @Sendable @escaping (NewOutput) throws -> OutputElement
    ) -> some Conversion<Input, [NewOutput]> where Output == [OutputElement] {
        self.map(Conversions.MapValues(AnyConversion(apply: apply, unapply: unapply)))
    }

    func mapValues<OutputElement: Sendable, NewOutput: Sendable, C>(
        _ conversion: some Conversion<OutputElement, NewOutput>
    ) -> some Conversion<Input, [NewOutput]>
    where Output == [OutputElement] {
        self.map(Conversions.MapValues(conversion))
    }

    func mapValues<OutputElement: Sendable, NewOutput: Sendable, C>(
        @ConversionBuilder _ conversion: () -> some Conversion<OutputElement, NewOutput>
    ) -> some Conversion<Input, [NewOutput]>
    where Output == [OutputElement] {
        self.map(Conversions.MapValues(conversion))
    }
}


extension FileExtension {
    static let markdown: FileExtension = "md"
}

struct ArtistConversion: Conversion {
    var body: some Conversion<FileContent<Data>, Event.Artist> {
        FileContentConversion {
            Conversions.DataToString()
            MarkdownWithFrontMatterConversion<ArtistInfoFrontMatter>()
        }

        FileToArtistConversion()
    }

    struct FileToArtistConversion: Conversion {
        typealias Input = FileContent<MarkdownWithFrontMatter<ArtistInfoFrontMatter>>
        typealias Output = Event.Artist

        func apply(_ input: Input) throws -> Output {
            Event.Artist(
                id: .init(),
                name: input.fileName,
                bio: input.data.body,
                imageURL: input.data.frontMatter?.imageURL,
                links: (input.data.frontMatter?.links ?? []).map { .init(url: $0.url, label: $0.label )}
            )
        }

        func unapply(_ output: Output) throws -> Input {
            FileContent(
                fileName: output.name,
                data: MarkdownWithFrontMatter(
                    frontMatter: ArtistInfoFrontMatter(
                        imageURL: output.imageURL,
                        links: output.links.map { .init(url: $0.url, label: $0.label )}
                    ).nilIfEmpty,
                    body: output.bio?.nilIfEmpty
                )
            )
        }
    }
}



import Foundation

import Parsing
import Conversions
import OpenFestivalModels


struct OpenFestivalDecoder {
    public func decode(from url: URL) async throws -> Event {
        return try await EventFileTree().read(from: url)
    }

}


extension Collection {
    var nilIfEmpty: Self? {
        self.isEmpty ? nil : self
    }
}

extension ArtistInfoFrontMatter {
    var nilIfEmpty: Self? {
        if self.imageURL == nil && self.links.isEmpty {
            return nil
        } else {
            return self
        }

    }
}
