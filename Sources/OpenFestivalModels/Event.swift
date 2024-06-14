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
public struct Event: Identifiable, Equatable {
    public var id: Tagged<Event, OpenFestivalIDType> //
    public var name: String //
    public var timeZone: TimeZone

    public var imageURL: URL? = nil
    public var siteMapImageURL: URL? = nil
    public var address: String? = nil

    public var contactNumbers: IdentifiedArrayOf<ContactNumber> = []
    public var artists: IdentifiedArrayOf<Artist>
    public var stages: Stages
    public var schedule: Schedule
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
    typealias DaySchedule = [Stage.ID: IdentifiedArrayOf<Performance>]

    @MemberwiseInit(.public)
    struct Schedule: Equatable, Hashable {
        public let days: [DaySchedule]
    }

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
}

