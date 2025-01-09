//
//  SwiftUIView.swift
//  
//
//  Created by Woody on 2/21/22.
//

import SwiftUI
import ComposableArchitecture
import OpenFestivalModels
import Zoomable

extension ScheduleView {

    struct AllStagesAtOnceView: View {
        let store: StoreOf<Schedule>

        var schedule: [TimelineWrapper<Event.Performance>] {
            @SharedReader(.event) var event

            let orderedStageIndexes: [Event.Stage.ID : Int] = event.stages.enumerated().reduce(into: [:]) {
                $0[$1.element.id] = $1.offset
            }

            guard let stageSchedules = store.event.schedule[id: store.selectedDay]?.stageSchedules
            else { return [] }

            let performancesWithColumns: [(Int, [Event.Performance])] = stageSchedules.compactMap { stageID, performances in
                guard let column: Int = orderedStageIndexes[stageID]
                else { return nil }

                return (column, performances)
            }

            return performancesWithColumns.flatMap { column, performances in
                return performances.map {
                    TimelineWrapper(
                        groupWidth: column..<column,
                        item: $0
                    )
                }
            }
        }

        var body: some View {
            ScrollView {
                SchedulePageView(schedule) { performance in
                    ScheduleCardView(
                        performance.item,
                        isSelected: false,
                        isFavorite: false
                    )
                    .onTapGesture { store.send(.didTapCard(performance.id)) }
                    .tag(performance.id)
                }
                .frame(height: 1500)
            }
            .zoomable()
        }
    }
}


#Preview {
    ScheduleView.AllStagesAtOnceView(
        store: Store(
            initialState: Schedule.State(),
            reducer: {
                Schedule()
            }
        )
    )
}

//
//struct AllStagesAtOnceView: View {
//    let store: StoreOf<ScheduleFeature>
//    let date: CalendarDate
//    
//    struct ViewState: Equatable {
//        var schedule: [TimelineWrapper<Performance.ID>]
//        var stages: IdentifiedArrayOf<Stage>
//        var selectedCard: ScheduleItem?
//        var selectedDate: CalendarDate
//        var favoriteArtists: FavoriteArtists
//
//        init(_ state: ScheduleFeature.State, date: CalendarDate) {
//            self.favoriteArtists = state.favoriteArtists
//            self.stages = state.eventData.stages
//
//            self.schedule = state.eventData.stages
//                .map { Schedule.PageKey(date: date, stageID: $0.id) }
//                .reduce([ScheduleItem]()) { partialResult, pageIdentifier in
//                    partialResult + state.eventData.schedule[page: pageIdentifier]
//                }
//                .filter {
//                    if state.isFiltering {
//                        return state.favoriteArtists.contains($0)
//                    } else {
//                        return true
//                    }
//                }
//                .map {
//                    let stageIndex = state.eventData.stages[id: $0.stageID]?.sortIndex ?? 0
//                    return TimelineWrapper(groupWidth: stageIndex..<stageIndex, item: $0)
//                }
//
//            
//            self.selectedDate = state.selectedDate
//            self.selectedCard = state.cardToDisplay
//        }
//    }
//    
//    @Environment(\.stages) var stages
//
//    var body: some View {
//        WithViewStore(store, observe: { ViewState($0, date: self.date) }) { viewStore in
//            DateSelectingScrollView(selecting: viewStore.selectedCard?.startTime) {
//                SchedulePageView(viewStore.schedule) { scheduleItem in
//                    Button {
//                        viewStore.send(.didTapCard(scheduleItem.item))
//                    } label: {
//                        ScheduleCardView(
//                            scheduleItem.item,
//                            isSelected: viewStore.selectedCard == scheduleItem.item,
//                            isFavorite: viewStore.favoriteArtists.contains(scheduleItem.item)
//                        )
//                    }
//                    .tag(scheduleItem.item)
//                }
//            }
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    StagesLegend(stages: viewStore.stages)
//                }
//            }
//        }
//    }
//}

struct StagesLegend: View {
    var stages: IdentifiedArrayOf<Event.Stage>

    @Environment(\.eventColorScheme) var eventColorScheme
    var body: some View {
        HStack {
            ForEach(stages) { stage in
                CachedAsyncIcon(url: stage.iconImageURL) {
                    ProgressView()
                }
                .foregroundColor(eventColorScheme.stageColors[stage.id])
                .frame(square: 50)

            }
        }
    }
}
