//
//  File.swift
//  
//
//  Created by Woody on 2/10/22.
//

import Foundation
import Tagged
import IdentifiedCollections
import MemberwiseInit
import Collections

public typealias OpenFestivalIDType = String

@MemberwiseInit(.public)
public struct Organization {
    public var id: Tagged<Self, OpenFestivalIDType>

    public struct Info: Decodable {

        public init(name: String, imageURL: URL? = nil) {
            self.name = name
            self.imageURL = imageURL
        }

        public var name: String
        public var imageURL: URL?
    }

    public var info: Info
    public var events: [Event]
}

@MemberwiseInit(.public)
public struct Event: Identifiable, Equatable {
    public var id: Tagged<Event, OpenFestivalIDType> //
    public var name: String //
    public var timeZone: TimeZone

    public var imageURL: URL? = nil
    public var siteMapImageURL: URL? = nil

    public var address: String? = nil
    public var latitude: String? = nil
    public var longitude: String? = nil

    public var contactNumbers: IdentifiedArrayOf<ContactNumber> = []
    public var artists: IdentifiedArrayOf<Artist>
    public var stages: Stages
    public var schedule: Schedule
    public var colorScheme: ColorScheme?
}

public extension Event {
    @MemberwiseInit(.public)
    struct ContactNumber: Identifiable, Equatable, Codable, Hashable {
        public var id: String = UUID().uuidString
        public var phoneNumber: String
        public var title: String
        public var description: String

        public init(title: String, phoneNumber: String, description: String) {
            self.title = title
            self.phoneNumber = phoneNumber
            self.description = description
        }
    }
}

public extension Event {
    typealias Stages = IdentifiedArrayOf<Stage>

    @MemberwiseInit(.public)
    struct Stage: Identifiable, Equatable, Hashable {
        public var id: Tagged<Event, OpenFestivalIDType>
        public var name: String
        public var iconImageURL: URL?
    }
}

public extension Event {
    typealias StageDaySchedule = IdentifiedArrayOf<Performance>

    struct Schedule: Equatable, Hashable {
        typealias UnderlyingStore = [Performance.ID : Performance]
        private let store: UnderlyingStore

        public init(days: [Day]) {
            var artistIndex: ArtistIndex = [:]
            var pageIndex: PageIndex = [:]
            var performances: UnderlyingStore = [:]
            var dayMetadatas: [Day.Metadata] = []

            for day in days {
                var stageSchedulesIndex: [Stage.ID : [Performance.ID]] = [:]

                dayMetadatas.append(day.metadata)

                for (stage, stageSchedule) in day.stageSchedules {
                    for performance in stageSchedule {
                        performances[performance.id] = performance
                        stageSchedulesIndex[stage].appendOrCreate(value: performance.id)

                        for artistID in performance.artistIDs {
                            artistIndex[artistID].appendOrCreate(value: performance.id)
                        }
                    }
                }

                pageIndex[day.id] = stageSchedulesIndex
            }

            self.store = performances
            self.artistIndex = artistIndex
            self.pageIndex = pageIndex
            self.dayMetadatas = IdentifiedArray(uniqueElements: dayMetadatas.sorted(by: \.date, then: \.id))
        }

        public subscript(id performanceID: Performance.ID) -> Performance? {
            self.store[performanceID]
        }

        typealias ArtistIndex = [Artist.ID : [Performance.ID]]
        private let artistIndex: ArtistIndex
        public subscript(for artistID: Artist.ID) -> [Performance] {
            (artistIndex[artistID] ?? [])
                .compactMap { store[$0] }
        }

        typealias PageIndex = [Day.ID: [Stage.ID: [Performance.ID]]]
        private let pageIndex: PageIndex
        public subscript(on day: Day.ID, at stage: Stage.ID) -> [Performance] {
            let result = (pageIndex[day]?[stage] ?? [])
                .compactMap { store[$0] }

            return result
        }

        public subscript(on day: Day.ID) -> [Performance] {
            (pageIndex[day] ?? [:])
                .flatMap { $0.value }
                .compactMap { store[$0] }
        }

        public var performances: Set<Performance> {
            Set(self.store.values)
        }

