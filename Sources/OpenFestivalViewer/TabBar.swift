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
struct TabBar {
    enum Tab {
        case schedule, artists, more
    }

    @ObservableState
    struct State {
        var selectedTab: Tab = .schedule

        var schedule: Schedule.State = .init()
        var artistList: ArtistList.State = .init()
        var more: More.State = .init()
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)

        case schedule(Schedule.Action)
        case artistList(ArtistList.Action)
        case more(More.Action)
    }

    var body: some ReducerOf<Self> {
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
                    Text("Schedule")
//                    ScheduleView(store: store.scope(state: \.schedule, action: \.schedule))
                }
                .navigationViewStyle(.stack)
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


@Reducer
struct Schedule {}

extension PersistenceKey where Self == PersistenceKeyDefault<InMemoryKey<Event>> {
    static var activeEvent: Self {
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
