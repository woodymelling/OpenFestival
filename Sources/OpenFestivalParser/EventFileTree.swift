//
//  FileTree.swift
//  OpenFestival
//
//  Created by Woodrow Melling on 9/30/24.
//

import FileTree
import OpenFestivalModels
import Yams

extension Organization {
    static let fileTree = FileTree {
        File("organization-info", .yaml)

        Many {
            Directory($0) {
                EventFileTree()
            }
        }
    }
}

struct EventFileTree: FileTreeComponent {
    typealias FileType = Event

    var body: some FileTreeComponent<Event> {
        FileTree {
            StaticFile("event-info", .yaml)
                .map(Conversions.YamlConversion(EventInfoDTO.self))

            StaticFile("contact-info", .yaml)
                .map(ContactInfoConversion())

            StaticFile("stages", .yaml)
                .map(StagesConversion())

            StaticDirectory("schedules") {
                Many {
                    File($0, .yaml)
                        .map {
                            FileContentConversion {
                                Conversions.YamlConversion(EventDTO.DaySchedule.self)
                            }
                            
                            ScheduleDayConversion()
                        }
                }
            }

            StaticDirectory("artists") {
                Many {
                    File($0, .markdown)
                        .map(ArtistConversion())
                }
            }
        }
        .map(EventConversion())
    }

    struct EventConversion: Conversion {

        typealias Input = (EventInfoDTO, [Event.ContactNumber], [Event.Stage], [Event.Schedule.Day], [Event.Artist])
        typealias Output = Event

        func apply(_ input: Input) throws -> Event {
            Event(
                name: input.0.name ?? "",
                // TODO?
                timeZone: try TimeZoneConversion().apply(input.0.timeZone) ?? TimeZone.current,
                imageURL: input.0.imageURL,
                siteMapImageURL: input.0.siteMapImageURL,
                address: input.0.address,
                latitude: nil,
                // TODO:
                longitude: nil,
                contactNumbers: input.1,
                artists: IdentifiedArray(uniqueElements: input.4),
                stages: IdentifiedArray(uniqueElements: input.2),
                schedule: Event.Schedule(days: input.3),
                colorScheme: nil // TODO:
            )
        }

        func unapply(_ output: Event) throws -> Input {
            fatalError()
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


    struct StagesConversion: AsyncConversion {
        var body: some AsyncConversion<Data, [Event.Stage]> {
            Conversions.YamlConversion([StageDTO].self)
                .mapValues {
                    Event.Stage(name: $0.name, iconImageURL: $0.imageURL)
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

func makeIDs(from items: String?...) -> String {
    items.compactMap(\.self).joined(separator: "-")
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

extension EventDTO.DaySchedule {
    struct TupleConversion: Conversion {
        typealias Input = EventDTO.DaySchedule
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
    func mapValues<OutputElement, NewOutput>(
        apply: @Sendable @escaping (OutputElement) throws -> NewOutput,
        unapply: @Sendable @escaping (NewOutput) throws -> OutputElement
    ) -> some Conversion<Input, [NewOutput]> where Output == [OutputElement] {
        self.map(Conversions.MapValues(AnyConversion(apply: apply, unapply: unapply)))
    }

    func mapValues<OutputElement, NewOutput, C>(
        _ conversion: some Conversion<OutputElement, NewOutput>
    ) -> some Conversion<Input, [NewOutput]>
    where Output == [OutputElement] {
        self.map(Conversions.MapValues(conversion))
    }

    func mapValues<OutputElement, NewOutput, C>(
        @ConversionBuilder _ conversion: () -> some Conversion<OutputElement, NewOutput>
    ) -> some Conversion<Input, [NewOutput]>
    where Output == [OutputElement] {
        self.map(Conversions.MapValues(conversion))
    }
}


extension FileExtension {
    static var markdown: FileExtension = "md"
}

struct ArtistConversion: Conversion {
    var body: some Conversion<FileContent<Data>, Event.Artist> {
        FileContentConversion {
            Conversions.DataToString()
            MarkdownWithFrontMatterConversion<ArtistInfoFrontMatter>()
        }

        FileToArtistConversion()
    }
}

extension ArtistConversion {
    struct FileToArtistConversion: Conversion {
        typealias Input = FileContent<MarkdownWithFrontMatter<ArtistInfoFrontMatter>>
        typealias Output = Event.Artist

        func apply(_ input: FileContent<MarkdownWithFrontMatter<ArtistInfoFrontMatter>>) throws -> Event.Artist {
            Event.Artist(
                name: input.fileName,
                bio: input.data.body,
                imageURL: input.data.frontMatter?.imageURL,
                links: (input.data.frontMatter?.links ?? []).map { .init(url: $0.url, label: $0.label )}
            )
        }

        func unapply(_ output: Event.Artist) throws -> FileContent<MarkdownWithFrontMatter<ArtistInfoFrontMatter>> {
            FileContent(
                fileName: output.name,
                data: MarkdownWithFrontMatter(
                    frontMatter: ArtistInfoFrontMatter(
                        imageURL: output.imageURL,
                        links: output.links.map { .init(url: $0.url, label: $0.label )}
                    ).nilIfEmpty,
                    body: output.bio ?? ""
                )
            )
        }
    }
}



import Foundation

struct OpenFestivalDecoder {
    public func decode(from url: URL) async throws -> Event {
        return try await EventFileTree().read(from: url)
    }

}

import Parsing
import OpenFestivalModels


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
