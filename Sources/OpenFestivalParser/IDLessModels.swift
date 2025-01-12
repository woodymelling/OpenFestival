//
//  IDLessModels.swift
//  OpenFestival
//
//  Created by Woodrow Melling on 11/17/24.
//

import Foundation
import OpenFestivalModels
import Collections

enum StringlyTyped {

    struct Schedule: Hashable, Identifiable {
        var id: Event.DailySchedule.ID { metadata.id }
        var metadata: Event.DailySchedule.Metadata
        var stageSchedules: [String : [Performance]]

        struct Performance: Hashable, Identifiable {
            var id: Event.Performance.ID
            var customTitle: String?
            var artistNames: OrderedSet<String>
            var startTime: Date
            var endTime: Date
            var stageName: String
        }
    }
}
