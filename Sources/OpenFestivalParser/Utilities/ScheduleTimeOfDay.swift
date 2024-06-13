//
//  File.swift
//  
//
//  Created by Woodrow Melling on 6/5/24.
//

import Foundation

struct ScheduleTime: Codable {
    var hour: Int
    var minute: Int

    init?(hour: Int = 0, minute: Int = 0) {
        guard (0..<48).contains(hour),
              (0..<60).contains(minute)
        else { return nil }

        self.hour = hour
        self.minute = minute
    }

    init(from date: Date) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second], from: date)
        self.hour = components.hour ?? 0
        self.minute = components.minute ?? 0
    }

    init?(from timeString: String, using formatter: DateFormatter) {
        guard let date = formatter.date(from: timeString) else {
            return nil
        }
        formatter.timeZone = .init(secondsFromGMT: 0)!
        var calendar = Calendar.autoupdatingCurrent
        calendar.timeZone = .init(secondsFromGMT: 0)!
        let components = calendar.dateComponents([.hour, .minute, .second], from: date)
        self.hour = components.hour ?? 0
        self.minute = components.minute ?? 0
    }

    func toDateComponents() -> DateComponents {
        return DateComponents(hour: hour, minute: minute)
    }

    func formattedString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.timeZone = .init(secondsFromGMT: 0)
        guard let date = Calendar.current.date(from: toDateComponents()) else {
            return ""
        }
        return formatter.string(from: date)
    }

    static let dayMinutes = 24 * 60 // Total minutes in a day

    var minutesAfterMidnight: Int {
        (hour * 60) + minute
    }


    func isAfter(_ other: Self, maximumDistance: Int = 720) -> Bool {
        return if minutesAfterMidnight == other.minutesAfterMidnight {
            false
        } else if self.minutesAfterMidnight > other.minutesAfterMidnight {
            true
        } else {
            other.minutesAfterMidnight - self.minutesAfterMidnight > maximumDistance
        }
    }

    func isAtSameTimeOrAfter(_ other: Self, maximumDistance: Int = 720) -> Bool {
        guard minutesAfterMidnight != other.minutesAfterMidnight
        else { return true }

        return isAfter(other, maximumDistance: maximumDistance)
    }
}

extension ScheduleTime: CustomStringConvertible {
    var description: String {
        
        "\(hour):\(minute == 0 ? "00" : String(minute))"
    }
}

extension ScheduleTime: Comparable {

    static func < (lhs: ScheduleTime, rhs: ScheduleTime) -> Bool {
        if lhs.hour != rhs.hour {
            return lhs.hour < rhs.hour
        }
        return lhs.minute < rhs.minute
    }


}

