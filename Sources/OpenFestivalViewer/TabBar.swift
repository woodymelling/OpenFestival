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
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.tabBar = .init()
                return .none

            case .sourceEventDidUpdate(let event):
                state.event = event
                return .none

            case .tabBar:
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
        case schedule, artists, more
    }

    @ObservableState
    public struct State {
        var selectedTab: Tab = .schedule

        var schedule: Schedule.State = .init()
        var artistList: ArtistList.State = .init()
        var more: More.State = .init()
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)

        case schedule(Schedule.Action)
        case artistList(ArtistList.Action)
        case more(More.Action)
    }

    public var body: some ReducerOf<Self> {
        BindingReducer()

        Scope(state: \.artistList, action: \.artistList) {
            ArtistList()
        }

        Scope(state: \.schedule, action: \.schedule) {
            Schedule()
        }

        Scope(state: \.more, action: \.more) {
            More()
        }
    }
}

struct TabBarView: View {
    @Perception.Bindable var store: StoreOf<TabBar>

    var body: some View {
        WithPerceptionTracking {
            TabView(selection: $store.selectedTab) {
                NavigationStack {
                    ScheduleView(store: store.scope(state: \.schedule, action: \.schedule))
                }
                .tabItem {
                    Label("Schedule", systemImage: "calendar")
                }
                .tag(TabBar.Tab.schedule)

                NavigationStack {
                    ArtistListView(store: store.scope(state: \.artistList, action: \.artistList))
                }
                .navigationViewStyle(.stack)
                .tabItem { Label("Artists", systemImage: "person.3") }
                .tag(TabBar.Tab.artists)

                NavigationStack {
                    MoreView(store: store.scope(state: \.more, action: \.more))
                }
                .navigationViewStyle(.stack)
                .tabItem { Label("More", systemImage: "ellipsis") }
                .tag(TabBar.Tab.more)
            }
        }
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
    TabBarView(store: Store(initialState: TabBar.State(), reducer: {
        TabBar()
    }))
}