        public func dayFor(_ performance: Event.Performance.ID) -> Day.ID? {
            pageIndex.first { 
                $0.value.values.flatMap { $0 }.contains(performance)
            }?.key
        }

        public struct Day: Identifiable, Equatable {
            public init(
                id: Tagged<Day, OpenFestivalIDType>,
                date: CalendarDate? = nil,
                customTitle: String? = nil,
                stageSchedules: [Stage.ID : [Performance]]
            ) {
                self.metadata = Metadata(
                    id: id,
                    date: date,
                    customTitle: customTitle
                )

                self.stageSchedules = stageSchedules
            }

            public struct Metadata: Identifiable, Equatable, Hashable {
                public var id: Tagged<Day, OpenFestivalIDType>
                public var date: CalendarDate?
                public var customTitle: String?
            }

            public var id: Metadata.ID { metadata.id }
            public var metadata: Metadata

            public var stageSchedules: [Stage.ID : [Performance]]
        }

        public let dayMetadatas: IdentifiedArrayOf<Day.Metadata>
    }
}

public extension Event {
    @MemberwiseInit(.public)
    struct Performance: Identifiable, Equatable, Hashable {
        public var id: Tagged<Performance, OpenFestivalIDType>
        public var customTitle: String?
        public var artistIDs: OrderedSet<Artist.ID>
        public var startTime: Date
        public var endTime: Date
        public var stageID: Stage.ID
    }
}

#if canImport(SwiftUI)
import SwiftUI
#endif

public extension Event {
    @MemberwiseInit(.public)
    struct Artist: Identifiable, Equatable, Hashable {
        public var id: Tagged<Event, String>
        public var name: String
        public var bio: String?
        public var imageURL: URL?
        public var links: [Link]

        @MemberwiseInit(.public)
        public struct Link: Equatable, Hashable {
            public var url: URL
            public var label: String?
        }
    }

    @MemberwiseInit(.public)
    struct ColorScheme: Equatable {
        #if canImport(SwiftUI)
        public typealias Color = SwiftUI.Color
        #else
        public typealias Color = String
        #endif

        public var mainColor: Color
        public var workshopsColor: Color
        public var stageColors: StageColorStore
        public var otherColors: [Color]

        public struct StageColorStore: Equatable {
            public init(_ colors: [(Stage.ID, Color)]) {
                self.stageColors = colors.reduce(into: [:]) {
                    $0[$1.0] = $1.1
                }
            }

            public init(stages: [Stage.ID], color: (Stage.ID) -> Color) {
                self.stageColors = stages.reduce(into: [:]) {
                    $0[$1] = color($1)
                }
            }

            private let stageColors: [Stage.ID : Color]

            public subscript(stageID: Stage.ID) -> Color {
                return self.stageColors[stageID] ?? .blue
            }
        }

    }
}


public extension Event {
    static var empty: Self {
        .init(
            id: "",
            name: "",
            timeZone: .current,
            artists: [],
            stages: [],
            schedule: .init(days: []),
            colorScheme: nil
        )
    }

