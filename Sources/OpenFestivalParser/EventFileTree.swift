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
                .map(YamlConversion(EventInfoDTO.self))

            StaticFile("contact-info", .yaml)
                .map(ContactInfoConversion())

            StaticFile("stages", .yaml)
                .map(StagesConversion())

            StaticDirectory("schedules") {
                Many {
                    File($0, .yaml)
                        .map(ScheduleDayConversion())
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
            fatalError()
        }

        func unapply(_ output: Event) throws -> Input {
            fatalError()
        }
    }


    struct StagesConversion: Conversion {
        var body: some Conversion<Data, [Event.Stage]> {

            YamlConversion([StageDTO].self)
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

            YamlConversion([ContactInfoDTO].self)
                .mapValues {
                    Event.ContactNumber(
                        phoneNumber: $0.phoneNumber,
                        title: $0.title,
                        description: $0.description
                    )
                } unapply: {
                    ContactInfoDTO(
                        phoneNumber: $0.phoneNumber,
                        title: $0.title,
                        description: $0.description
                    )
                }
        }
    }

    struct ScheduleDayConversion: Conversion {
        typealias Input = FileContent<Data>
        typealias Output = Event.Schedule.Day

        var body: some Conversion<Input, Output> {

            FileContentConversion {
                YamlConversion(EventDTO.DaySchedule.self)

                EventDTO.DaySchedule.Tuple()

                Conversions.Tuple(
                    Identity<String?>(),
                    Identity<CalendarDate?>(),
                    ScheduleDictionaryConversion()
                )
            }

            FileContentTupleScheduleDayConversion()
        }


        struct ScheduleDictionaryConversion: Conversion {
            typealias Input = [String: [PerformanceDTO]]
            typealias Output = [Event.Stage.ID: [Event.Performance]]

            var body: some Conversion<Input, Output> {
                Conversions.MapKVPairs(
                    keyConversion: Event.Stage.ID.Conversion(),
                    valueConversion: Convert {
                        Conversions.MapValues {
                            TimelessStagelessPerformanceConversion()
                        }

                        StagelessPerformanceConversion()
                    }
                )

                StagedPerformanceConversion()
            }
        }


        struct StagelessPerformanceConversion: Conversion {
            typealias Input = [TimelessStagelessPerformance]
            typealias Output = [StagelessPerformance]

            func apply(_ input: [TimelessStagelessPerformance]) throws -> [StagelessPerformance] {
                fatalError()
            }

            func unapply(_ output: [StagelessPerformance]) throws -> [TimelessStagelessPerformance] {
                fatalError()
            }
        }

        struct StagedPerformanceConversion: Conversion {
            typealias Input = [Event.Stage.ID: [StagelessPerformance]]
            typealias Output = [Event.Stage.ID: [Event.Performance]]

            func apply(_ input: Input) throws -> Output {
                fatalError()
            }

            func unapply(_ output: Output) throws -> Input {
                fatalError()
            }
        }

        struct FileContentTupleScheduleDayConversion: Conversion {
            typealias Input = FileContent<(String?, CalendarDate?, [Event.Stage.ID: [Event.Performance]])>
            typealias Output = Event.Schedule.Day

            func apply(_ input: Input) throws -> Output {
                fatalError()
            }

            func unapply(_ output: Output) throws -> Input {
                fatalError()
            }
        }
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
    struct Tuple: Conversion {
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
        apply: @escaping (OutputElement) throws -> NewOutput,
        unapply: @escaping (NewOutput) throws -> OutputElement
    ) -> some Conversion<Input, [NewOutput]> where Output == [OutputElement] {
        self.map(Conversions.MapValues(Convert(apply: apply, unapply: unapply)))
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


extension Conversions {
    public struct MapValues<C: Conversion>: Conversion {
        var transform: C

        public init(_ transform: C) {
            self.transform = transform
        }

        public init(@ConversionBuilder _ build: () -> C) {
            self.transform = build()
        }

        public func apply(_ input: [C.Input]) throws -> [C.Output] {
            try input.map(transform.apply)
        }

        public func unapply(_ output: [C.Output]) throws -> [C.Input] {
            try output.map(transform.unapply)
        }
    }


    public struct MapKVPairs<KeyConversion: Conversion, ValueConversion: Conversion>: Conversion where KeyConversion.Input: Hashable, KeyConversion.Output: Hashable {
        public typealias Input = [KeyConversion.Input: ValueConversion.Input]
        public typealias Output = [KeyConversion.Output: ValueConversion.Output]

        var keyConversion: KeyConversion
        var valueConversion: ValueConversion

        public func apply(_ input: Input) throws -> Output {
            Dictionary(uniqueKeysWithValues: try input.map {
                try (keyConversion.apply($0.0), valueConversion.apply($0.1))
            })

        }

        public func unapply(_ output: Output) throws -> Input {
            Dictionary(uniqueKeysWithValues: try Output().map {
                try (keyConversion.unapply($0.0), valueConversion.unapply($0.1))
            })
        }
    }
}

public struct Convert<Input, Output>: Conversion {
    var _apply: (Input) throws -> Output
    var _unapply: (Output) throws -> Input

    init(apply: @escaping (Input) throws -> Output, unapply: @escaping (Output) throws -> Input) {
        self._apply = apply
        self._unapply = unapply
    }

    init(@ConversionBuilder build: () -> some Conversion<Input, Output>) {
        let conversion = build()
        self._apply = conversion.apply
        self._unapply = conversion.unapply
    }

    
    public func apply(_ input: Input) throws -> Output {
        try self._apply(input)
    }

    public func unapply(_ output: Output) throws -> Input {
        try self._unapply(output)
    }
}

extension FileExtension {
    static var markdown: FileExtension = "md"
}


struct ArtistConversion: Conversion {
    var body: some Conversion<FileContent<Data>, Event.Artist> {
        FileContentConversion {
            DataStringConversion()
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
