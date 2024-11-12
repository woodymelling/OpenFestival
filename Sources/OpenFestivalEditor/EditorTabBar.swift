//
//  ArtistEditor.swift
//  OpenFestival
//
//  Created by Woodrow Melling on 11/9/24.
//



import ComposableArchitecture
import SwiftUI


@Reducer
struct ArtistEditor {
    @ObservableState
    struct State: Equatable {
        var name: String
    }
}
struct ArtistEditorView: View {
    let store: StoreOf<ArtistEditor>
    var body: some View {
        Label("Artists Editor for: \(store.name)", systemImage: "person")
    }
}

@Reducer
struct ScheduleEditor {
    @ObservableState
    struct State: Equatable {
        var name: String
    }
}

struct ScheduleEditorView: View {
    let store: StoreOf<ScheduleEditor>
    var body: some View {
        VStack {
            Label("Schedule Editor for: \(store.name)", systemImage: "calendar")
        }
    }
}

@Reducer
struct EventEditorTabBar {
    @ObservableState
    struct State {
        var editorTabs: TabPagesState<Tabs.State> = .init(
            pages: [
                .artistEditor(ArtistEditor.State(name: "Boids")),
                .scheduleEditor(ScheduleEditor.State(name: "11-10-2024")),
                .artistEditor(ArtistEditor.State(name: "Rhythmbox")),
                .scheduleEditor(ScheduleEditor.State(name: "11-11-2024")),
                .artistEditor(ArtistEditor.State(name: "Overgrowth")),
            ]
        )
    }

    enum Action {
        case editorTabs(TabPagesAction<Tabs.State, Tabs.Action>)

        case didTapLaunchArtists
        case didTapLaunchSchedule
    }

    @Reducer
    enum Tabs {
        case artistEditor(ArtistEditor)
        case scheduleEditor(ScheduleEditor)
    }

    var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case .didTapLaunchArtists:
                state.editorTabs.append(.artistEditor(ArtistEditor.State(name: "Oaktrail")))
                return .none
            case .didTapLaunchSchedule:

                state.editorTabs.append(.scheduleEditor(ScheduleEditor.State(name: "11-10-24")))
                return .none
            case .editorTabs:
                return .none
            }
        }
        .forEach(\.editorTabs, action: \.editorTabs) {
            Reduce { state, action in
                return .none
            }
            Tabs.body
        }
        ._printChanges()
    }
}

struct EventEditorTabBarView: View {
    @Bindable var store: StoreOf<EventEditorTabBar>

