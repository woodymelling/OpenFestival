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
            self.$event.withLock { $0 = event }
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
                state.$event.withLock { $0 = event }
                return .none

            case .tabBar, .delegate:
                return .none
            }

        }
        .ifLet(\.tabBar, action: \.tabBar) {
            TabBar()
        }
        ._printChanges()
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
    enum Feature: Hashable, Codable {
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

        var selectedTab: TabLocation<Feature> = .tabBar(.artists)

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

import CustomizableTabView

struct TabBarView: View {
    @Bindable var store: StoreOf<TabBar>

    @Environment(\.showingArtistImages) var showingArtistImages


    @Shared(
        .fileStorage(.documentsDirectory.appending(component: "tab-customization.json"))
    )
    var tabCustomization: TabCustomization<TabBar.Feature> = .init(
        items: [
            .schedule,
            .artists,
            .explore,
            .workshops,
            .siteMap,
            .location,
            .contactInfo,
            .notifications
        ],
        maxVisible: 5
    )

    @State var selectedFeature: TabLocation<TabBar.Feature> = .more(.schedule)

    var body: some View {
        CustomizableTabView(
            selection: $selectedFeature,
            customization: Binding($tabCustomization)
        ) {
            NavigationStackTab("Schedule", systemImage: "calendar", value: TabBar.Feature.schedule) {
                ScheduleView(store: store.scope(state: \.schedule, action: \.schedule))
            }

            NavigationStackTab("Artists", systemImage: "person.3", value: TabBar.Feature.artists) {
                ArtistListView(store: store.scope(state: \.artistList, action: \.artistList))
            }

            if showingArtistImages {
                NavigationStackTab("Explore", systemImage: "sparkle.magnifyingglass", value: TabBar.Feature.explore) {
                    ExploreView(store: store.scope(state: \.explore, action: \.explore))
                }
            }

            if let store = store.scope(state: \.workshops, action: \.workshops) {
                NavigationStackTab("Workshops", systemImage: "figure.yoga", value: TabBar.Feature.workshops) {
                    WorkshopsView(store: store)
                }
            }

            if let store = store.scope(state: \.siteMap, action: \.siteMap) {
                NavigationStackTab("Site Map", systemImage: "map", value: TabBar.Feature.siteMap) {
                    SiteMapView(store: store)
                }
            }

            if let store = store.scope(state: \.location, action: \.location) {
                NavigationStackTab("Location", systemImage: "mappin.and.ellipse", value: TabBar.Feature.location) {
                    AddressView(store: store)
                }
            }

            if let store = store.scope(state: \.contactInfo, action: \.contactInfo) {
                NavigationStackTab("Contact Info", systemImage: "phone", value: TabBar.Feature.contactInfo) {
                    ContactInfoView(store: store)
                }
            }

            NavigationStackTab("Notifications", systemImage: "bell.badge", value: TabBar.Feature.notifications) {
                NotificationsView(store: store.scope(state: \.notifications, action: \.notifications))
            }
        }
        .onAppear { store.send(.onAppear) }

    }
}





public extension SharedReaderKey where Self == InMemoryKey<Event>.Default {
    static var event: Self {

        @Dependency(\.context) var context
        return switch context {
        case .preview, .test:
            Self[
                .inMemory("activeEvent"),
                default: .testival
            ]
        case .live:

            Self[
                .inMemory("activeEvent"),
                default: .empty
            ]
        }
    }
}


#Preview {
    EventViewerView(
        store: Store(initialState: EventViewer.State(event: .testival)) {
            EventViewer()
        }
    )
}



