//
//  OpenFestivalEditor.swift
//  OpenFestival
//
//  Created by Woodrow Melling on 11/7/24.
//

import SwiftUI
import ComposableArchitecture
import OpenFestivalParser
import OpenFestivalModels

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

                case .createNewArtist:
                    return .none
                case .createNewSchedule:
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

        if let firstSelection = tags.first, tabs.pages.ids.contains(firstSelection) {
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
    init(store: StoreOf<EventEditor>) {
        self.store = store
    }

    public init() {
        self.store = Store(initialState: EventEditor.State(Shared(.testival))) {
            EventEditor()
                ._printChanges()
        }
    }

    @Bindable var store: StoreOf<EventEditor>

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
            case createNewSchedule
            case createNewArtist
        }
    }

    var body: some ReducerOf<Self> {
        BindingReducer()
    }
}

extension EventTag {
    var availableActions: Set<Sidebar.Action.ContextMenuAction> {
        var actions: Set<Sidebar.Action.ContextMenuAction> = []

        actions.include(.showInFinder)
        switch self {
        case .file:
            actions.include(.delete, .openInTab)
        case .directory(.schedules):
            actions.include(.createNewSchedule)
        case .directory(.artists):
            actions.include(.createNewArtist)
        }
        return actions
    }
}

extension SetAlgebra {
    mutating func include(_ elements: Element...) {
        for element in elements {
            self.insert(element)
        }
    }
}

struct SidebarView: View {
    @Bindable var store: StoreOf<Sidebar>

    var body: some View {
        List(selection: $store.selection) {
            EventFileTree()
                .view(for: store.event, filteringFor: store.searchText)
        }
        .contextMenu(
            availableActions: \EventTag.availableActions,
            menu: { selections, actions in
                if actions.contains(.createNewArtist) {
                    Button("Create New Artist") {
                        store.send(.contextMenu(selections, .createNewArtist))
                    }

                    Divider()
                }

                if actions.contains(.createNewSchedule) {
                    Button("Create New Schedule") {
                        store.send(.contextMenu(selections, .createNewSchedule))
                    }

                    Divider()
                }

                if actions.contains(.openInTab) {
                    Button("Open in Tab") {
                        store.send(.contextMenu(selections, .openInTab))
                    }
                }

                if actions.contains(.showInFinder) {
                    Button("Show in Finder") {
                        store.send(.contextMenu(selections, .showInFinder))
                    }
                    .disabled(true)
                }

                Divider()

                if actions.contains(.delete) {
                    Button("Delete") {
                        store.send(.contextMenu(selections, .delete))
                    }
                }
            },
            primaryAction: {
                store.send(.primaryAction($0))
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
    EventEditorView(store: Store(initialState: EventEditor.State(Shared(.testival))) {
        EventEditor()
            ._printChanges()
    })
//        .frame(width: 700, height: 500)
}


extension View {
    /**
     Adds a tag-based context menu to a view.

     - Parameters:
        - availableActions: A closure returning a set of actions for a given selection.
        - menu: A closure building the menu, given the selected items and their common actions.
        - primaryAction: A closure handling a primary action for the selected items.

     - Returns: A view with the specified context menu.

     ### Example:
     ```swift
     enum Action {
        case actionOne
        case actionTwo
     }

     enum Tag {
        case one
        case two

        var availableActions: Set<Action> {
            switch self {
                case .one: [.actionOne]
                case .two: [.actionTwo]
            }
        }
     }

     List(selection: $selection) {
         ItemOne()
            .tag(Tag.one)

         ItemTwo()
            .tag(Tag.two)
     }
     .contextMenu(
         availableActions: \Item.availableActions,
         menu: { selections, actions in
             if actions.contains(.actionOne) {
                 Button("Action One") { handleAction(selections, .actionOne) }
             }

             if actions.contains(.actionTwo) {
                 Button("Action Two", role: .destructive) { handleAction(selections, .actionTwo) }
             }
         },
         primaryAction: { handlePrimaryAction($0) }
     )
     ```
     */
    func contextMenu<SelectionType: Hashable, Action, Content: View>(
        availableActions: @escaping (SelectionType) -> Set<Action>,
        @ViewBuilder menu: @escaping (Set<SelectionType>, Set<Action>) -> Content,
        primaryAction: @escaping (Set<SelectionType>) -> Void
    ) -> some View {
        self.contextMenu(
            forSelectionType: SelectionType.self,
            menu: { selections in
                let commonActions = selections
                    .map(availableActions)
                    .reduce(nil) { $0?.intersection($1) ?? $1 } ?? []
                menu(selections, commonActions)
            },
            primaryAction: primaryAction
        )
    }
}

