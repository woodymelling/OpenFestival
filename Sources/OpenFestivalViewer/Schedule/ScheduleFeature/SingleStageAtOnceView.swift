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
            guard let daySchedule = store.event.schedule[id: store.selectedDay]
            else { return [] }

            return stageOrder.compactMap { stageID in
                daySchedule.stageSchedules[stageID].map { (stageID, $0) }
            }
        }


        public var body: some View {
            ScrollViewReader { reader in
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
                                .tag(performance.id)
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
                    .scrollClipDisabled()
                    .animation(.default, value: store.selectedStage)
                    .frame(height: 1500)
                }
            }
            .scrollClipDisabled()
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

struct ScrollViewWithEdgeDetection<Content: View>: View {
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var content: Content

    var body: some View {
        ScrollView {
            content
                .background {
                    VStack {
                        Text("Top")
                            .tag(ScrollViewEdge.top)
                        Spacer()
                        Text("Bottom")
                            .tag(ScrollViewEdge.bottom)
                    }
                }
        }

    }
}

enum ScrollViewEdge {
    case top, bottom
}

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

