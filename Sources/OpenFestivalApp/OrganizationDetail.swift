//
//  OrganizationDetail.swift
//  OpenFestivalApp
//
//  Created by Woodrow Melling on 6/30/24.
//

import Foundation
import ComposableArchitecture
import OpenFestivalParser
import OpenFestivalViewer
import OpenFestivalModels
import SwiftUI

@Reducer
public struct OrganizationDetail {
    @ObservableState
    public struct State {
        var organization: OrganizationReference

        @Presents var destination: Destination.State?
    }

    @Reducer
    public enum Destination {
        case eventViewer(EventViewer)
    }

    public enum Action {
        case didTapEvent(OrganizationReference.Event)
        case didLoadEvent(Event)
        case destination(PresentationAction<Destination.Action>)
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .didTapEvent(let eventReference):

                return .run { send in
                    @Dependency(OpenFestivalParser.self)
                    var parser

                    print(eventReference)
                    
                    let event = try await parser.parseEvent(from: eventReference.url)
                    await send(.didLoadEvent(event))

                    @Shared(.selectedEventRelativeURL) var url
                    await $url.withLock {
                        $0 = eventReference.url.relativePath(from: URL.organizations)
                    }
                }

            case .didLoadEvent(let event):
                state.destination = .eventViewer(.init(event: event))
                return .none

            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

struct OrganizationDetailView: View {
    @Perception.Bindable var store: StoreOf<OrganizationDetail>

    var body: some View {
        WithPerceptionTracking {

            VStack(alignment: .center) {
                if let image = store.organization.info.imageURL {
                    AsyncImage(
                        url: image,
                        content: { $0.resizable() },
                        placeholder: { ProgressView()}
                    )
                    .frame(width: 150, height: 150)

                    Text(store.organization.info.name)
                        .font(.largeTitle)
                }
                List {
                    WithPerceptionTracking {
                        Section("Events") {
                            ForEach(store.organization.events, id: \.name) { event in
                                HStack {
                                    Button(event.name) {
                                        store.send(.didTapEvent(event))
                                    }
                                    Spacer()
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .buttonStyle(.navigationLink)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .fullScreenCover(
                item: $store.scope(
                    state: \.destination?.eventViewer,
                    action: \.destination.eventViewer
                ),
                content: EventViewerView.init(store:)
            )
        }
    }
}
