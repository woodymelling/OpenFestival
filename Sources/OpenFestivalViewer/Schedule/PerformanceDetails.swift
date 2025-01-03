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
        var performance: Event.Performance
        @SharedReader(.event) var event


        @Presents var destination: Destination.State?
    }

    @Reducer
    public enum Destination {
        case artistDetail(ArtistDetail)
    }

    public enum Action {
        case didTapArtist(Event.Performance.ArtistReference)
        case destination(PresentationAction<Destination.Action>)
    }


    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .didTapArtist(let artistReference):
                @SharedReader(.event) var event

                guard case let .known(artistID) = artistReference,
                    let artist = event.artists[id: artistID]
                else{ return .none }

                state.destination = .artistDetail(ArtistDetail.State(artist: artist))
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
            Section {
                PerformanceDetailRow(for: store.performance)
            }

            Section("Artists") {
                Text("Reimplement")
//                ForEach(store.performance.artistIDs, id: \.self) { artist in
//                    Button(artist.name) {
//                        store.send(.didTapArtist(artist.id))
//                    }
//                    .buttonStyle(.navigationLink)
//                }
            }
        }
        .navigationDestination(
            item: $store.scope(state: \.destination?.artistDetail, action: \.destination.artistDetail),
            destination: ArtistDetailView.init(store:)
        )
    }
}

//#Preview {
//    PerformanceDetailView(
//        store: Store(
//            initialState: PerformanceDetails.State(performanceID: Event.testival.schedule.first(where: { $0.artistIDs.count > 1})!.id),
//            reducer: {
//                PerformanceDetails()
//            }
//        )
//    )
//}
