//
//  File.swift
//
//
//  Created by Woodrow Melling on 7/3/24.
//

import Foundation
import ComposableArchitecture
import SwiftUI
import OpenFestivalModels

@Reducer
public struct PerformanceDetails {
    @ObservableState
    public struct State {
        var performanceID: Event.Performance.ID
        @SharedReader(.event) var event

        var performance: Event.Performance? {

            return event.schedule[id: performanceID]
        }

        var artists: [Event.Artist] {

            (performance?.artistIDs ?? []).compactMap {
                event.artists[id: $0]
            }
        }

        @Presents var destination: Destination.State?
    }

    @Reducer
    public enum Destination {
        case artistDetail(ArtistDetail)
    }

    public enum Action {
        case didTapArtist(Event.Artist.ID)
        case destination(PresentationAction<Destination.Action>)
    }


    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .didTapArtist(let artistID):
                state.destination = .artistDetail(ArtistDetail.State(id: artistID))
                return .none

            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}


struct PerformanceDetailView: View {
    @Bindable var store: StoreOf<PerformanceDetails>

    var body: some View {
        List {
            if let performance = store.performance {
                Section {
                    PerformanceDetailRow(for: performance)
                }

                Section("Artists") {
                    ForEach(store.artists) { artist in
                        Button(artist.name) {
                            store.send(.didTapArtist(artist.id))
                        }
                        .buttonStyle(.navigationLink)
                    }
                }
            }
        }
        .navigationDestination(
            item: $store.scope(state: \.destination?.artistDetail, action: \.destination.artistDetail),
            destination: ArtistDetailView.init(store:)
        )
    }
}

#Preview {
    PerformanceDetailView(
        store: Store(
            initialState: PerformanceDetails.State(performanceID: Event.testival.schedule.performances.first(where: { $0.artistIDs.count > 1})!.id),
            reducer: {
                PerformanceDetails()
            }
        )
    )
}
