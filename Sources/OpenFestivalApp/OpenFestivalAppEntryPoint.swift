//
//  File.swift
//  
//
//  Created by Woodrow Melling on 7/1/24.
//

import Foundation
import ComposableArchitecture
import OpenFestivalViewer
import OpenFestivalModels
import OpenFestivalParser
import SwiftUI

extension PersistenceKey where Self == AppStorageKey<String?> {
    static var selectedEventRelativeURL: Self {
        .appStorage("selected_event_url")
    }
}

@Reducer
public struct OpenFestivalAppEntryPoint {
    public init() {}

    @ObservableState
    public enum State {
        case eventViewer(EventViewer.State)
        case festivalList(FestivalList.State)
        case loading
    }

    public enum Action {
        case onAppear
        case loadedSelectedEvent(Event)
        case failedToLoadEvent

        case eventViewer(EventViewer.Action)
        case festivalList(FestivalList.Action)
    }

    public var body: some ReducerOf<Self> {
        CombineReducers {
            Reduce { state, action in
                switch action {
                case .onAppear:
                    @Shared(.selectedEventRelativeURL)
                    var selectedEventReference

                    if let selectedEventReference {
                        return .run { send in
                            @Dependency(OpenFestivalParser.self)
                            var openFestivalParser

                            let event = try await openFestivalParser.parseEvent(from: .organizations.appendingPathComponent(selectedEventReference))
                            await send(.loadedSelectedEvent(event))
                        } catch: { error, send in
                            @Shared(.selectedEventRelativeURL) var selectedEventURL
                            await $selectedEventURL.withLock {
                                $0 = nil
                            }

                            await send(.failedToLoadEvent)
                        }
                    } else {
                        state = .festivalList(FestivalList.State())
                        return .none
                    }
                case .failedToLoadEvent:
                    state = .festivalList(FestivalList.State())
                    return .none

                case .loadedSelectedEvent(let event):
                    state = .eventViewer(EventViewer.State(event: event))
                    return .none
                case .eventViewer, .festivalList:
                    return .none
                }
            }

            Scope(state: \.eventViewer, action: \.eventViewer) {
                EventViewer()
            }

            Scope(state: \.festivalList, action: \.festivalList) {
                FestivalList()
            }
        }

    }
}

public struct OpenFestivalAppView: View {
    public init(store: StoreOf<OpenFestivalAppEntryPoint>) {
        self.store = store
    }

    let store: StoreOf<OpenFestivalAppEntryPoint>

    public var body: some View {
        WithPerceptionTracking {
            switch store.state {
            case .loading:
                ProgressView()
                    .onAppear { store.send(.onAppear) }
            case .eventViewer:
                if let store = store.scope(state: \.eventViewer, action: \.eventViewer) {
                    EventViewerView(store: store)
                }
            case .festivalList:
                if let store = store.scope(state: \.festivalList, action: \.festivalList) {
                    NavigationStack {
                        FestivalListView(store: store)
                    }
                }
            }
        }
    }
}
