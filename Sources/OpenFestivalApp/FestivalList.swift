//
//  FestivalList.swift
//  OpenFestivalApp
//
//  Created by Woodrow Melling on 6/30/24.
//

import Foundation
import ComposableArchitecture
import SwiftUI
import OpenFestivalParser
import CachedAsyncImage


@Reducer
public struct FestivalList {
    @ObservableState
    public struct State {
        init() {}

        @Presents var destination: Destination.State?
        var organizations: [OrganizationReference] = []

        var isLoadingEvent: Bool = false

        func loadOrganizations() -> EffectOf<FestivalList> {
            return .run { send in
                @Dependency(OpenFestivalClient.self) var openFestivalClient

                let organizations = try await openFestivalClient.fetchOrganizationsFromDisk()

                await send(.organizationsResponse(organizations))
            }
        }
    }

    @Reducer
    public enum Destination {
        case addRepository(AddRepository)
        case organizationDetail(OrganizationDetail)
    }

    public enum Action {
        case didTapAddFestivalButton
        case onAppear
        case didPullToRefresh

        case organizationsResponse([OrganizationReference])
        case didTapOrganization(OrganizationReference)
        case destination(PresentationAction<Destination.Action>)
    }


    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear, .destination(\.addRepository.successfullyAddedRepository):

                return state.loadOrganizations()

            case .didPullToRefresh:
                return .concatenate(
                    .run { _ in
                        @Dependency(OpenFestivalClient.self) var openFestivalClient
                        try await openFestivalClient.refreshOrganizations()
                    },
                    state.loadOrganizations()
                )
            case .organizationsResponse(let organizations):
                state.organizations = organizations
                return .none
            case .didTapAddFestivalButton:
                state.destination = .addRepository(AddRepository.State())
                return .none

            case .didTapOrganization(let org):
                state.destination = .organizationDetail(OrganizationDetail.State(organization: org))
                return .none

            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}


struct FestivalListView: View {
    @Perception.Bindable var store: StoreOf<FestivalList>

    var body: some View {
        WithPerceptionTracking {

            List(store.organizations, id: \.url) { org in
                Button {
                    store.send(.didTapOrganization(org))
                } label: {
                    HStack {
                        CachedAsyncImage(
                            url: org.info.imageURL,
                            content: { $0.resizable() },
                            placeholder: {
                                Image(systemName: "photo.artframe")
                                    .resizable()
                            }
                        )
                        .frame(width: 60, height: 60)
                        .aspectRatio(contentMode: .fit)

                        Text(org.info.name)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.navigationLink)
            }
            .listStyle(.plain)
            .onAppear { store.send(.onAppear) }
            .refreshable { await store.send(.didPullToRefresh).finish() }
            .navigationTitle("My Festivals")
            .toolbar {
                Button("Add Festival", systemImage: "plus") {
                    store.send(.didTapAddFestivalButton)
                }
            }
            .sheet(
                item: $store.scope(
                    state: \.destination?.addRepository,
                    action: \.destination.addRepository
                ),
                content: AddRepositoryView.init(store:)
            )
            .navigationDestination(
                item: $store.scope(
                    state: \.destination?.organizationDetail,
                    action: \.destination.organizationDetail
                ),
                destination: OrganizationDetailView.init(store:)
            )
        }
    }
}

#Preview {
    NavigationStack {
        FestivalListView(
            store: Store(
                initialState: FestivalList.State(),
                reducer: {
                    FestivalList()
                }
            )
        )
    }
}

