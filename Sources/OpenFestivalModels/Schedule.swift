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

        private var performances: [Performance.ID: Performance]
        private var artistIndex: [Artist.ID : Set<Performance.ID>]
        private var dailySchedules: IdentifiedArrayOf<DailySchedule>

        public let dayStartsAtNoon: Bool

        public init(dailySchedules: IdentifiedArrayOf<DailySchedule>) {

            var artistIndex: [Artist.ID: Set<Performance.ID>] = [:]
            var performances: [Performance.ID: Performance] = [:]


            for performance in dailySchedules.flatMap(\.stageSchedules).flatMap(\.value) {
                performances[performance.id] = performance

                for artistRef in performance.artistIDs {
                    switch artistRef {
                    case .known(let artistID):
                        artistIndex[artistID, default: []].insert(performance.id)
                    case .anonymous:
                        // Possibly skip, or handle differently (e.g. store them in a separate dictionary)
                        break
                    }
                }
            }

            self.dailySchedules = dailySchedules
            self.performances = performances
            self.artistIndex = artistIndex
            self.dayStartsAtNoon = true
        }

        public subscript(artistID artistID: Artist.ID) -> OrderedSet<Performance> {
            guard let performanceIds = artistIndex[artistID] else { return .init() }

            return performanceIds.reduce(into: OrderedSet()) { partialResult, performanceID in
                if let performance = performances[performanceID] {
                    partialResult.append(performance)
                }
            }
        }

        public subscript(day day: DailySchedule.ID) -> DailySchedule? {
            get {
                dailySchedules[id: day]
            }
        }

        public subscript(id id: Performance.ID) -> Performance? {
            performances[id]
        }


        public typealias Index = Int
        public typealias Element = DailySchedule

        public var startIndex: Index {
            dailySchedules.startIndex
        }

        public var endIndex: Index {
            dailySchedules.endIndex
        }

        public subscript(position: Index) -> Element {
            get { dailySchedules[position] }
        }

        public func index(after i: Index) -> Index {
            dailySchedules.index(after: i)
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
