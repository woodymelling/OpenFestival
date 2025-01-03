//
//  File.swift
//  
//
//  Created by Woodrow Melling on 5/29/24.
//

import Foundation
import OpenFestivalModels
import MemberwiseInit


enum DTOs {}

extension DTOs {
    struct Organization {
        struct Info: Codable, Equatable {
            var name: String
            var imageURL: URL?
            var address: String?
            var timeZone: String?
            var siteMapImageURL: URL?
            var colorScheme: ColorScheme?
        }

        var info: Info
        var events: [Event]
    }

    struct Event {
        var eventInfo: EventInfoDTO
        var contactInfo: [ContactInfoDTO]?
        var stages: [StageDTO]
        var artists: [ArtistDTO]
        var schedule: Schedule
    }
}

extension DTOs.Event {
    struct Schedule: Decodable, Equatable {
        var daySchedules: [String : DaySchedule]
    }

    @MemberwiseInit
    struct DaySchedule: Codable, Equatable {
        var customTitle: String?
        var date: CalendarDate? // This could be defined in the yaml, or from the title of the file
        var performances: [String: [PerformanceDTO]]
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            
            if let rawPerformances = try? container.decode([String: [PerformanceDTO]].self) {
                self.date = nil
                self.performances = rawPerformances
            } else {
                let keyedContainer = try decoder.container(keyedBy: CodingKeys.self)
                self.date = try? keyedContainer.decode(CalendarDate.self, forKey: .date)
                self.customTitle = try? keyedContainer.decode(String.self, forKey: .date)
                self.performances = try keyedContainer.decode([String: [PerformanceDTO]].self, forKey: .performances)
            }
        }

        enum CodingKeys: String, CodingKey {
            case date
            case customTitle
            case performances
        }
    }
}

struct ColorScheme: Equatable, Codable {
    var primaryColor: String?
    var workshopsColor: String?
}

struct EventInfoDTO: Codable, Equatable {
    var name: String?
    var address: String?
    var timeZone: String?

    var imageURL: URL?
    var siteMapImageURL: URL?

    var colorScheme: ColorScheme?

    var contactNumber: [ContactInfoDTO]
}

struct StageDTO: Codable, Equatable {
    var name: String
    var color: String?
    var imageURL: URL?
}

struct ContactInfoDTO: Codable, Equatable {
    var phoneNumber: String
    var title: String
    var description: String?
}

struct PerformanceDTO: Codable, Equatable {
    var title: String?
    var artist: String?
    var artists: [String]?
    var time: String
    var endTime: String?
}

struct ArtistDTO: Sendable {
    var name: String
    var description: String
    var imageURL: URL?
    var links: [Link]


    struct Link: Codable, Equatable, Sendable {
        var url: URL
        var label: String?
    }
}

public struct ArtistInfoFrontMatter: Codable, Equatable {
    var imageURL: URL?
    var links: [ArtistDTO.Link]
}
