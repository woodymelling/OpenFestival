//
//  Schedule.swift
//
//
//  Created by Woody on 2/17/2022.
//

import SwiftUI
import ComposableArchitecture
import OpenFestivalModels
import OrderedCollections


extension Event.Performance: DateIntervalRepresentable {
    public var dateInterval: DateInterval {
        .init(start: startTime, end: endTime)
    }
}

extension ScheduleView {
    public struct SingleStageAtOnceView: View {
        @Bindable var store: StoreOf<Schedule>

        @Namespace var namespace

        public init(store: StoreOf<Schedule>) {
            self.store = store
        }

        // Should eventually be stored and manageable by the user
        var stageOrder: OrderedSet<Event.Stage.ID> {
            @Shared(.event) var event

            return event.stages.ids
        }

        var orderedStageSchedules: [(Event.Stage.ID, [Event.Performance])] {
            guard let daySchedule = store.event.schedule[day: store.selectedDay]
            else { return [] }

            return stageOrder.compactMap { stageID in
                daySchedule.stageSchedules[stageID].map { (stageID, $0) }
            }
        }

        @Environment(\.dayStartsAtNoon) var dayStartsAtNoon

        public var body: some View {
            ScrollView {
                HorizontalPageView(page: $store.selectedStage) {
                    ForEach(orderedStageSchedules, id: \.0) { (stageID, schedule) in
                        SchedulePageView(schedule) { performance in
                            ScheduleCardView(
                                performance,
                                isSelected: false,
                                isFavorite: false
                            )
                            .onTapGesture { store.send(.didTapCard(performance.id)) }
                            .id(performance.id)
                        }
                        .tag(stageID)
                        .overlay {
                            if store.showTimeIndicator {
                                TimeIndicatorView()
                            }
                        }
                    }
                }
                .animation(.default, value: store.selectedStage)
                .frame(height: 1500)
                .scrollClipDisabled()
                .scrollTargetLayout()
            }
            .scrollPosition($store.highlightedPerformance) { id, size in
                @Shared(.event) var event
                guard let performance = event.schedule[id: id]
                else { return nil }

                return CGPoint(
                    x: 0,
                    y: performance.startTime.toY(
                        containerHeight: size.height,
                        dayStartsAtNoon: dayStartsAtNoon
                    )
                )
            }
            .overlay {
                if store.showingComingSoonScreen {
                    ScheduleComingSoonView()
                }
            }
            .navigationBarExtension {
                StageSelector(
                    stages: store.event.stages,
                    selectedStage: $store.selectedStage.animation(.snappy)
                )
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

extension IdentifiedArrayOf<Event.DailySchedule> {
    subscript(performanceID id: Event.Performance.ID) -> Event.Performance? {
        for schedule in self {
            for stageSchedule in schedule.stageSchedules.values {
                if let performance = stageSchedule.first(where: { $0.id == id }) {
                    return performance
                }
            }
        }

        return nil
    }
}

let firstPerformance = Event.testival.schedule.first!.stageSchedules.first!.value.first!

#Preview {
    NavigationStack {
        ScheduleView.SingleStageAtOnceView(
            store: Store(
                initialState: Schedule.State(),
                reducer: { Schedule() }
            )
        )
        .environment(\.dayStartsAtNoon, true)
    }
}

