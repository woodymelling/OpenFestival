////
////  File.swift
////  
////
////  Created by Woodrow Melling on 5/29/24.
////
//
//import Foundation
//import Validated
//import OpenFestivalModels
//import Dependencies
//import Collections
//import Prelude
//import SwiftUI
//
enum Validation: Error {
    case stage(Stage)
    case generic
    case schedule(ScheduleError)
    case artist

    enum Stage: Error {
        case generic
    }

    enum ScheduleError: Error {
        case daySchedule(DayScheduleError)
    }
}

//struct OrganizationMapper: ValidatedMapper {
//    typealias From = OrganizationDTO
//    typealias To = Organization
//    typealias ToError = Validation
//
//    func map(_ dto: OrganizationDTO) -> Output {
//        return dto
//            .events
//            .map { EventMapper().map($0) }
//            .sequence()
//            .map { events in
//                Organization(
//                    info: .init(
//                        name: dto.info.name,
//                        imageURL: dto.info.imageURL
//                    ),
//                    events: events
//                )
//            }
//    }
//}
//
//struct EventMapper: ValidatedMapper {
//    typealias From = EventDTO
//    typealias To = Event
//    typealias ToError = Validation
//
//    func map(_ dto: EventDTO) -> Output {
//        zip(
//            StagesMapper().map(dto.stages).mapErrors { Validation.stage($0) },
//            ArtistsMapper().map(dto.artists).mapErrors { _ in .artist },
//            ScheduleMapper().map(dto.schedule).mapErrors { Validation.schedule($0) },
//            TimeZoneMapper().map(dto.eventInfo.timeZone).mapErrors { _ in .generic },
//            ContactInfoMapper().map(dto.contactInfo ?? []).mapErrors { _ in .generic }
//        )
//        .map { stages, artists, schedule, timeZone, contactInfo in
//            var artists = artists
//            addArtistsFromSchedule(to: &artists, schedule: schedule)
//            
//            return Event(
//                name: dto.eventInfo.name ?? "",
//                timeZone: timeZone,
//                imageURL: dto.eventInfo.imageURL,
//                siteMapImageURL: dto.eventInfo.siteMapImageURL,
//                address: dto.eventInfo.address,
//                latitude: nil,
//                longitude: nil,
//                contactNumbers: contactInfo,
//                artists: artists,
//                stages: stages,
//                schedule: schedule,
//                colorScheme: extractColorScheme(from: dto, stages: stages)
//            )
//        }
//    }
//
//    private func addArtistsFromSchedule(
//        to artists: inout IdentifiedArrayOf<Event.Artist>,
//        schedule: Event.Schedule
//    ) {
//        for artistID in schedule.performances.flatMap(\.artistIDs) {
//            if artists[id: artistID] == nil {
//                artists[id: artistID] = Event.Artist(
//                    name: artistID.rawValue,
//                    bio: nil,
//                    imageURL: nil,
//                    links: []
//                )
//            }
//        }
//    }
//
//    private func extractColorScheme(
//        from dto: EventDTO,
//        stages: Event.Stages
//    ) -> Event.ColorScheme? {
//        let stageColors = dto.stages.compactMap { stage in
//            stage.color.map {
//                (
//                    Event.Stage.ID(stage.name),
//                    SwiftUI.Color(hex: $0)
//                )
//            }
//        }
//
//        guard stages.count == stageColors.count,
//              let primaryColor = dto.eventInfo.colorScheme?.primaryColor,
//              let workshopsColor = dto.eventInfo.colorScheme?.workshopsColor
//        else { return nil }
//
//        return Event.ColorScheme(
//            mainColor: Color(hex: primaryColor),
//            workshopsColor: Color(hex: workshopsColor),
//            stageColors: .init(stageColors),
//            otherColors: stageColors.map { $0.1 }
//        )
//    }
//}
//
//struct StagesMapper: ValidatedMapper {
//    typealias From = [StageDTO]
//    typealias To = IdentifiedArrayOf<Event.Stage>
//    typealias ToError = Validation.Stage
//
//    func map(_ dtos: [StageDTO]) -> Output {
//        .valid(
//            IdentifiedArray(
//                uniqueElements: dtos.map {
//                    Event.Stage(
//                        name: $0.name,
//                        iconImageURL: $0.imageURL
//                    )
//                }
//            )
//        )
//    }
//}
//
//struct ContactInfoMapper: ValidatedMapper {
//    typealias From = [ContactInfoDTO]
//    typealias To = [Event.ContactNumber]
//    typealias ToError = Never
//
//    func map(_ dtos: [ContactInfoDTO]) -> Output {
//        .valid(
//            dtos.map {
//                Event.ContactNumber(title: $0.title, phoneNumber: $0.phoneNumber, description: $0.description)
//            }
//        )
//    }
//}
//
//
//struct TimeZoneMapper: ValidatedMapper {
//    typealias From = String?
//    typealias To = TimeZone
//    typealias ToError = Error
//
//    func map(_ dto: String?) -> Output {
//        @Dependency(\.timeZone) var timeZone
//
//        return .valid(
//            dto.flatMap(TimeZone.init(identifier:))
//            ?? dto.flatMap(TimeZone.init(abbreviation:))
//            ?? timeZone
//        )
//    }
//}
//
//struct ArtistsMapper: ValidatedMapper {
//    typealias From = [ArtistDTO]
//    typealias To = IdentifiedArrayOf<Event.Artist>
//    typealias ToError = Error
//
//    func map(_ dtos: [ArtistDTO]) -> Output {
//        .valid(
//            IdentifiedArray(uniqueElements: dtos.map {
//                Event.Artist(
//                    name: $0.name,
//                    bio: $0.description,
//                    imageURL: $0.imageURL,
//                    links: $0.links.map { Event.Artist.Link(url: $0.url, label: $0.label) }
//                )
//            })
//        )
//    }
//}
//
