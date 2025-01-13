//
//  StretchyHeaderList.swift
//  OpenFestival
//
//  Created by Woodrow Melling on 1/21/25.
//

import SwiftUI


extension EnvironmentValues {
    @Entry var showingStretchListDebugInformation = false
    @Entry var stretchFactor: CGFloat = 400
}

struct StretchyHeaderList<StretchyContent: View, ListContent: View>: View {

    init(
        @ViewBuilder title: () -> Text,
        @ViewBuilder stretchyContent: () -> StretchyContent,
        @ViewBuilder listContent: () -> ListContent

    ) {
        self.stretchyContent = stretchyContent()
        self.titleContent = title()
        self.listContent = listContent()
    }

    var titleContent: Text
    var stretchyContent: StretchyContent
    var listContent: ListContent


    @Environment(\.stretchFactor) var stretchFactor
    @State var offset: CGFloat = .zero
    @State var titleVisibility = false


    var scale: CGFloat {
        return max(1, (-offset / stretchFactor) + 1)

    }

    var showNavigationBar: Bool {
        offset > 0
    }

    var showTitleInNavigationBar: Bool {
        offset > 10
    }

    var maxHeight: CGFloat = 500

    @Environment(\.showingStretchListDebugInformation) var showingStretchListDebugInformation


    var body: some View {

        List {

            self.stretchyContent

                .frame(minWidth: UIScreen.main.bounds.width, maxWidth: .infinity)
                .aspectRatio(contentMode: .fill)
//                    .listRowInsets(EdgeInsets())
                .scaleEffect(scale, anchor: .bottom)
                .frame(maxHeight: UIScreen.main.bounds.height / 3, alignment: .bottom)
                .overlay(alignment: .bottomLeading) {
                    self.titleContent
                        .opacity(0.9)
                        .padding(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background {
                            LinearGradient(
                                colors: [
                                    Color(.systemBackground),
                                    .clear
                                ],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        }
                }
                .listRowSeparator(.hidden)

            if showingStretchListDebugInformation {

                Section {
                    Text("offset: \(offset)")
                    Text("scale: \(scale)")
                    Text("ScrollVisibility")
                }
            }

            listContent

        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(showTitleInNavigationBar ? titleContent : Text(""))
        .toolbarBackground(showNavigationBar ? .visible : .hidden)
        .animation(.default, value: self.showTitleInNavigationBar)
        .onScrollGeometryChange(for: CGFloat.self) {
            $0.contentOffset.y + $0.contentInsets.top
        } action: { _, newValue in
            offset = newValue
        }
    }
}

struct _Preview: View {

    var image: Image
    @State var isPresented: Bool = true

    var body: some View {
        NavigationStack {
            Button("go") {
                isPresented.toggle()
            }
            .navigationTitle("Artists")
            .navigationDestination(isPresented: $isPresented, destination: {
                StretchyHeaderList {
                    Text("Slynk")
                        .fontWeight(.bold)
                        .font(.largeTitle)
                } stretchyContent: {
                    image.resizable()
                } listContent: {

                    Section {
                        ForEach(1...100, id: \.self) {
                            Text("Item: \($0)")
                        }
                    }
                }
                .listStyle(.plain)
                .environment(\.showingStretchListDebugInformation, true)
            })
        }
    }
}
