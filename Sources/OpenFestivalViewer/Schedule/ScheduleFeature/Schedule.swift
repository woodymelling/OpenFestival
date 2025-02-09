//
//  Schedule.swift
//
//
//  Created by Woody on 2/17/2022.
//

import ComposableArchitecture
import CoreGraphics
import OpenFestivalModels
import Combine
import SwiftUI

@Reducer
public struct Schedule {
    public init() {}

    @ObservableState
    public struct State {

        public init() {
            @Shared(.event) var event

            if let launchDate = determineDayScheduleAtLaunch(from: event.schedule) {
                self.selectedDay = launchDate

                if let launchStage = determineLaunchStage(for: event, on: launchDate) {
                    self.selectedStage = launchStage
                } else {
                    self.selectedStage = .init()
                }
            } else {
//                self.showingComingSoonScreen = true

                self.selectedStage = .init()
                self.selectedDay = .init()
            }
        }

        @Presents var destination: Destination.State?

        @Shared(.event) var event
        @Shared(.favoriteArtists) var favoriteArtists = Set()

        public var selection = true

        public var selectedStage: Event.Stage.ID?
        public var selectedDay: Event.Schedule.ID
        public var filteringFavorites: Bool = false

        public var showingPerformanceID: Event.Performance.ID?

        public var showingComingSoonScreen: Bool = false

        var isFiltering: Bool {
            // For future filters
            return filteringFavorites
        }

        var showTimeIndicator: Bool {
            @Dependency(\.date) var date


            if let selectedDay = event.schedule[id: selectedDay]?.metadata,
               selectedDay.date == CalendarDate(date()) {
                return true
            } else {
                return false
            }
        }
    }

    
    public enum Action: BindableAction {
        case binding(_ action: BindingAction<State>)
        case didTapCard(Event.Performance.ID)

        case destination(PresentationAction<Destination.Action>)
        
        case didSelectStage(Event.Stage.ID)
    }
    
    @Reducer
    public enum Destination {
        case artistDetail(ArtistDetail)
        case performanceDetail(PerformanceDetails)
    }

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .didTapCard(let performanceID):
                reportIssue("REIMPLEMENT")
                return .none
//                guard let performance = state.event.schedule[id: performanceID]
//                else { return .none }
//
//                switch performance.artistIDs.count {
//                case 1:
//                    state.destination = .artistDetail(ArtistDetail.State(id: performance.artistIDs.first!))
//                default:
//                    state.destination = .performanceDetail(PerformanceDetails.State(performanceID: performance.id))
//                    return .none
//
//                }
//                return .none

            case .didSelectStage(let stageID):
                state.selectedStage = stageID
                return .none
                
            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}


enum ScheduleStyle: Equatable {
    case singleStage(Event.Stage)
    case allStages
}

public struct ScheduleView: View {
    @Bindable var store: StoreOf<Schedule>

    public init(store: StoreOf<Schedule>) {
        self.store = store
    }

    @SharedReader(.deviceOrientation) var deviceOrientation

    public var body: some View {
        Group {
            switch deviceOrientation {
            case .portrait:
                SingleStageAtOnceView(store: store)

            case .landscape:
                AllStagesAtOnceView(store: store)
            }
        }
        .modifier(EventDaySelectorViewModifier(selectedDay: $store.selectedDay))
        .toolbar {
            ToolbarItem {
                FilterMenu(store: store)
            }
        }
        .environment(\.dayStartsAtNoon, true)
        .navigationDestination(item: $store.scope(state: \.destination?.artistDetail, action: \.destination.artistDetail)) { store in
            ArtistDetailView(store: store)
        }
        .navigationDestination(item: $store.scope(state: \.destination?.performanceDetail, action: \.destination.performanceDetail)) { store in
            PerformanceDetailView(store: store)
        }
    }


    struct FilterMenu: View {
        @Bindable var store: StoreOf<Schedule>

        var body: some View {
            Menu {
                Toggle(isOn: $store.filteringFavorites.animation()) {
                    Label(
                        "Favorites",
                        systemImage:  store.isFiltering ? "heart.fill" : "heart"
                    )
                }
            } label: {
                Label(
                    "Filter",
                    systemImage: store.isFiltering ?
                    "line.3.horizontal.decrease.circle.fill" :
                        "line.3.horizontal.decrease.circle"
                )
            }
        }
    }

    struct EventDaySelectorViewModifier: ViewModifier {
        @Binding var selectedDay: Event.Schedule.ID
        @Shared(.event) var event


        func label(for day: Event.Schedule.Metadata) -> String {
            if let customTitle = day.customTitle {
                return customTitle
            } else if let calendarDay = day.date {
                return calendarDay.date.formatted(.dateTime.weekday(.wide))
            } else {
                return day.id.uuidString
            }
        }

        var selectedDayMetadata: Event.Schedule.Metadata? {
            event.schedule[id: selectedDay]?.metadata
        }


        func body(content: Content) -> some View {
            content
                .toolbarTitleMenu {
                    ForEach(event.schedule) { day in
                        Button(label(for: day.metadata)) {
                            selectedDay = day.id
                        }
                    }
                }
                .navigationTitle(selectedDayMetadata.map { label(for: $0) } ?? "")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}



struct ScheduleView_Previews: PreviewProvider {
    static var state = Schedule.State()
    static var previews: some View {
        NavigationStack {
            ScheduleView(
                store: .init(initialState: state) {
                    Schedule()
//                        ._printChanges()
                }
            )
        }
    }
}


func determineDayScheduleAtLaunch(from schedules: IdentifiedArrayOf<Event.Schedule>) -> Event.Schedule.ID? {

    return schedules.first?.metadata.id
}


func determineLaunchStage(for event: Event, on day: Event.Schedule.ID) -> Event.Stage.ID? {

    return event.stages.first?.id
}
