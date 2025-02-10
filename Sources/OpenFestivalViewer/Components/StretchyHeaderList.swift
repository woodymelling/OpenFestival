//
//  StretchHEader.swift
//  SwiftUITesting
//
//  Created by Woodrow Melling on 1/12/25.
//

import SwiftUI


extension EnvironmentValues {
    @Entry var showingStretchListDebugInformation = false
    @Entry var stretchFactor: CGFloat = 400
}

struct StretchyHeaderList<StretchyContent: View, ListContent: View>: View {

    init(
        title: Text,
        @ViewBuilder stretchyContent: () -> StretchyContent,
        @ViewBuilder listContent: () -> ListContent

    ) {
        self.stretchyContent = stretchyContent()
        self.titleContent = title
        self.listContent = listContent()
    }

    var titleContent: Text
    var stretchyContent: StretchyContent
    var listContent: ListContent


    @Environment(\.stretchFactor) var stretchFactor
    @State var offset: CGFloat = .zero
    @State var titleVisibility = false


    var scale: CGFloat {
        let trueScale = (-offset / stretchFactor) + 1

        return if trueScale >= 1 {
            trueScale
        } else {
            pow(trueScale, 1/5)
        }
    }

    var showNavigationBar: Bool {
        offset > 0
    }

    var showTitleInNavigationBar: Bool {
        offset > 10
    }

    @Environment(\.showingStretchListDebugInformation) var showingStretchListDebugInformation

    var headerContentHeight: CGFloat = UIScreen.main.bounds.width


    var body: some View {
        List {
            self.stretchyContent
                .scaledToFill()
                .overlay {
                    topDimOverlay
                }
                .scaleEffect(scale, anchor: .bottom) // For stretching
                .listRowInsets(EdgeInsets()) // Remove side + bottom padding from row
                .ignoresSafeArea()
                .frame(height: headerContentHeight, alignment: .center) // Set content height
                .listRowSeparator(.hidden, edges: .top) // Remove the top separator
                // The image can can be bigger then the bounds. clip it, but give it plenty of vertical size so that it can never go off the top of the screen
                .clipShape(ScaledShape(shape: Rectangle(), scale: .init(width: 1, height: 2), anchor: .bottom))
                .overlay(alignment: .bottomLeading) {
                    TitleView(titleContent: self.titleContent)
                }

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
        .navigationTitle(showNavigationBar ? self.titleContent : Text(""))
        .toolbarBackground(showNavigationBar ? .visible : .hidden)
        .animation(.default, value: self.showNavigationBar)
        .onScrollGeometryChange(for: CGFloat.self) {
            $0.contentOffset.y + $0.contentInsets.top
        } action: { _, newValue in
            offset = newValue
        }
    }

    private var topDimOverlay: some View {
        let shadowColor = Color(.systemBackground)
        // Adjust the height/opacity to taste:
        return LinearGradient(
            gradient: Gradient(colors: [
                shadowColor,
                shadowColor.opacity(0.1),
                shadowColor
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
//        .frame(height: 120) // How tall the shadow region is
        .opacity(dimOpacity(for: offset))
    }

    private func dimOpacity(for offset: CGFloat) -> CGFloat {
        // If offset is 0 or negative, we’re pulling down,
        // so we can keep the shadow at 0% opacity.
        guard offset > 0 else { return 0 }

        // Example logic: fade from 0 → 1 as offset goes 0 → 150
        let maxOffset: CGFloat = 100
        let clippedOffset = min(offset, maxOffset)
        return clippedOffset / maxOffset
    }

    struct TitleView: View {
        var titleContent: Text

        var body: some View {
            self.titleContent
                .font(.largeTitle)
                .fontDesign(.default)
                .safeAreaPadding()
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
                StretchyHeaderList(title: Text("Slynk")) {
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

//#Preview("Vertical") {
//    _Preview(image: Image(.spashPhotoVertical))
//}
//
//#Preview("Horizontal") {
//    _Preview(image: Image(.splashPhotoLandscapeBad))
//}

