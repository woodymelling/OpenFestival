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
        var selectedTab: Tab

        var schedule: Schedule.State
        var artistList: ArtistList.State
        var more: More.State
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

            }
        }
    }
}


@Reducer
struct Schedule {}

@Reducer
struct More {}

extension PersistenceKey where Self == PersistenceKeyDefault<InMemoryKey<Event>> {
    static var activeEvent: Self {
        PersistenceKeyDefault(
            .inMemory("activeEvent"),
            .empty,
            previewValue: .testival
        )
    }
}
