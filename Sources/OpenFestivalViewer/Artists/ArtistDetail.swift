//
//  File.swift
//
//
//  Created by Woodrow Melling on 6/15/24.
//

import Foundation
import ComposableArchitecture
import OpenFestivalModels
import SwiftUI
import OrderedCollections
import ImageCaching

@Reducer
public struct ArtistDetail {
    //
    public init() {}

    @ObservableState
    public struct State: Equatable {
        public init(artist: Event.Artist) {
            self.artist = artist
        }

        @Shared(.favoriteArtists) var favoriteArtists
        @SharedReader(.event) var event

        public var artist: Event.Artist

        var isFavorite: Bool {
            favoriteArtists.contains(artist.id)
        }

        var performances: OrderedSet<Event.Performance> {
            event.schedule[artistID: artist.id]
        }

        var artistBioMarkdown: AttributedString? {
            artist.bio?.nilIfEmpty.flatMap {
                try? AttributedString(
                    markdown: $0,
                    options: .init(failurePolicy: .returnPartiallyParsedIfPossible)
                )
            }
        }

        @Presents var destination: Destination.State?

        @Shared(.highlightedPerformance) var highlightingPerformance
    }

    @Reducer(state: .equatable)
    public enum Destination {
        case inAppBrowser(InAppBrowser)
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case didTapPerformance(Event.Performance.ID)
        case favoriteArtistButtonTapped
        case didTapURL(URL)

        case destination(PresentationAction<Destination.Action>)
    }

    public var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .didTapPerformance(let performance):
                state.$highlightingPerformance.withLock { $0 = performance }
                return .none

            case .favoriteArtistButtonTapped:
                state.$favoriteArtists.withLock { $0 .toggle(state.artist.id) }
                return .none

            case .didTapURL(let url):
                state.destination = .inAppBrowser(url)
                return .none

            case .destination, .binding:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

public struct ArtistDetailView: View {
    @Bindable var store: StoreOf<ArtistDetail>

    public init(store: StoreOf<ArtistDetail>) {
        self.store = store
    }

    @Environment(\.eventColorScheme) var eventColorScheme

    var meshColors: [Color] {
        let performanceColors = store.performances.map { eventColorScheme.stageColors[$0.stageID] }
        var colors = [Color.accentColor]

        return [Color.accentColor] + performanceColors + performanceColors
    }

    public var body: some View {

//        ArtistImage(artist: store.artist)

        StretchyHeaderList(
            title: Text(store.artist.name),
            stretchyContent: {
                ArtistImage(artist: store.artist)
            },
            listContent: {
                ForEach(store.performances) { performance in
                    NavigationLinkButton {
                        store.send(.didTapPerformance(performance.id))
                    } label: {
                        PerformanceDetailRow(for: performance)
                    }
                }


                if let bio = store.artistBioMarkdown {
                    Text(bio)
                }

                // MARK: Socials
                if store.artist.links.hasElements {
                    Section("Links") {
                        ForEach(store.artist.links, id: \.self) { link in
                            NavigationLinkButton {
                                store.send(.didTapURL(link.url))
                            } label: {
                                LinkView(link)
                            }
                        }
                    }
                }
            }
        )
        .ignoresSafeArea(.all)
        .environment(\.meshBaseColors, meshColors)
        .listStyle(.plain)
        .sheet(
            item: $store.scope(state: \.destination?.inAppBrowser, action: \.destination.inAppBrowser),
            content: { SafariView(store: $0).ignoresSafeArea(edges: .bottom) }
        )
        .toolbar {
            Toggle("Favorite", isOn: $store.favoriteArtists[store.artist.id])
                .frame(square: 20)
                .toggleStyle(FavoriteToggleStyle())
        }
        
    }


    struct ArtistImage: View {
        let artist: Event.Artist
        @Shared(.event) var event

        var body: some View {
            CachedAsyncImage(
                requests: [
                    ImageRequest(url: artist.imageURL, processors: [.resize(width: 440)]).withPipeline(.artist)
                ]
            ) {
                $0.resizable()
            } placeholder: {
                AnimatedMeshView()
                    .overlay(.thinMaterial)
                    .opacity(0.25)
            }
            .frame(maxWidth: .infinity)
        }
    }




