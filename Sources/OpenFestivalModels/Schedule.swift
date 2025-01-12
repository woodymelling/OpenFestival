//
//  Schedule.swift
//  OpenFestival
//
//  Created by Woodrow Melling on 1/11/25.
//

import MemberwiseInit
import Foundation
import OrderedCollections


public extension Event {
//    typealias Schedule = IdentifiedArrayOf<DailySchedule>

    /// A  collection of Performances indexed for each artist, and each schedule page.
    /// This allows for O(1) access to all Performances associated with an artist or with a stage/date combination,
    /// at the cost of additional space complexity, and an O(N) index generation at each update
    struct Schedule: Equatable, RandomAccessCollection, Sendable {

        @MemberwiseInit(.public)
        public struct PageKey: Hashable, Codable, Sendable {
            public var date: CalendarDate
            public var stageID: Stage.ID
        }

        public typealias PerformanceStore = IdentifiedArrayOf<Performance>

        private var performances: PerformanceStore

        private var artistIndex: [Artist.ID : Set<Performance.ID>]
        private var schedulePageIndex: [PageKey : Set<Performance.ID>]
        public let dayStartsAtNoon: Bool

        public init(
            performances: IdentifiedArrayOf<DailySchedule>
        ) {
            self.dayStartsAtNoon = true
            var artistIndex: [Artist.ID : Set<Performance.ID>] = [:]
            var schedulePageIndex: [PageKey : Set<Performance.ID>] = [:]
            var items = PerformanceStore()

            for performance in performances {

//                items[id: Performance.id] = Performance
//
//                // Populate schedule page index
//                schedulePageIndex.insert(
//                    key: Performance.schedulePageIdentifier(dayStartsAtNoon: dayStartsAtNoon, timeZone: timeZone),
//                    value: Performance.id
//                )
//
//                // Populate artistPage index
//                switch Performance.type {
//                case .artistSet(let artistID):
//                    artistIndex.insert(key: artistID, value: Performance.id)
//                case .groupSet(let artistIDs):
//                    for artistID in artistIDs {
//                        artistIndex.insert(key: artistID, value: Performance.id)
//                    }
//                }
            }

            self.artistIndex = artistIndex
            self.schedulePageIndex = schedulePageIndex
            self.performances = items
        }

        public subscript(artistID artistID: Artist.ID) -> OrderedSet<Performance> {
            guard let performanceIds = artistIndex[artistID] else { return .init() }

            return performanceIds.reduce(into: OrderedSet()) { partialResult, PerformanceID in
                if let Performance = performances[id: PerformanceID] {
                    partialResult.append(Performance)
                }
            }
        }

        public subscript(page schedulePage: PageKey) -> IdentifiedArrayOf<Performance> {
            get {
                guard let performanceIds = schedulePageIndex[schedulePage] else { return .init() }

                return IdentifiedArray(uncheckedUniqueElements: performanceIds.reduce(into: OrderedSet()) { partialResult, PerformanceID in
                    if let Performance = performances[id: PerformanceID] {
                        partialResult.append(Performance)
                    }
                })
            }
        }

        public subscript(day day: DailySchedule.ID) -> DailySchedule? {
            get {
                fatalError()
//                IdentifiedArray(uniqueElements: self.Performances.filter {
//                    $0.isOnDate(day.date, dayStartsAtNoon: false)
//                })
            }
        }

        public subscript(id id: Performance.ID) -> Performance? {
            performances[id: id]
        }


        public typealias Index = Int
        public typealias Element = DailySchedule

        public var startIndex: Index {
            fatalError()
//            return Performances.startIndex
        }

        public var endIndex: Index {
            fatalError()
//            return Performances.endIndex
        }

        public subscript(position: Index) -> Element {
            get {
                fatalError()
//                Performances[position]
            }
        }

        public func index(after i: Index) -> Index {
            fatalError()
//            Performances.index(after: i)
        }
    }

    struct DailySchedule: Identifiable, Hashable, Sendable {
        public init(
            id: Tagged<Self, OpenFestivalIDType>,
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

        public init(
            metadata: Metadata,
            stageSchedules: [Stage.ID : [Performance]]
        ) {
            self.metadata = metadata
            self.stageSchedules = stageSchedules
        }

        public struct Metadata: Identifiable, Equatable, Hashable, Sendable {
            public init(
                id: Tagged<DailySchedule, OpenFestivalIDType>,
                date: CalendarDate? = nil,
                customTitle: String? = nil
            ) {
                self.id = id
                self.date = date
                self.customTitle = customTitle
            }

            public var id: Tagged<DailySchedule, OpenFestivalIDType>
            public var date: CalendarDate?
            public var customTitle: String?
        }

        public var id: Metadata.ID { metadata.id }
        public var metadata: Metadata

        public var stageSchedules: [Stage.ID : [Performance]]

        public var name: String {
            metadata.customTitle ?? metadata.date?.description ?? "Unknown Schedule"
        }
    }

}
extension Event.Schedule: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Event.DailySchedule...) {
        // TODO:
        fatalError("")
    }
}
