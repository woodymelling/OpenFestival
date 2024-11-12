//
//  ScheduleDayConversion.swift
//  OpenFestival
//
//  Created by Woodrow Melling on 10/31/24.
//

import Parsing
import OpenFestivalModels
import FileTree
import Foundation


struct ScheduleDayConversion: AsyncConversion {
    typealias Input = FileContent<EventDTO.DaySchedule>
    typealias Output = Event.Schedule.Day

    var body: some AsyncConversion<Input, Output> {
        FileContentConversion {
            EventDTO.DaySchedule.TupleConversion()

            Conversions.Tuple(
                Identity<String?>(),
                Identity<CalendarDate?>(),
                ScheduleDictionaryConversion()
            )
        }

        FileContentToTupleScheduleDayConversion()
    }


    struct ScheduleDictionaryConversion: Conversion {
        typealias Input = [String: [PerformanceDTO]]
        typealias Output = [Event.Stage.ID: [StagelessPerformance]]

        var body: some Conversion<Input, Output> {
            Conversions.MapKVPairs(
                keyConversion: Event.Stage.ID.Conversion(),
                valueConversion: StagelessPerformanceConversion()
            )
        }

        struct StagelessPerformanceConversion: Conversion {
            typealias Input = [PerformanceDTO]
            typealias Output = [StagelessPerformance]
            var body: some Conversion<Input, Output> {
                Conversions.MapValues {
                    TimelessStagelessPerformanceConversion()
                }

                DetermineFullSetTimesConversion()
            }
        }
    }


    struct DetermineFullSetTimesConversion: Conversion {
        typealias Input = [TimelessStagelessPerformance]
        typealias Output = [StagelessPerformance]

        func apply(_ partialPerformances: Input) throws(Validation.ScheduleError.StageDayScheduleError) -> Output {
            var schedule: [StagelessPerformance] = []
            var scheduleStartTime: ScheduleTime?

            for (index, performance) in partialPerformances.enumerated() {
                var startTime = performance.startTime
                var endTime: ScheduleTime

                // End times can be manually set
                if let staticEndTime = performance.endTime {
                    endTime = staticEndTime

                    // If they aren't, find the next performance, and make the endtime butt up against it
                } else if let nextPerformance = partialPerformances[safe: index + 1] {
                    endTime = nextPerformance.startTime

                    // If there aren't any performances after this, we can't determine the endtime
                } else {
                    throw .cannotDetermineEndTimeForPerformance(performance)
                }

                if let scheduleStartTime {
                    if startTime < scheduleStartTime {
                        startTime.hour += 24
                    }

                    if endTime < scheduleStartTime {
                        endTime.hour += 24
                    }
                } else {
                    scheduleStartTime = startTime
                    if endTime < startTime {
                        endTime.hour += 24
                    }
                }

                schedule.append(StagelessPerformance(
                    customTitle: performance.customTitle,
                    artistIDs: performance.artistIDs,
                    startTime: startTime,
                    endTime: endTime
                ))
            }

            for (index, performance) in schedule.enumerated() {
                guard let nextPerformance = schedule[safe: index + 1]
                else { continue }

                guard performance.endTime <= nextPerformance.startTime
                else { throw .overlappingPerformances(performance, nextPerformance) }

                guard performance.startTime < performance.endTime
                else { throw .endTimeBeforeStartTime(performance) }
            }

            return schedule
        }

        func unapply(_ performances: [StagelessPerformance]) throws -> [TimelessStagelessPerformance] {
            var schedule = performances.map {
                TimelessStagelessPerformance(
                    startTime: $0.startTime,
                    endTime: $0.endTime,
                    customTitle: $0.customTitle,
                    artistIDs: $0.artistIDs
                )
            }

            // remove end times for schedules that butt up against each other.
            for (index, performance) in schedule.enumerated() {
                if let nextPerformance = performances[safe: index + 1],
                   performance.endTime == nextPerformance.startTime {
                    schedule[index].endTime = nil
                }
            }

            return schedule
        }
    }

    struct StagedPerformanceConversion: Conversion {
        typealias Input = [Event.Stage.ID: [StagelessPerformance]]
        typealias Output = [Event.Stage.ID: [Event.Performance]]

        func apply(_ input: Input) throws -> Output {
            input.mapValuesWithKeys { key, value in
                value.map {
                    Event.Performance(
                        id: "\($0.customTitle ?? "")-\($0.artistIDs.map(\.rawValue).joined(separator: "-"))-\($0.startTime)-\($0.endTime)",
                        customTitle: $0.customTitle,
                        artistIDs: $0.artistIDs,
                        startTime: Date(), // TODO:
                        endTime: Date(), // TODO:
                        stageID: key
                    )
                }
            }
        }

        func unapply(_ output: Output) throws -> Input {
            output.mapValues {
                $0.map {
                    StagelessPerformance(
                        customTitle: $0.customTitle,
                        artistIDs: $0.artistIDs,
                        startTime: ScheduleTime(from: $0.startTime),
                        endTime: ScheduleTime(from: $0.endTime)
                    )
                }
            }
        }
    }

    struct FileContentToTupleScheduleDayConversion: Conversion {
        typealias Input = FileContent<(String?, CalendarDate?, [Event.Stage.ID: [StagelessPerformance]])>
        typealias Output = Event.Schedule.Day

        func apply(_ input: Input) throws -> Output {
            let customTitle = input.data.0
            let scheduleDate = input.data.1 ?? CalendarDate(input.fileName) ?? .today // Default to today if nothing is provided

            let schedule = input.data.2.mapValuesWithKeys { key, value in
                value.map {
                    Event.Performance(
                        id: .init(
                            makeIDs(
                                from: $0.customTitle,
                                $0.artistIDs.map(\.rawValue).joined(separator: "-"),
                                String(describing: $0.startTime),
                                key.rawValue
                            )
                        ),
                        customTitle: $0.customTitle,
                        artistIDs: $0.artistIDs,
                        startTime: scheduleDate.atTime($0.startTime),
                        endTime: scheduleDate.atTime($0.endTime),
                        stageID: key
                    )
                }
            }

            return Event.Schedule.Day(
                id: .init(makeIDs(from: customTitle, String(describing: scheduleDate))),
                date: scheduleDate,
                customTitle: input.data.0,
                stageSchedules: schedule
            )
        }

        func unapply(_ output: Output) throws -> Input {
            FileContent(
                fileName: output.metadata.date?.description ?? output.metadata.customTitle ?? "schedule",
                data: (output.metadata.customTitle, output.metadata.date, output.stageSchedules.mapValues {
                    $0.map {
                        StagelessPerformance(
                            customTitle: $0.customTitle,
                            artistIDs: $0.artistIDs,
                            startTime: ScheduleTime(from: $0.startTime),
                            endTime: ScheduleTime(from: $0.endTime)
                        )
                    }
                })
            )
        }
    }
}
