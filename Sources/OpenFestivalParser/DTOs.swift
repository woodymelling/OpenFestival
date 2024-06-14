//
//  File.swift
//  
//
//  Created by Woodrow Melling on 5/29/24.
//

import Foundation
import OpenFestivalModels
import MemberwiseInit

struct EventDTO {
    var eventInfo: EventInfoDTO
    var contactInfo: [ContactInfoDTO]?
    var stages: [StageDTO]
    var artists: [ArtistDTO]
    var schedule: Schedule
}

extension EventDTO {
    struct Schedule: Decodable, Equatable {
        var daySchedules: [DaySchedule]
    }

    @MemberwiseInit
    struct DaySchedule: Decodable, Equatable {
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
                self.performances = try keyedContainer.decode([String: [PerformanceDTO]].self, forKey: .performances)
            }
        }

        enum CodingKeys: String, CodingKey {
            case date
            case performances
        }
    }
}

struct EventInfoDTO: Decodable, Equatable {
    var name: String
    var address: String?
    var timeZone: String?

    var imageURL: URL?
    var siteMapImageURL: URL?

    var colorScheme: ColorScheme?

    struct ColorScheme: Equatable, Decodable {
        var primaryColor: String?
        var workshopsColor: String?
    }
}

struct StageDTO: Decodable, Equatable {
    var name: String
    var color: String?
    var imageURL: URL?
}

struct ContactInfoDTO: Decodable, Equatable {
    var phoneNumber: String
    var title: String
    var description: String?
}

struct PerformanceDTO: Decodable, Equatable {
    var title: String?
    var artist: String?
    var artists: [String]?
    var time: String
    var endTime: String?
}

struct ArtistDTO {
    var name: String
    var description: String
    var imageURL: URL?
    var links: [Link]


    struct Link: Decodable, Equatable {
        var url: URL
        var label: String?
    }
}

public struct ArtistInfoFrontMatter: Decodable, Equatable {
    var imageURL: URL?
    var links: [ArtistDTO.Link]
}
