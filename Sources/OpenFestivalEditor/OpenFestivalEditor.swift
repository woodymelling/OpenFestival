//
//  OpenFestivalEditor.swift
//  OpenFestival
//
//  Created by Woodrow Melling on 11/7/24.
//

import SwiftUI
import ComposableArchitecture


enum Selection: Hashable {
    case event
    case eventInfo
    case stages
    case contactNumbers
    case artists
    case artist(String)
    case schedules
    case schedule(String)

}

struct EventEditorView: View {
    @AppStorage("event-expanded") var eventExpanded = true


    @State var selections: Set<Selection> = []

    @State var artists = ["Boids", "Rhythmbox", "Overgrowth"]
    @State var tabsStore = Store(initialState: EventEditorTabBar.State()) {
        EventEditorTabBar()
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selections) {
                Folder("My Event", isExpanded: .constant(true)) {
                    File("event-info", "yaml")
                        .tag(Selection.eventInfo)
                    File("stages", "yaml")
                        .tag(Selection.stages)
                    File("contact-numbers", "yaml")
                        .tag(Selection.contactNumbers)

                    Folder("schedules") {
                        ForEach(["11-6-2024", "11-7-2024"], id: \.self) {
                            File("\($0)", "yaml")
                                .tag(Selection.schedule($0))
                        }
                    }
                    .tag(Selection.schedules)

                    Folder("artists", isExpanded: .constant(true)) {
                        ForEach($artists, id: \.self) {

                            EditableFile(title: $0, fileType: "md")
                                .tag(Selection.artist($0.wrappedValue))
                        }
                    }
                    .tag(Selection.artists)


                }
                .tag(Selection.event)
            }
            .frame(minWidth: 200)

        } detail: {
            VStack(spacing: 0) {
                EventEditorTabBarView(store: tabsStore)
            }
        }

    }

    struct Folder<Content: View>: View {
        var name: String
        var content: Content

        init(_ name: String, isExpanded: Binding<Bool>? = nil, @ViewBuilder content: () -> Content) {
            self.name = name
            self.bindingIsExpanded = isExpanded
            self.content = content()
        }

        @State var localIsExpanded = false
        var bindingIsExpanded: Binding<Bool>?

        var isExpanded: Binding<Bool> {
            bindingIsExpanded ?? $localIsExpanded
        }

        var body: some View {
            DisclosureGroup(isExpanded: isExpanded) {
                content
            } label: {
                Label(name, systemImage: "folder")
            }

        }
    }

    struct File: View {
        init(_ name: String, _ fileType: String) {
            self.name = name
            self.fileType = fileType
        }

        var name: String
        var fileType: String

        var body: some View {
            Label(name, systemImage: "doc")
        }
    }

    struct EditableFile: View {
        @Binding var title: String
        var fileType: String

        @State var isEditing = false

        var body: some View {
            HStack(alignment: .bottom, spacing: 0) {
                Label("", systemImage: "doc")

                TextField("artist name", text: $title)
            }
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
        .frame(width: 700, height: 500)
}
