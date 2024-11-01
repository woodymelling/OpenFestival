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

import CustomDump
extension Conversion {
    func _printChanges() -> some Conversion<Input, Output> {
        Convert(
            apply: {
                
                customDump($0, name: "Before \(Self.self).apply")
                let result = try self.apply($0)
                customDump(result, name: "After \(Self.self).apply")

                return result
            },
            unapply: {
                customDump($0, name: "Before \(Self.self).unapply")
                let result = try self.unapply($0)
                customDump(result, name: "After \(Self.self) unapply")
                return result
            }
        )
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
                        .map {
                            FileContentConversion {
                                YamlConversion(EventDTO.DaySchedule.self)
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
        typealias Input = FileContent<EventDTO.DaySchedule>
        typealias Output = Event.Schedule.Day

        var body: some Conversion<Input, Output> {

            FileContentConversion {
                EventDTO.DaySchedule.TupleConversion()

                Conversions.Tuple(
                    Identity<String?>(),
                    Identity<CalendarDate?>(),
                    ScheduleDictionaryConversion()
                )
            }

            FileContentToTupleScheduleDayConversion()

        }


        struct ScheduleDictionaryConversion: Conversion {
            typealias Input = [String: [PerformanceDTO]]
            typealias Output = [Event.Stage.ID: [StagelessPerformance]]

            var body: some Conversion<Input, Output> {
                Conversions.MapKVPairs(
                    keyConversion: Event.Stage.ID.Conversion(),
                    valueConversion: StagelessPerformanceConversion()
                )
            }

            struct StagelessPerformanceConversion: Conversion {
                typealias Input = [PerformanceDTO]
                typealias Output = [StagelessPerformance]
                var body: some Conversion<Input, Output> {
                    Conversions.MapValues {
                        TimelessStagelessPerformanceConversion()
                    }

                    DetermineFullSetTimesConversion()

                }
            }
        }


        struct DetermineFullSetTimesConversion: Conversion {
            typealias Input = [TimelessStagelessPerformance]
            typealias Output = [StagelessPerformance]

            func apply(_ partialPerformances: Input) throws(Validation.ScheduleError.StageDayScheduleError) -> Output {
                var schedule: [StagelessPerformance] = []
                var scheduleStartTime: ScheduleTime?

                for (index, performance) in partialPerformances.enumerated() {
                    var startTime = performance.startTime
                    var endTime: ScheduleTime

                    // End times can be manually set
                    if let staticEndTime = performance.endTime {
                        endTime = staticEndTime

                        // If they aren't, find the next performance, and make the endtime butt up against it
                    } else if let nextPerformance = partialPerformances[safe: index + 1] {
                        endTime = nextPerformance.startTime

                        // If there aren't any performances after this, we can't determine the endtime
                    } else {
                        throw .cannotDetermineEndTimeForPerformance(performance)
                    }

                    if let scheduleStartTime {
                        if startTime < scheduleStartTime {
                            startTime.hour += 24
                        }

                        if endTime < scheduleStartTime {
                            endTime.hour += 24
                        }
                    } else {
                        scheduleStartTime = startTime
                        if endTime < startTime {
                            endTime.hour += 24
                        }
                    }

                    schedule.append(StagelessPerformance(
                        customTitle: performance.customTitle,
                        artistIDs: performance.artistIDs,
                        startTime: startTime,
                        endTime: endTime
                    ))
                }

                for (index, performance) in schedule.enumerated() {
                    guard let nextPerformance = schedule[safe: index + 1]
                    else { continue }

                    guard performance.endTime <= nextPerformance.startTime
                    else { throw .overlappingPerformances(performance, nextPerformance) }

                    guard performance.startTime < performance.endTime
                    else { throw .endTimeBeforeStartTime(performance) }
                }

                return schedule
            }

            func unapply(_ performances: [StagelessPerformance]) throws -> [TimelessStagelessPerformance] {
                var schedule = performances.map {
                    TimelessStagelessPerformance(
                        startTime: $0.startTime,
                        endTime: $0.endTime,
                        customTitle: $0.customTitle,
                        artistIDs: $0.artistIDs
                    )
                }

                // remove end times for schedules that butt up against each other.
                for (index, performance) in schedule.enumerated() {
                    if let nextPerformance = performances[safe: index + 1],
                       performance.endTime == nextPerformance.startTime {
                        schedule[index].endTime = nil
                    }
                }

                return schedule
            }
        }

        struct StagedPerformanceConversion: Conversion {
            typealias Input = [Event.Stage.ID: [StagelessPerformance]]
            typealias Output = [Event.Stage.ID: [Event.Performance]]

            func apply(_ input: Input) throws -> Output {
                input.mapValuesWithKeys { key, value in
                    value.map {
                        Event.Performance(
                            id: "\($0.customTitle ?? "")-\($0.artistIDs.map(\.rawValue).joined(separator: "-"))-\($0.startTime)-\($0.endTime)",
                            customTitle: $0.customTitle,
                            artistIDs: $0.artistIDs,
                            startTime: Date(), // TODO:
                            endTime: Date(), // TODO:
                            stageID: key
                        )
                    }
                }
            }

            func unapply(_ output: Output) throws -> Input {
                output.mapValues {
                    $0.map {
                        StagelessPerformance(
                            customTitle: $0.customTitle,
                            artistIDs: $0.artistIDs,
                            startTime: ScheduleTime(from: $0.startTime),
                            endTime: ScheduleTime(from: $0.endTime)
                        )
                    }
                }
            }
        }

        struct FileContentToTupleScheduleDayConversion: Conversion {
            typealias Input = FileContent<(String?, CalendarDate?, [Event.Stage.ID: [StagelessPerformance]])>
            typealias Output = Event.Schedule.Day

            func apply(_ input: Input) throws -> Output {
                let customTitle = input.data.0
                let scheduleDate = input.data.1 ?? CalendarDate(input.fileName) ?? .today // Default to today if nothing is provided

                let schedule = input.data.2.mapValuesWithKeys { key, value in
                    value.map {
                        Event.Performance(
                            id: .init(
                                makeIDs(
                                    from: $0.customTitle,
                                    $0.artistIDs.map(\.rawValue).joined(separator: "-"),
                                    String(describing: $0.startTime),
//                                    String(describing: $0.endTime),
                                    key.rawValue
                                )
                            ),
                            customTitle: $0.customTitle,
                            artistIDs: $0.artistIDs,
                            startTime: scheduleDate.atTime($0.startTime),
                            endTime: scheduleDate.atTime($0.endTime),
                            stageID: key
                        )
                    }
                }

                return Event.Schedule.Day(
                    id: .init(makeIDs(from: customTitle, String(describing: scheduleDate))),
                    date: scheduleDate,
                    customTitle: input.data.0,
                    stageSchedules: schedule
                )
            }

            func unapply(_ output: Output) throws -> Input {
                FileContent(
                    fileName: output.metadata.date?.description ?? output.metadata.customTitle ?? "schedule",
                    data: (output.metadata.customTitle, output.metadata.date, output.stageSchedules.mapValues {
                        $0.map {
                            StagelessPerformance(
                                customTitle: $0.customTitle,
                                artistIDs: $0.artistIDs,
                                startTime: ScheduleTime(from: $0.startTime),
                                endTime: ScheduleTime(from: $0.endTime)
                            )
                        }
                    })
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
            Dictionary(uniqueKeysWithValues: try output.map {
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

    init<C: Conversion<Input, Output>>(@ConversionBuilder build: () -> C) {
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
