//
//  File.swift
//  
//
//  Created by Woodrow Melling on 6/14/24.
//

import Foundation
import ComposableArchitecture
import OpenFestivalModels
import SwiftUI

@Reducer
public struct EventViewer {
    public init() {}

    @ObservableState
    public struct State {
        public init(event: Event) {
            self.event = event
        }

        @Shared(.event) var event
        var tabBar: TabBar.State?

        var showingArtistImages: Bool {
            event.artists.contains { $0.imageURL != nil }
        }
    }

    public enum Action {
        case tabBar(TabBar.Action)

        case onAppear
        
        case sourceEventDidUpdate(Event)
        case delegate(Delegate)

        @CasePathable
        public enum Delegate {
            case didTapRefreshEvent
            case didTapExitEvent
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.tabBar = TabBar.State()
                return .none

            case .sourceEventDidUpdate(let event):
                state.event = event
                return .none

            case .tabBar, .delegate:
                return .none
            }

        }
        .ifLet(\.tabBar, action: \.tabBar) {
            TabBar()
        }
    }
}

public struct EventViewerView: View {
    let store: StoreOf<EventViewer>

    public init(store: StoreOf<EventViewer>) {
        self.store = store
    }

    public var body: some View {
        Group {
            if let store = store.scope(state: \.tabBar, action: \.tabBar) {
                TabBarView(store: store)
            } else {
                ProgressView()
            }
        }
        .onAppear { store.send(.onAppear) }
        .environment(\.eventColorScheme, store.event.colorScheme!)
        .environment(\.showingArtistImages, store.showingArtistImages)
    }
}

@Reducer
public struct TabBar {
    enum Tab {
        case schedule, artists, contactInfo, siteMap, location, explore, workshops, notifications
    }

    @ObservableState
    public struct State {
        init() {
            @Shared(.event) var event

            if let siteMapURL = Shared($event.info.siteMapImageURL) {
                self.siteMap = SiteMapFeature.State(url: siteMapURL)
            }

            if let location = Shared($event.info.location) {
                self.location = LocationFeature.State(location: location)
            }

            self.workshops = .init()
        }

        var selectedTab: Tab = .schedule

        @Shared(.highlightedPerformance) var highlightedPerformance

        var schedule: Schedule.State = .init()
        var artistList: ArtistList.State = .init()
        var explore: ExploreFeature.State = .init()
        var notifications: NotificationsFeature.State = .init()

        var siteMap: SiteMapFeature.State?
        var location: LocationFeature.State?
        var contactInfo: ContactInfoFeature.State?
        var workshops: WorkshopsFeature.State?
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case onAppear

        case didHighlightCard(Event.Performance.ID)

        case schedule(Schedule.Action)
        case artistList(ArtistList.Action)
        case explore(ExploreFeature.Action)
        case siteMap(SiteMapFeature.Action)
        case location(LocationFeature.Action)
        case contactInfo(ContactInfoFeature.Action)
        case workshops(WorkshopsFeature.Action)
        case notifications(NotificationsFeature.Action)
    }

    public var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .onAppear:
                return .publisher {
                    state.$highlightedPerformance.publisher.compactMap {
                        $0.map { .didHighlightCard($0) }
                    }
                }
                
            case .didHighlightCard(let performanceID):
                reportIssue("Need to Reimplement")
                //                @SharedReader(.event) var event
                //                guard let performance = event.schedule[id: performanceID],
                //                      let performanceDay = event.schedule.dayFor(performanceID)
                //                else { return .none }
                //
                //                state.selectedTab = .schedule
                //                state.schedule.selectedStage = performance.stageID
                //                state.schedule.selectedDay = performanceDay
                //                state.schedule.destination = nil
                //                state.schedule.showingPerformanceID = performanceID
                return .none
                
