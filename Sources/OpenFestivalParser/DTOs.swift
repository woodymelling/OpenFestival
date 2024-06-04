//
//  File.swift
//  
//
//  Created by Woodrow Melling on 5/29/24.
//

import Foundation

struct EventDTO {
    typealias ScheduleDay = [String: [PerformanceDTO]]
    typealias Schedule = [String: ScheduleDay]

    var eventInfo: EventInfoDTO
    var stages: [StageDTO]
    var contactInfo: [ContactInfoDTO]?
    var schedule: Schedule
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