    var body: some View {
        TabPagesView(
            store: $store.scope(state: \.editorTabs, action: \.editorTabs),
            root: {
                VStack {
                    Text("Root View")
                    Button("Launch Artists") {
                        store.send(.didTapLaunchArtists)
                    }
                    Button("Launch Schedule") {
                        store.send(.didTapLaunchSchedule)
                    }
                }
            },
            label: { state in
                switch state {
                case .artistEditor(let state):
                    Label("\(state.name)", systemImage: "doc")
                case .scheduleEditor(let state):
                    Label("\(state.name)", systemImage: "doc")
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

extension EventEditorTabBar.Tabs.State: Equatable {}


// MARK: TabPagesReducer
@ObservableState
public struct TabPagesState<Element> {
    var selection: TabPageID? // TODO: Shared?
    var pages: IdentifiedArrayOf<TabPageIdentified<Element>> = .init()

    init() { }

    init<C: Collection>(pages: C) where C.Element == Element {
        @Dependency(\.uuid) var uuid
        self.pages = IdentifiedArray(uncheckedUniqueElements: pages.map {
            TabPageIdentified(id: uuid(), element: $0)
        })

        self.selection = self.pages.first?.id
    }

    mutating func append(_ element: Element) {
        @Dependency(\.uuid) var uuid
        pages.append(.init(id: uuid(), element: element))
    }
}
extension TabPagesState: Equatable where Element: Equatable {}
extension TabPagesState: Hashable where Element: Hashable {}
public typealias TabPageID = UUID

@ObservableState
struct TabPageIdentified<T>: Identifiable {
    var id: TabPageID
    var element: T
}

extension TabPageIdentified: Equatable where T: Equatable {}
extension TabPageIdentified: Hashable where T: Hashable {}

@CasePathable
public enum TabPagesAction<State: Equatable, Action>: BindableAction {
    case page(IdentifiedAction<TabPageID, TabPageAction<Action>>)
    case binding(BindingAction<TabPagesState<State>>)
}

@CasePathable
public enum TabPageAction<Element> {
    case page(Element)
    case tab(TabAction)
}


@Reducer
public struct TabPages<Base: Reducer, Destination: Reducer>: Reducer where Destination.State: Equatable {
    let base: Base
    let toTabState: WritableKeyPath<Base.State, TabPagesState<Destination.State>>
    let toTabAction: CaseKeyPath<Base.Action, TabPagesAction<Destination.State, Destination.Action>>
    let destination: Destination
    let fileID: StaticString
    let line: UInt

    public typealias State = Base.State
    public typealias Action = Base.Action

    public var body: some ReducerOf<Self> {
        Scope(state: toTabState, action: toTabAction) {
            BindingReducer()

            Reduce { state, action in
                switch action {
                case .binding:
                    return .none
                case let .page(.element(id: id, action: .tab(tabAction))):

                    return reduceTab(state: &state, id: id, action: tabAction)
                case .page:
                    return .none
                }
            }
            .forEach(\.pages, action: \.page) {
                Scope(state: \.element, action: \.page) {
                    destination
                }
            }
        }

        base
    }

    func reduceTab(
        state: inout TabPagesState<Destination.State>,
        id: TabPageID,
        action: TabAction
    ) -> Effect<TabPagesAction<Destination.State, Destination.Action>> {
        switch action {
        case .didTapClose:
            if state.selection == id,
               let index = state.pages.index(id: id) {
                state.selection = state.pages.elementAfter(index)?.id
            }

            state.pages.remove(id: id)
            state.selectLastPageIfSelectionNotPresent()
            return .none
        case .didTapTab:
            state.selection = id
            return .none

        case .didTapCloseOtherTabs:
            state.pages = state.pages.filter { $0.id == id }
            state.selection = id
            return .none

        case .didTapCloseTabsToTheLeft:
            guard let index = state.pages.index(id: id),
                  index != state.pages.startIndex
            else { return .none }

            state.pages.removeSubrange(state.pages.startIndex..<index)
            state.selectLastPageIfSelectionNotPresent()
            return .none

        case .didTapCloseTabsToTheRight:
            guard let index = state.pages.index(id: id),
                  index != state.pages.endIndex
            else { return .none }

            state.pages.removeSubrange((index + 1)..<state.pages.endIndex)
            state.selectLastPageIfSelectionNotPresent()

            return .none
        }
    }
}

extension TabPagesState {
    mutating func selectLastPageIfSelectionNotPresent() {
        if let selection = self.selection,
           !self.pages.ids.contains(selection) {
            self.selection = self.pages.ids.last
        }
    }
}

extension Collection {
    func elementAfter(_ index: Index) -> Element? {
        self[safe: self.index(after: index)]
    }

    subscript(safe index: Index) -> Element? {
        self.indices.contains(index) ? self[index] : nil
    }
}

extension Reducer {
    public func forEach<DestinationState, DestinationAction, Destination: Reducer>(
        _ toTabState: WritableKeyPath<Self.State, TabPagesState<DestinationState>>,
        action toTabAction: CaseKeyPath<Self.Action, TabPagesAction<DestinationState, DestinationAction>>,
        @ReducerBuilder<DestinationState, DestinationAction> destination: () -> Destination,
        fileID: StaticString = #fileID,
        line: UInt = #line
    ) -> TabPages<Self, Destination>
    where Destination.State == DestinationState, Destination.Action == DestinationAction {
        TabPages(
            base: self,
            toTabState: toTabState,
            toTabAction: toTabAction,
            destination: destination(),
            fileID: fileID,
            line: line
        )
    }

    /// A special overload of ``Reducer/forEach(_:action:destination:fileID:line:)-yz3v`` for enum
    /// reducers.
    public func forEach<DestinationState: CaseReducerState, DestinationAction>(
      _ toTabState: WritableKeyPath<State, TabPagesState<DestinationState>>,
      action toTabAction: CaseKeyPath<Action, TabPagesAction<DestinationState, DestinationAction>>
    ) -> some ReducerOf<Self> where DestinationState.StateReducer.Action == DestinationAction {
        self.forEach(toTabState, action: toTabAction) {
            DestinationState.StateReducer.body
        }
    }
}
extension SwiftUI.Bindable {
  /// Derives a binding to a store focused on ``StackState`` and ``StackAction``.
  ///
  /// See ``SwiftUI/Binding/scope(state:action:fileID:line:)`` defined on `Binding` for more
  /// information.
  public func scope<State: ObservableState, Action, ElementState, ElementAction>(
    state: KeyPath<State, TabPagesState<ElementState>>,
    action: CaseKeyPath<Action, TabPagesAction<ElementState, ElementAction>>
  ) -> Binding<Store<TabPagesState<ElementState>, TabPagesAction<ElementState, ElementAction>>>
  where Value == Store<State, Action> {
      self[state: state, action: action]
  }
}

extension Store where State: ObservableState {
  fileprivate subscript<ElementState, ElementAction>(
    state state: KeyPath<State, TabPagesState<ElementState>>,
    action action: CaseKeyPath<Action, TabPagesAction<ElementState, ElementAction>>
  ) -> Store<TabPagesState<ElementState>, TabPagesAction<ElementState, ElementAction>> {
    get {
        self.scope(state: state, action: action)
    }
    set {}
  }
}


struct TabPagesView<
    State: ObservableState & Equatable,
    Action,
    Root: View,
    Label: View,
    Destination: View
>: View {
    init(
        store: Binding<Store<TabPagesState<State>, TabPagesAction<State, Action>>>,
        @ViewBuilder root: @escaping () -> Root,
        @ViewBuilder label: @escaping (State) -> Label,
        @ViewBuilder destination: @escaping (Store<State, Action>) -> Destination
    ) {
        self.store = store.wrappedValue
        self.root = root
        self.label = label
        self.destination = destination
    }

    @Bindable var store: Store<TabPagesState<State>, TabPagesAction<State, Action>>
    let root: () -> Root
    let label: (State) -> Label
    let destination: (Store<State, Action>) -> Destination


    var body: some View {
        VStack(spacing: 0) {
            TopRowTabs (
                selection: $store.selection,
                tabs: $store.pages.elementsUniqued, // This could be a performance issue, with 
                send: { store.send(.page($0)) },
                tabLabel: { tab in
                    label(tab.element)
                }
            )
            .fixedSize(horizontal: false, vertical: true)

            Group {
                if let selection = store.selection,
                   let childStore = store.scope(state: \.pages[id: selection], action: \.page[id: selection])
                {
                    destination(childStore.scope(state: \.element, action: \.page))
                } else {
                    root()
                }
            }
            .frame(maxHeight: .infinity)
        }
    }
}

struct Identified<T, ID: Hashable>: Identifiable {
    let id: ID
    let value: T

    init(_ value: T, id: ID) {
        self.id = id
        self.value = value
    }

    init(_ value: T, id idKeyPath: KeyPath<T, ID>) {
        self.value = value
        self.id = self.value[keyPath: idKeyPath]
    }
}

@dynamicMemberLookup
struct WithOffset<Index: Comparable, Value> {
    var offset: Index
    var value: Value

    subscript<T>(dynamicMember keyPath: KeyPath<Value, T>) -> T {
        value[keyPath: keyPath]
    }
}


extension WithOffset: Identifiable where Value: Identifiable {
    var id: Value.ID { value.id }
}

extension Array {
    var withOffset: [WithOffset<Index, Element>] {
        get {
            zip(self.indices, self).map { WithOffset(offset: $0, value: $1) }
        }

        set {
            self = newValue.map(\.value)
        }
    }
}

extension IdentifiedArray where Element: Identifiable, Element.ID == ID {
    var elementsUniqued: [Element] {
        get { self.elements }
        set { self = Self(uniqueElements: newValue) }
    }
}

struct TopRowTabs<
    State: Identifiable,
    Action,
    TabLabel: View
>: View {
    @Binding var selection: State.ID?
    @Binding var tabs: [State]
    var send: (IdentifiedAction<State.ID, TabPageAction<Action>>) -> Void
    @ViewBuilder var tabLabel: (State) -> TabLabel

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                ForEach($tabs.withOffset) { tab, _ in
                    TabWithStructure(
                        send: { self.send(.element(id: tab.id, action: .tab($0))) },
                        content: { tabLabel(tab.value) }
                    )
                    .environment(\.isSelectedTab, selection == tab.id)
                    .environment(\.isFirstTab, tab.offset == tabs.startIndex)
                    .environment(\.isLastTab, tab.offset == tabs.endIndex - 1)
                    .environment(\.isOnlyTab, tabs.count == 1)
                }
            }
        }
        .background(.background)
        .scrollIndicators(.never)
    }



}


public enum TabAction: Hashable {
    case didTapClose
    case didTapTab
    case didTapCloseOtherTabs
    case didTapCloseTabsToTheLeft
    case didTapCloseTabsToTheRight
}

extension EnvironmentValues {
    @Entry var isSelectedTab = false
    @Entry var isFirstTab = false
    @Entry var isLastTab = false
    @Entry var isOnlyTab = false
}

struct TabWithStructure<Content: View>: View {
    var send: (TabAction) -> Void
    @ViewBuilder var content: () -> Content
    @Environment(\.isSelectedTab) var isSelectedTab

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Tab(send: send, content: content)
                Divider()
            }

            if !isSelectedTab {
                Divider()
            }
        }
    }
}