    static var testival: Self {
        .init(
            id: .init("testival"),
            name: "Testival",
            timeZone: .current,
            siteMapImageURL: URL(string: "https://firebasestorage.googleapis.com/v0/b/festivl.appspot.com/o/userContent%2FSite%20Map.webp?alt=media&token=48272d3c-ace0-4d5b-96a9-a5142f1c744a"),
            address: "1234 Pine Ave, Somewhere in the forest",
            artists: [
                Artist(
                    id: Tagged(rawValue: "Subsonic"),
                    name: "Subsonic",
                    bio: "Subsonic delivers powerful bass-driven music that shakes the ground and moves the crowd, known for their high-energy performances and deep, resonant beats.",
                    imageURL: URL(string: "https://firebasestorage.googleapis.com/v0/b/festivl.appspot.com/o/userContent%2FSubsonic.webp?alt=media&token=8b732938-f9c7-4216-8fb5-3ff4acad9384"),
                    links: []
              ),
              Artist(
                id: Tagged(rawValue: "Phantom Groove"),
                name: "Phantom Groove",
                bio: nil,
                imageURL: nil,
                links: []
              ),
              Artist(
                id: Tagged(rawValue: "Sunspear"),
                name: "Sunspear",
                bio: nil,
                imageURL: URL(string: "https://firebasestorage.googleapis.com/v0/b/festivl.appspot.com/o/userContent%2FSunspear-image.webp?alt=media&token=be30f499-8356-41a9-9425-7e19e36e2ea9")!,
                links: []
              ),
              Artist(
                id: Tagged(rawValue: "Rhythmbox"),
                name: "Rhythmbox",
                bio: nil,
                imageURL: nil,
                links: []
              ),
              Artist(
                id: Tagged(rawValue: "Prism Sound"),
                name: "Prism Sound",
                bio: nil,
                imageURL: nil,
                links: []
              ),
              Artist(
                id: Tagged(rawValue: "Oaktrail"),
                name: "Oaktrail",
                bio: nil,
                imageURL: URL(string: "https://firebasestorage.googleapis.com/v0/b/festivl.appspot.com/o/userContent%2FOaktrail.webp?alt=media&token=db962b24-e144-476c-ac4c-71ffa7f7f32d"),
                links: []
              ),
              Artist(
                id: Tagged(rawValue: "Space Chunk"),
                name: "Space Chunk",
                bio: nil,
                imageURL: URL(string: "https://i1.sndcdn.com/avatars-oI73KB5SpEOGCmFq-5ezWjw-t500x500.jpg")!,
                links: [
                    .init(url: URL(string: "https://soundcloud.com/spacechunk")!, label: nil)
                ]
              ),
              Artist(
                id: Tagged(rawValue: "The Sleepies"),
                name: "The Sleepies",
                bio: nil,
                imageURL: nil,
                links: []
              ),
              Artist(
                id: Tagged(rawValue: "Sylvan Beats"),
                name: "Sylvan Beats",
                bio: nil,
                imageURL: nil,
                links: []
              ),
              Artist(
                id: Tagged(rawValue: "Overgrowth"),
                name: "Overgrowth",
                bio: nil,
                imageURL: URL(string: "https://firebasestorage.googleapis.com/v0/b/festivl.appspot.com/o/userContent%2FOvergrowth%20DJ%20Profile.webp?alt=media&token=f0856acd-ab9c-47bf-b1d8-d7e385048beb"),
                links: [
                    .init(url: URL(string: "https://soundcloud.com/overgrowthmusic")!, label: nil)
                ]
              ),
              Artist(
                id: Tagged(rawValue: "Floods"),
                name: "Floods",
                bio: nil,
                imageURL: URL(string: "https://firebasestorage.googleapis.com/v0/b/festivl.appspot.com/o/userContent%2FFloods.webp?alt=media&token=2fca7492-7de5-4390-bf9a-d9fe7eb55cd8"),
                links: []
              ),
              Artist(
                id: Tagged(rawValue: "Float On"),
                name: "Float On",
                bio: nil,
                imageURL: nil,
                links: []
              ),
                Artist(
                    id: Tagged(rawValue: "Caribou State"),
                    name: "Caribou State",
                    bio: nil,
                    imageURL: nil,
                    links: []
                )
            ],
            stages: [
                Stage(
                    id: "Fractal Forest",
                    name: "Fractal Forest",
                    iconImageURL: URL(string: "https://firebasestorage.googleapis.com:443/v0/b/festivl.appspot.com/o/userContent%2F0545133C-90A6-4A64-99F9-EA563A8E976E.png?alt=media&token=35509f1f-a977-47d2-bd76-2d3898d0e465")
                ),

                Stage(
                    id: "Village",
                    name: "Village",
                    iconImageURL: URL(string: "https://firebasestorage.googleapis.com:443/v0/b/festivl.appspot.com/o/userContent%2F96A24076-86EB-4327-BC13-26B3A8B1B769.png?alt=media&token=cb596866-35e6-4e39-a018-004b7338d7e8")
                ),
                Stage(
                    id: "Pagoda",
                    name: "Pagoda",
                    iconImageURL: URL(string: "https://firebasestorage.googleapis.com:443/v0/b/festivl.appspot.com/o/userContent%2F980B90FE-4868-4E65-B0B8-045A54BEFBD2.png?alt=media&token=91037e7e-5702-424d-a4f5-f0c78c5c9fde")
                )

            ],
            schedule: .init(
                        days: [
                            Schedule.Day(
                                id: .init("FileName"),
                                date: CalendarDate(year: 2024, month: 6, day: 16),
                                customTitle: nil,
                                stageSchedules: [
                                    "Fractal Forest": [
                                        Event.Performance(
                                            id: .init("Sunspear-16:30-Fractal Forest"),
                                            customTitle: nil,
                                            artistIDs: ["Sunspear"],
                                            startTime: Date(year: 2024, month: 6, day: 12, hour: 16, minute: 30)!,
                                            endTime: Date(year: 2024, month: 6, day: 12, hour: 18, minute: 30)!,
                                            stageID: Event.Stage.ID(rawValue: "Fractal Forest")
                                        ),
                                        Event.Performance(
                                            id: .init("Phantom Groove-18:30-Fractal Forest"),
                                            customTitle: nil,
                                            artistIDs: ["Phantom Groove"],
                                            startTime: Date(year: 2024, month: 6, day: 12, hour: 18, minute: 30)!,
                                            endTime: Date(year: 2024, month: 6, day: 12, hour: 20)!,
                                            stageID: Event.Stage.ID(rawValue: "Fractal Forest")
                                        ),
                                        Event.Performance(
                                            id: .init("Caribou State-20:00-Fractal Forest"),
                                            customTitle: nil,
                                            artistIDs: ["Caribou State"],
                                            startTime: Date(year: 2024, month: 6, day: 12, hour: 20)!,
                                            endTime: Date(year: 2024, month: 6, day: 12, hour: 21, minute: 30)!,
                                            stageID: Event.Stage.ID(rawValue: "Fractal Forest")
                                        ),
                                        // Additional performances for other artists
                                        Event.Performance(
                                            id: .init("Subsonic-21:30-Fractal Forest"),
                                            customTitle: nil,
                                            artistIDs: ["Subsonic"],
                                            startTime: Date(year: 2024, month: 6, day: 12, hour: 21, minute: 30)!,
                                            endTime: Date(year: 2024, month: 6, day: 12, hour: 23)!,
                                            stageID: Event.Stage.ID(rawValue: "Fractal Forest")
                                        )
                                    ],
                                    "Pagoda": [
                                        Event.Performance(
                                            id: .init("Oaktrail-20:00-Pagoda"),
                                            customTitle: nil,
                                            artistIDs: ["Oaktrail"],
                                            startTime: Date(year: 2024, month: 6, day: 12, hour: 20)!,
                                            endTime: Date(year: 2024, month: 6, day: 12, hour: 22)!,
                                            stageID: Event.Stage.ID(rawValue: "Pagoda")
                                        ),
                                        Event.Performance(
                                            id: .init("Rhythmbox-22:00-Pagoda"),
                                            customTitle: nil,
                                            artistIDs: ["Rhythmbox"],
                                            startTime: Date(year: 2024, month: 6, day: 12, hour: 22)!,
                                            endTime: Date(year: 2024, month: 6, day: 12, hour: 23, minute: 30)!,
                                            stageID: Event.Stage.ID(rawValue: "Pagoda")
                                        ),
                                        Event.Performance(
                                            id: .init("Prism Sound-23:30-Pagoda"),
                                            customTitle: nil,
                                            artistIDs: ["Prism Sound"],
                                            startTime: Date(year: 2024, month: 6, day: 12, hour: 23, minute: 30)!,
                                            endTime: Date(year: 2024, month: 6, day: 13, hour: 1)!,
                                            stageID: Event.Stage.ID(rawValue: "Pagoda")
                                        )
                                    ],
                                    "Village": [
                                        // Performances for artists on Village stage
                                        Event.Performance(
                                            id: .init("Space Chunk-17:00-Village"),
                                            customTitle: nil,
                                            artistIDs: ["Space Chunk"],
                                            startTime: Date(year: 2024, month: 6, day: 12, hour: 17)!,
                                            endTime: Date(year: 2024, month: 6, day: 12, hour: 18, minute: 30)!,
                                            stageID: Event.Stage.ID(rawValue: "Village")
                                        ),
                                        Event.Performance(
                                            id: .init("The Sleepies-18:30-Village"),
                                            customTitle: nil,
                                            artistIDs: ["The Sleepies"],
                                            startTime: Date(year: 2024, month: 6, day: 12, hour: 18, minute: 30)!,
                                            endTime: Date(year: 2024, month: 6, day: 12, hour: 20)!,
                                            stageID: Event.Stage.ID(rawValue: "Village")
                                        ),
                                        Event.Performance(
                                            id: .init("Sylvan Beats-20:00-Village"),
                                            customTitle: nil,
                                            artistIDs: ["Sylvan Beats"],
                                            startTime: Date(year: 2024, month: 6, day: 12, hour: 20)!,
                                            endTime: Date(year: 2024, month: 6, day: 12, hour: 21, minute: 30)!,
                                            stageID: Event.Stage.ID(rawValue: "Village")
                                        ),
                                        Event.Performance(
                                            id: .init("Overgrowth-21:30-Village"),
                                            customTitle: nil,
                                            artistIDs: ["Overgrowth"],
                                            startTime: Date(year: 2024, month: 6, day: 12, hour: 21, minute: 30)!,
                                            endTime: Date(year: 2024, month: 6, day: 12, hour: 23)!,
                                            stageID: Event.Stage.ID(rawValue: "Village")
                                        ),
                                        Event.Performance(
                                            id: .init("Floods-23:00-Village"),
                                            customTitle: nil,
                                            artistIDs: ["Floods"],
                                            startTime: Date(year: 2024, month: 6, day: 12, hour: 23)!,
                                            endTime: Date(year: 2024, month: 6, day: 13, hour: 0, minute: 30)!,
                                            stageID: Event.Stage.ID(rawValue: "Village")
                                        ),
                                        Event.Performance(
                                            id: .init("Float On-0:30-Village"),
                                            customTitle: nil,
                                            artistIDs: ["Float On", "Floods"],
                                            startTime: Date(year: 2024, month: 6, day: 13, hour: 0, minute: 30)!,
                                            endTime: Date(year: 2024, month: 6, day: 13, hour: 2)!,
                                            stageID: Event.Stage.ID(rawValue: "Village")
                                        )
                                    ]
                                ]
                            )
                        ]
            ),
            colorScheme: .init(
                mainColor: .accentColor,
                workshopsColor: .accentColor,
                stageColors: .init(
                    [
                        ("Pagoda", .red),
                        ("Fractal Forest", .orange),
                        ("Village", .yellow)
                    ]
                ),
                otherColors: [
                    .blue,
                    .cyan,
                    .green,
                    .yellow,
                    .orange,
                    .red
                ]
            )
        )
    }
}

