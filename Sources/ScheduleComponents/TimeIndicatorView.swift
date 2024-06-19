////
////  SwiftUIView.swift
////  
////
////  Created by Woodrow Melling on 4/18/22.
////
//
//import SwiftUI
////import Dependencies
////import OpenFestivalModels
//
//struct SelectedDateEnvironmentKey: EnvironmentKey {
//    static var defaultValue: CalendarDate = .today
//}
//
//extension EnvironmentValues {
//    public var calendarSelectedDate: CalendarDate {
//        get { self[SelectedDateEnvironmentKey.self] }
//        set { self[SelectedDateEnvironmentKey.self] = newValue }
//    }
//}
//
//struct TimeIndicatorView: View {
//    @Environment(\.dayStartsAtNoon) var dayStartsAtNoon: Bool
//    @Environment(\.calendarSelectedDate) var selectedDate: CalendarDate
//
//    @ScaledMetric var textWidth: CGFloat = 50
//    @ScaledMetric var gradientHeight: CGFloat = 30
//    
//    var body: some View {
//        TimelineView(.periodic(from: .now, by: 1)) { context in
////            GeometryReader { geo in
////                if shouldShowTimeIndicator(context.date) {
////                    ZStack(alignment: .leading) {
////                        
////                        // Gradient behind the current time text so that it doesn't overlap with the grid time text
////                        Rectangle()
////                            .fill(
////                                LinearGradient(
////                                    colors: [.clear, Color(uiColor: .systemBackground), Color(uiColor: .systemBackground), .clear],
////                                    startPoint: .top,
////                                    endPoint: .bottom
////                                )
////                            )
////                            .frame(width: textWidth, height: gradientHeight)
////                        
////                        // Current time text
////                        Text(
////                            context.date
////                                .formatted(
////                                    timeFormat
////                                )
////                                .lowercased()
////                                .replacingOccurrences(of: " ", with: "")
////                        )
////                        .foregroundColor(Color.accentColor)
////                        .font(.caption)
////                        .frame(width: textWidth)
////
////
////                        // Circle indicator
////                        Circle()
////                            .fill(Color.accentColor)
////                            .frame(square: 5)
////                            .offset(x: textWidth, y: 0)
////                        
////                        
////                        // Line going across the schedule
////                        Rectangle()
////                            .fill(Color.accentColor)
////                            .frame(height: 1)
////                            .offset(x: textWidth, y: 0)
////                    }
////                    .position(x: geo.size.width / 2, y: context.date.toY(containerHeight: geo.size.height, dayStartsAtNoon: dayStartsAtNoon))
////                } else {
////                    EmptyView()
////                }
////            }
//        }
//    }
////    
////    func shouldShowTimeIndicator(_ currentTime: Date) -> Bool {
////        func isDate(_ date1: Date, inSameDayAs date2: Date) -> Bool {
////            @Dependency(\.calendar) var calendar
////
////            return calendar.isDate(date1, inSameDayAs: date2)
////        }
////        
////        if dayStartsAtNoon {
////            return isDate(currentTime - 12.hours, inSameDayAs: selectedDate.date)
////        } else {
////            return isDate(currentTime, inSameDayAs: selectedDate.date)
////        }
////    }
//
//    var timeFormat: Date.FormatStyle {
//        var format = Date.FormatStyle.dateTime.hour(.defaultDigits(amPM: .narrow)).minute()
//        format.timeZone = NSTimeZone.default
//        return format
//    }
//}
//
//struct TimeIndicatorView_Previews: PreviewProvider {
//    static var previews: some View {
//        TimeIndicatorView()
//    }
//}