            case .binding,
                    .schedule,
                    .artistList,
                    .siteMap,
                    .location,
                    .contactInfo,
                    .explore:
                return .none
            }
        }
        .ifLet(\.siteMap, action: \.siteMap) {
            SiteMapFeature()
        }
        .ifLet(\.location, action: \.location) {
            LocationFeature()
        }
        .ifLet(\.contactInfo, action: \.contactInfo) {
            ContactInfoFeature()
        }
        .ifLet(\.workshops, action: \.workshops) {
            WorkshopsFeature()
        }

        Scope(state: \.artistList, action: \.artistList) {
            ArtistList()
        }

        Scope(state: \.schedule, action: \.schedule) {
            Schedule()
        }

        Scope(state: \.explore, action: \.explore) {
            ExploreFeature()
        }

        Scope(state: \.notifications, action: \.notifications) {
            NotificationsFeature()
        }
    }
}

struct TabBarView: View {
    @Bindable var store: StoreOf<TabBar>

    @Environment(\.showingArtistImages) var showingArtistImages

    @AppStorage("tabViewCustomizations") var tabViewCustomization: TabViewCustomization
    var body: some View {
        TabView(selection: $store.selectedTab) {
            Tab("Schedule", systemImage: "calendar", value: .schedule) {
                NavigationStack {
                    ScheduleView(store: store.scope(state: \.schedule, action: \.schedule))
                }
            }
            .customizationID("com.OpenFestival.schedule")

            Tab("Artists", systemImage: "person.3", value: .artists) {

                NavigationStack {
                    ArtistListView(store: store.scope(state: \.artistList, action: \.artistList))
                }
            }
            .customizationID("com.OpenFestival.artists")

            if showingArtistImages {
                Tab("Explore", systemImage: "sparkle.magnifyingglass", value: .explore) {
                    NavigationStack {
                        ExploreView(store: store.scope(state: \.explore, action: \.explore))
                    }
                }
                .customizationID("com.OpenFestival.explore")
            }

            if let store = store.scope(state: \.workshops, action: \.workshops) {
                Tab("Workshops", systemImage: "figure.yoga", value: .workshops) {
                    NavigationStack {
                        WorkshopsView(store: store)
                    }
                }
                .customizationID("com.OpenFestival.workshops")
            }

            if let store = store.scope(state: \.siteMap, action: \.siteMap) {
                Tab("Site Map", systemImage: "map", value: .siteMap) {
                    NavigationStack {
                        SiteMapView(store: store)
                    }
                }
                .customizationID("com.OpenFestival.siteMap")
            }

            if let store = store.scope(state: \.location, action: \.location) {
                Tab("Location", systemImage: "mappin.and.ellipse", value: .location) {

                    NavigationStack {
                        AddressView(store: store)
                    }
                }
                .customizationID("com.OpenFestival.location")
            }

            if let store = store.scope(state: \.contactInfo, action: \.contactInfo) {
                Tab("Contact Info", systemImage: "phone", value: .contactInfo) {
                    NavigationStack {
                        ContactInfoView(store: store)
                    }
                }
                .customizationID("com.OpenFestival.contactInfo")
            }

            Tab("Notifications", systemImage: "bell.badge", value: .notifications) {
                NavigationStack {
                    NotificationsView(store: store.scope(state: \.notifications, action: \.notifications))
                }

            }
            .customizationID("com.OpenFestival.notifications")

        }
        .tabViewStyle(.sidebarAdaptable)
        .tabViewCustomization($tabViewCustomization)
        .onAppear { store.send(.onAppear) }
    }
}



public extension PersistenceReaderKey where Self == PersistenceKeyDefault<InMemoryKey<Event>> {
    static var event: Self {
        PersistenceKeyDefault(
            .inMemory("activeEvent"),
            .empty,
            previewValue: .testival
        )
    }
}


#Preview {
    EventViewerView(
        store: Store(initialState: EventViewer.State(event: .testival)) {
            EventViewer()
        }
    )
}