import Foundation

extension Date {
    init?(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0,
        minute: Int = 0,
        second: Int = 0,
        calendar: Calendar = .current
    ){
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        dateComponents.hour = hour
        dateComponents.minute = minute
        dateComponents.second = second

        if let date = calendar.date(from: dateComponents) {
            self = date
            return
        }

        return nil
    }
}





extension Optional where Wrapped: RangeReplaceableCollection {
    mutating func appendOrCreate(value: Wrapped.Element) {
        if self != nil {
            self?.append(value)
        } else {
            self = Wrapped([value])
        }
    }
}



extension Sequence {
    func sorted<PrimaryKey: Comparable, SecondaryKey: Comparable>(
        by primaryKeyPath: KeyPath<Element, PrimaryKey?>,
        then secondaryKeyPath: KeyPath<Element, SecondaryKey>
    ) -> [Element] {
        return sorted { lhs, rhs in
            if let lhsPrimary = lhs[keyPath: primaryKeyPath], let rhsPrimary = rhs[keyPath: primaryKeyPath] {
                if lhsPrimary != rhsPrimary {
                    return lhsPrimary < rhsPrimary
                }
            } else if lhs[keyPath: primaryKeyPath] != nil {
                return true
            } else if rhs[keyPath: primaryKeyPath] != nil {
                return false
            }
            return lhs[keyPath: secondaryKeyPath] < rhs[keyPath: secondaryKeyPath]
        }
    }
}