    struct LinkView: View {
        struct LinkType {
            static let soundcloud = LinkType(icon: Image("soundcloud", bundle: .module), name: "Soundcloud")
            static let spotify = LinkType(icon: Image("spotify", bundle: .module), name: "Spotify")
            static let website = LinkType(icon: Image("website", bundle: .module), name: "Website")
            static let instagram = LinkType(icon: Image("instagram", bundle: .module), name: "Instagram")
            static let youtube = LinkType(icon: Image("youtube", bundle: .module), name: "Youtube")
            static let facebook = LinkType(icon: Image("facebook", bundle: .module), name: "Facebook")

            let icon: Image
            let name: String

            static func fromURL(_ url: URL) -> LinkType {
                let host = url.host?.lowercased() ?? ""
                return switch host {
                case _ where host.contains("soundcloud.com"): .soundcloud
                case _ where host.contains("spotify.com"): .spotify
                case _ where host.contains("instagram.com"): .instagram
                case _ where host.contains("youtube.com"), _ where host.contains("youtu.be"):
                        .youtube
                case _ where host.contains("facebook.com"): .facebook
                default: .website
                }
            }
        }

        init(_ link: Event.Artist.Link) {
            self.linkType = .fromURL(link.url)
            self.customName = link.label
        }

        var linkType: LinkType
        var customName: String?

        var body: some View {
            HStack {
                linkType.icon
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 30)

                Text(customName ?? linkType.name)
                Spacer()
            }
        }
    }
}

extension ImagePipeline {
    static var artist: ImagePipeline {
        ImagePipeline(configuration: .withDataCache)
    }

    static var event: ImagePipeline {
        return ImagePipeline {
            $0.imageCache = ImageCache()
            $0.dataCache = try? DataCache(name: "com.openFestival.eventImageCache")
        }
    }
}

#Preview {
    NavigationStack {
        ArtistDetailView(store: Store(initialState: ArtistDetail.State(artist: Event.testival.artists[0]), reducer: {
            ArtistDetail()
        }))
    }
}

#Preview {
    NavigationStack {
        ArtistDetailView(store: Store(initialState: ArtistDetail.State(artist: Event.testival.artists[1]), reducer: {
            ArtistDetail()
        }))
    }
}


#Preview {
    NavigationStack {
        ArtistDetailView(store: Store(initialState: ArtistDetail.State(artist: Event.testival.artists[5]), reducer: {
            ArtistDetail()
        }))
    }
}

struct FavoriteToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Label(
            title: { configuration.label },
            icon: {
                Image(systemName: "heart")
                    .resizable()
                    .foregroundStyle(configuration.isOn ? .red : .primary)
                    .symbolVariant(configuration.isOn ? .fill : .none)
            }
        )
        .onTapGesture { configuration.isOn.toggle() }
        .labelStyle(.iconOnly)
        .contentTransition(.symbolEffect(.automatic))
    }
}

extension View {
    @ViewBuilder
    func animateHeart(value: some Equatable) -> some View {
        if #available(iOS 17, *) {

        } else {
            self.animation(.default, value: value)
        }
    }
}

#Preview("Heart") {
    @Previewable @State var isOn = false

    Toggle("Favorite", isOn: $isOn)
        .toggleStyle(FavoriteToggleStyle())
        .frame(width: 20, height: 20)
}


@Reducer
public struct InAppBrowser {
    public typealias State = URL
    public typealias Action = Never
}

import SafariServices

struct SafariView: UIViewControllerRepresentable {

    let store: StoreOf<InAppBrowser>

    func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
        return store.withState { url in
            SFSafariViewController(url: url)
        }
    }

    func updateUIViewController(
        _ uiViewController: SFSafariViewController,
        context: UIViewControllerRepresentableContext<SafariView>
    ) {}
}

extension Event.Performance.ArtistReference {
    var name: String {
        switch self {
        case .known(let id):
            @SharedReader(.event) var event
            return event.artists[id: id]?.name ?? id.uuidString
        case .anonymous(let name):
            return name
        }
    }
}


extension Collection {
    var nilIfEmpty: Self? {
        self.isEmpty ? nil : self
    }
}
