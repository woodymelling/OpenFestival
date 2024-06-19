//
//  Schedule.swift
//
//
//  Created by Woody on 2/17/2022.
//

import SwiftUI
import ComposableArchitecture
import ScheduleComponents
import OpenFestivalModels


extension Event.Performance: DateIntervalRepresentable {
    public var dateInterval: DateInterval {
        .init(start: startTime, end: endTime)
    }
}

extension ScheduleView {
    public struct SingleStageAtOnceView: View {
        @Perception.Bindable var store: StoreOf<Schedule>
        @Namespace var namespace

        public init(store: StoreOf<Schedule>) {
            self.store = store
        }


        public var body: some View {

            WithPerceptionTracking {
                ScrollView {
                    TabView(selection: $store.selectedStage) {
                        ForEach(store.event.stages) { stage in
                            let schedule = store.event.schedule[on: store.selectedDay, at: stage.id]
                            SchedulePageView(schedule) { performance in
                                WithPerceptionTracking {
                                    ScheduleCardView(
                                        performance,
                                        isSelected: false,
                                        isFavorite: false
                                    )
                                    .onTapGesture { store.send(.didTapCard(performance.id)) }
                                    .tag(performance.id)
                                }
                            }
                            .tag(stage.id)
                        }
                    }
                    .animation(.default, value: store.selectedStage)
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: 1500)
                }
                .overlay {
                    if store.showingComingSoonScreen {
                        ScheduleComingSoonView()
                    }
                }
                .toolbarBackground(.background, for: .navigationBar)
                .safeAreaInset(edge: .top) {
                    ScheduleStageSelector(
                        stages: store.event.stages,
                        selectedStage: store.selectedStage,
                        onSelectStage: { @MainActor stage in
                            store.send(.didSelectStage(stage), animation: .default)
                        }
                    )
                }
            }
        }
    }
}
