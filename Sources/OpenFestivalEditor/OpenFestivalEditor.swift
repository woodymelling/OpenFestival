//
//  OpenFestivalEditor.swift
//  OpenFestival
//
//  Created by Woodrow Melling on 11/7/24.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct EventEditor {
    @ObservableState
    struct State {
        @Shared var event: Event

        init(_ event: Shared<Event>) {
            self._event = event

            self.sidebar = .init(event: event)
        }

        var tabs: TabPagesState<Tabs.State> = .init()
        var sidebar: Sidebar.State
    }

    @Reducer
    enum Tabs {
        case artistEditor(ArtistEditor)
        case scheduleEditor(ScheduleEditor)

    }

    enum Action {
        case sidebar(Sidebar.Action)
        case tabs(TabPagesAction<Tabs.State, Tabs.Action>)
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.sidebar, action: \.sidebar) {
            Sidebar()
        }

        Reduce { state, action in
            switch action {
            case .sidebar(.primaryAction(let tags)):
                state.openTabs(tags: tags)
                return .none
            case .sidebar(.contextMenu(let tags, let action)):
                switch action {
                case .delete:
                    tags.forEach {
                        switch $0 {
                        case .directory: break
                        case .file(let fileType):
                            switch fileType {
                            case .artist(let artistID):
                                state.event.artists.remove(id: artistID)
                            case .schedule(let scheduleID):
                                state.event.schedule.removeAll {
                                    $0.metadata.id == .init(scheduleID)
                                }
                            case .eventInfo, .stages, .contactInfo:
                                break
                            }
                        }
                    }
                    return .none
                case .openInTab:
                    state.openTabs(tags: tags)
                    return .none
                case .showInFinder:
                    return .none
                }

            case .sidebar, .tabs:
                return .none
            }
        }
        .forEach(\.tabs, action: \.tabs)
    }
}

extension EventEditor.State {
    mutating func openTabs(tags: Set<EventTag>) {
        for tag in tags {
            guard !tabs.pages.ids.contains(tag)
            else { continue }

            switch tag {
            case .directory: break
            case .file(let fileType):
                switch fileType {
                case .artist(let artistID):
                    guard let artist = Shared(self.$event.artists[id: artistID])
                    else { break }

                    self.tabs.append(.artistEditor(ArtistEditor.State(artist: artist)))

                case .schedule(let scheduleID):
                    guard let schedule = Shared(self.$event.schedule[id: scheduleID])
                    else { break }

                    self.tabs.append(.scheduleEditor(ScheduleEditor.State(schedule: schedule)))

                case .eventInfo:
                    break

                case .stages:
                    break

                case .contactInfo:
                    break

                }
            }
        }

        if let firstSelection = tags.first {
            self.tabs.selection = firstSelection
        }
    }
}

extension EventEditor.Tabs.State: Equatable, Identifiable {
    var id: EventTag {
        switch self {
        case .artistEditor(let state):
            .file(.artist(state.artist.id))
        case .scheduleEditor(let state):
            .file(.schedule(state.schedule.id))
        }
    }
}


public struct EventEditorView: View {
    public init() {}

    @Bindable var store = Store(initialState: EventEditor.State(Shared(.testival))) {
        EventEditor()
            ._printChanges()
    }

    public var body: some View {
        NavigationSplitView {
            SidebarView(store: store.scope(state: \.sidebar, action: \.sidebar))
        } detail: {
            TabPagesView(
                store: $store.scope(state: \.tabs, action: \.tabs),
                root: {
                    Text("No Editor Open")
                },
                label: { state in
                    switch state {
                    case .artistEditor(let state):
                        Label("\(state.artist.name)", systemImage: "doc")
                    case .scheduleEditor(let state):
                        Label("\(state.schedule.name)", systemImage: "doc")
                    }
                },
                destination: { store in
                    switch store.case {
                    case .artistEditor(let store):
                        ArtistEditorView(store: store)
                    case .scheduleEditor(let store):
                        ScheduleEditorView(store: store)
                    }
                }
            )
        }
    }
}

@Reducer
struct Sidebar {
    @ObservableState
    struct State {
        var selection: Set<EventTag> = []
        @Shared var event: Event
        var searchText = ""
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)

        case primaryAction(Set<EventTag>)
        case contextMenu(Set<EventTag>, ContextMenuAction)

        enum ContextMenuAction {
            case openInTab
            case delete
            case showInFinder
        }
    }

    var body: some ReducerOf<Self> {
        BindingReducer()
    }
}

import OpenFestivalParser
import OpenFestivalModels

struct SidebarView: View {
    @Bindable var store: StoreOf<Sidebar>

    var body: some View {
        List(selection: $store.selection) {
            EventFileTree()
                .view(for: store.event)
        }
        .searchable(text: $store.searchText, placement: .sidebar)
        .contextMenu(
            forSelectionType: EventTag.self,
            menu: { selections in
                Button("Open in Tab") {
                    store.send(.contextMenu(selections, .openInTab))
                }
                .disabled(selections.contains { $0.isDirectory })

                Button("Show in Finder") {
                    store.send(.contextMenu(selections, .showInFinder))
                }

                Divider()

                Button("Delete", role: .destructive) {
                    store.send(.contextMenu(selections, .delete))
                }
                .disabled(selections.contains { $0.isDirectory })
            },
            primaryAction: { id in
                store.send(.primaryAction(id))
            }
        )
    }
}

extension EventTag {
    var isDirectory: Bool {
        switch self {
        case .file: false
        case .directory: true
        }
    }
}

extension View {
   func hover(_ isHovered: Binding<Bool>) -> some View {
       self.onHover { isHovered.wrappedValue = $0 }
    }
}

#Preview {
    EventEditorView()
//        .frame(width: 700, height: 500)
}
