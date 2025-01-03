//
//  ArtistList.swift
//
//
//  Created by Woody on 2/9/2022.
//

import ComposableArchitecture
import OpenFestivalModels
import SwiftUI

@Reducer
public struct ArtistList {
    public init() {}

    @ObservableState
    public struct State: Equatable {

        public init() {}

        @SharedReader(.event) var event

        var artists: [Event.Artist] {
            event.artists
                .filter {
                    if searchText.hasElements {
                        $0.name.caseInsensitiveContains(searchText)
                    } else {
                        true
                    }
                }
                .sorted(by: \.name)
        }

        @Presents var artistDetail: ArtistDetail.State?

        public var searchText: String = ""
    }

    public enum Action: BindableAction {
        case binding(_ action: BindingAction<State>)
        case artistDetail(PresentationAction<ArtistDetail.Action>)
        case didTapArtist(Event.Artist.ID)
    }

    public var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce { state, action in
            switch action {

            case let .didTapArtist(artistID):

                guard let artist = state.event.artists[id: artistID]
                else { return .none }

                state.artistDetail = ArtistDetail.State(artist: artist)
                return .none

            case .binding, .artistDetail:
                return .none
            }
        }
        .ifLet(\.$artistDetail, action: \.artistDetail) {
            ArtistDetail()
        }
    }
}

public struct ArtistListView: View {
    @Bindable var store: StoreOf<ArtistList>

    public init(store: StoreOf<ArtistList>) {
        self.store = store
    }

    public var body: some View {
        List(store.artists) { artist in
            Button {
                store.send(.didTapArtist(artist.id))
            } label: {
                ArtistRow(artist: artist)
            }
        }
        .searchable(text: $store.searchText)
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
        .navigationTitle("Artists")
        .listStyle(.plain)
        .navigationDestination(
            item: $store.scope(state: \.artistDetail, action: \.artistDetail),
            destination: ArtistDetailView.init
        )
    }

    public struct ArtistRow: View {
        var artist: Event.Artist

        @SharedReader(.event) var activeEvent
        @SharedReader(.favoriteArtists) var favoriteArtists
        @Environment(\.showingArtistImages) var showArtistImage

        var performances: [Event.Performance] {
            []
//            return activeEvent.schedule[for: artist.id]
        }

        public var body: some View {
            HStack(spacing: 10) {
                if showArtistImage {
                    CachedAsyncImage(url: artist.imageURL) {
                        $0.resizable()
                    } placeholder: {
                        Image(systemName: "person.fill")
                            .resizable()
                            .frame(square: 30)
                    }
                    .aspectRatio(contentMode: .fill)
                    .frame(square: 60)
                    .clipped()
                }

                StagesIndicatorView(stageIDs: performances.map(\.stageID))
                    .frame(width: 5)

                Text(artist.name)
                    .lineLimit(1)

                Spacer()

                if favoriteArtists[artist.id] {
                    Image(systemName: "heart.fill")
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(square: 15)
                        .foregroundColor(.accentColor)
                        .padding(.trailing)
                }

            }
            .frame(height: 60)
        }
    }
}

struct ShowingArtistImagesEnvironmentKey: EnvironmentKey {
    static var defaultValue = true
}

extension EnvironmentValues {
    var showingArtistImages: Bool {
        get { self[ShowingArtistImagesEnvironmentKey.self] }
        set { self[ShowingArtistImagesEnvironmentKey.self] = newValue}
    }
}

struct ArtistListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ArtistListView(
                store: .init(
                    initialState: .init(),
                    reducer: ArtistList.init
                )
            )
        }
    }
}


extension StringProtocol {
    func caseInsensitiveContains(_ other: String) -> Bool {
        self.lowercased().contains(other.lowercased())
    }
}
