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

            let launchDate = determineDayScheduleAtLaunch(from: event.schedule)
            let launchStage = determineLaunchStage(for: event, on: launchDate!)

            if let launchDate, let launchStage {
                self.selectedStage = launchStage
                self.selectedDay = launchDate
            } else {
                self.showingComingSoonScreen = true

                self.selectedStage = .init("")
                self.selectedDay = .init("")
            }
        }

        @Presents var destination: Destination.State?

        @Shared(.event) var event
        @Shared(.favoriteArtists) var favoriteArtists = Set()

        public var selection = true

        public var selectedStage: Event.Stage.ID
        public var selectedDay: Event.Schedule.Day.ID
        public var filteringFavorites: Bool = false

        public var cardToDisplay: Event.Performance.ID?

        public var showTutorialElements: Bool = false
        public var showingLandscapeTutorial: Bool = false
        public var showingFilterTutorial: Bool = false

        public var showingComingSoonScreen: Bool = false

        var isFiltering: Bool {
            // For future filters
            return filteringFavorites
        }
    }

    
    public enum Action: BindableAction {
        case binding(_ action: BindingAction<State>)

        case task
        case scheduleTutorial(ScheduleTutorialAction)

        case showAndHighlightCard(Event.Performance.ID)
        case highlightCard(Event.Performance.ID)
        case unHighlightCard

        case didTapCard(Event.Performance.ID)

        case destination(PresentationAction<Destination.Action>)
        
        case didSelectStage(Event.Stage.ID)

        
        public enum ScheduleTutorialAction {
            case showLandscapeTutorial
            case hideLandscapeTutorial
            case showFilterTutorial
            case hideFilterTutorial
        }
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
                
            case .task:
                return showFilterTutorialIfRequired(state: &state)

            case let .scheduleTutorial(tutorialAction):
                
                switch tutorialAction {
                case .showLandscapeTutorial:
                    state.showingLandscapeTutorial = true
                case .hideLandscapeTutorial:
                    state.showingLandscapeTutorial = false
                case .showFilterTutorial:
                    state.showingFilterTutorial = true
                case .hideFilterTutorial:
                    state.showingFilterTutorial = false
                }
                
                return .none
                
            case .showAndHighlightCard(let cardID):
                
//                state.destination = nil
//                
//                guard let card = state.event.schedule[id: cardID] else {
//                    XCTFail("Could not find scheduleItem with id: \(cardID)")
//                    return .none
//                }
//                
//                let schedulePage = card.schedulePageIdentifier(
//                    dayStartsAtNoon: state.eventData.event.dayStartsAtNoon,
//                    timeZone: state.eventData.event.timeZone
//                )
//
//                if let stage = state.eventData.stages[id: schedulePage.stageID] {
//                    state.selectedStage = stage.id
//                }
//
//                state.selectedDate = schedulePage.date
//                
//                state.cardToDisplay = state.eventData.schedule[id: cardID]

                return .run { send in
                    
                    try! await Task.sleep(for: .seconds(2))
                    
//                    await send(.unHighlightCard)
                         
                    await send(.unHighlightCard, animation: .default)
                }

            case .highlightCard(let card):
                state.cardToDisplay = card
                return .none

            case .unHighlightCard:
                state.cardToDisplay = nil

                return .none

            case .didTapCard(let performanceID):
                guard let performance = state.event.schedule[id: performanceID]
                else { return .none }

                switch performance.artistIDs.count {
                case 1:
                    state.destination = .artistDetail(ArtistDetail.State(id: performance.artistIDs.first!))
                default:
                    state.destination = .performanceDetail(PerformanceDetails.State(performanceID: performance.id))
                    return .none

                }

                return .none

            case .didSelectStage(let stageID):
                state.selectedStage = stageID
                return .none
                
            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
    
    func showFilterTutorialIfRequired(state: inout State) -> Effect<Action> {
        @Shared(.appStorage("hasShownScheduleTutorial"))
        var hasShownScheduleTutorial: Bool = true

        if state.showingComingSoonScreen || hasShownScheduleTutorial {
            return .none
        }
        
        hasShownScheduleTutorial = true

        return .run { send in
            try await Task.sleep(for: .seconds(1))
            
            await send(.scheduleTutorial(.showLandscapeTutorial))
            
            try await Task.sleep(for: .seconds(2))
            await send(.scheduleTutorial(.hideLandscapeTutorial))
            
            await send(.scheduleTutorial(.showFilterTutorial))
            try await Task.sleep(for: .seconds(5))
            await send(.scheduleTutorial(.hideFilterTutorial))
        }
    }
}