struct Tab<Content: View>: View {
    init(
        send: @escaping (TabAction) -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.send = send
        self.content = content()
    }

    var send: (TabAction) -> Void
    var content: Content

    @SwiftUI.State var isHovering = false

    @Environment(\.isSelectedTab) var isSelected
    @Environment(\.isFirstTab) var isFirstTab
    @Environment(\.isLastTab) var isLastTab
    @Environment(\.isOnlyTab) var isOnlyTab

    var body: some View {

        Button {
            send(.didTapTab)
        } label: {
            HStack(spacing: 1) {
                CloseButton {
                    send(.didTapClose)
                }
                .opacity(isHovering ? 1 : 0)

                content
            }
        }
        .padding(.leading, 1)
        .padding(.trailing, 15)
        .padding(.vertical, 4)
        .frame(minWidth: 100, minHeight: 40)
        .contentShape(.rect)
        .background(
            isSelected ?
            AnyShapeStyle(.windowBackground) :
                AnyShapeStyle(BackgroundStyle.background)
        )
        .hover($isHovering)
        .buttonStyle(.plain)
        .contextMenu {
            Button("Close Tab") {
                send(.didTapClose)
            }

            Button("Close Other Tabs") {
                send(.didTapCloseOtherTabs)
            }
            .disabled(isOnlyTab)

            Button("Close Tabs to the Left") {
                send(.didTapCloseTabsToTheLeft)
            }
            .disabled(isFirstTab)

            Button("Close Tabs to the Right") {
                send(.didTapCloseTabsToTheRight)
            }
            .disabled(isLastTab)
        }
    }

    struct CloseButton: View {
        @SwiftUI.State var isHovering = false
        var action: () -> Void

        var body: some View {
            Button(role: .destructive, action: action) {
                Label("Close", systemImage: "xmark")
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.accessoryBar)
        }
    }
}

#Preview(
    traits: .fixedLayout(width: 500, height: 300)
) {
    EventEditorTabBarView(store: Store(initialState: EventEditorTabBar.State()) {
        EventEditorTabBar()
    })
}