enum ScheduleStyle: Equatable {
    case singleStage(Event.Stage)
    case allStages
}

public struct ScheduleView: View {
    @Perception.Bindable var store: StoreOf<Schedule>

    public init(store: StoreOf<Schedule>) {
        self.store = store
    }

    @SharedReader(.deviceOrientation) var deviceOrientation

    public var body: some View {
        WithPerceptionTracking {
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
            .task { await store.send(.task).finish() }
            .environment(\.dayStartsAtNoon, true)
            .sheet(item: $store.scope(state: \.destination?.artistDetail, action: \.destination.artistDetail)) { store in
                NavigationStack {
                    ArtistDetailView(store: store)
                }
            }
            .sheet(item: $store.scope(state: \.destination?.performanceDetail, action: \.destination.performanceDetail)) { store in
                NavigationStack {
                    PerformanceDetailView(store: store)
                }
            }
//            .sheet(item: $store.scope(state: \.destination?.groupSet, action: \.destination.groupSet)) { store in
//                NavigationStack {
//                    GroupSetDetailView(store: store)
//                }
//            }
//            .toast(
//                isPresenting: $store.showingLandscapeTutorial,
//                duration: 5,
//                tapToDismiss: true,
//                alert: {
//                    AlertToast(
//                        displayMode: .alert,
//                        type: .systemImage("arrow.counterclockwise", .primary),
//                        subTitle: "Rotate your phone to see all of the stages at once"
//                    )
//                },
//                completion: {
//                    store.send(.scheduleTutorial(.hideLandscapeTutorial))
//                }
//            )

        }
    }


    struct FilterMenu: View {
        @Perception.Bindable var store: StoreOf<Schedule>

        var body: some View {

            WithPerceptionTracking {
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
    //            .popover(present: $store.showingFilterTutorial, attributes: { $0.dismissal.mode = .tapOutside }) {
    //                ArrowPopover(arrowSide: .top(.mostClockwise)) {
    //                    Text("Filter the schedule to only see your favorite artists")
    //                }
    //                .onTapGesture {
    //                    store.send(.scheduleTutorial(.hideFilterTutorial))
    //                }
    //            }
            }
        }
    }

    struct EventDaySelectorViewModifier: ViewModifier {
        @Binding var selectedDay: Event.Schedule.Day.ID
        @Shared(.event) var event


        func label(for day: Event.Schedule.Day.Metadata) -> String {
            if let customTitle = day.customTitle {
                return customTitle
            } else if let calendarDay = day.date {
                return calendarDay.date.formatted(.dateTime.weekday(.wide))
            } else {
                return day.id.rawValue
            }
        }

        var selectedDayMetadata: Event.Schedule.Day.Metadata? {
            event.schedule.dayMetadatas[id: selectedDay]
        }


        func body(content: Content) -> some View {
            content
                .toolbarTitleMenu {
                    ForEach(event.schedule.dayMetadatas) { day in
                        Button(label(for: day)) {
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
                        ._printChanges()
                }
            )
        }
    }
}


func determineDayScheduleAtLaunch(from schedule: Event.Schedule) -> Event.Schedule.Day.ID? {
    let days = schedule.dayMetadatas
    return (days.first(where: { $0.date == .today}) ?? days.first)?.id
}


func determineLaunchStage(for event: Event, on day: Event.Schedule.Day.ID) -> Event.Stage.ID? {
    let stages = event.stages

    return (stages.first { event.schedule[on: day, at: $0.id].hasElements } ??
     stages.first)?.id
}
