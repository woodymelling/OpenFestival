//
//  File.swift
//  
//
//  Created by Woodrow Melling on 6/15/24.
//

import Foundation
import SwiftUI
import CachedAsyncImage
import OpenFestivalModels
import ComposableArchitecture

public struct StageIconView: View {
    public init(stageID: Event.Stage.ID) {
        self.stageID = stageID
    }

    var stageID: Event.Stage.ID

    @Environment(\.colorScheme) var colorScheme

    @Shared(.event) var event

    @Environment(\.eventColorScheme) var eventColorScheme
    var stageColor: Color {
        eventColorScheme.stageColors[stageID]
    }

    public var body: some View {
        if let stage = event.stages[id: stageID] {
            GeometryReader { geo in
                CachedAsyncIcon(
                    url: stage.iconImageURL,
                    placeholder: {
                        ZStack {
                            Text(stage.name)
                                .font(.system(size: 500, weight: .bold))
                                .minimumScaleFactor(0.001)
                                .padding(2)
                                .background(LinearGradient(colors: [stageColor, .primary], startPoint: .topLeading, endPoint: .bottomTrailing))
                        }
                })
//                .frame(square: geo.size.width)
//                .if(stage.iconImageURL == nil, transform: {
//                    $0.background(LinearGradient(colors: [stageColor, .primary], startPoint: .topLeading, endPoint: .bottomTrailing))
//                })
                .foregroundStyle(colorScheme == .light ? stageColor : .white)
                .clipShape(Circle())
            }
        }


    }
}



public struct CachedAsyncIcon<Content: View>: View {
    public init(
        url: URL?,
        contentMode: SwiftUI.ContentMode = .fill,
        @ViewBuilder placeholder: @escaping () -> Content
    ) {
        self.url = url
        self.contentMode = contentMode
        self.placeholder = placeholder
    }


    var url: URL?
    var contentMode: SwiftUI.ContentMode
    @ViewBuilder var placeholder: () -> Content

    @State var hasTransparency = true

    public var body: some View {
        CachedAsyncImage(url: url, urlCache: .iconCache) { image in
            image
                .resizable()
                .renderingMode(hasTransparency ? .template : .original)
                .aspectRatio(contentMode: .fit)
                .frame(alignment: .center)
//                    .task {
//                        self.hasTransparency = await image.frame(square: 100).hasTransparency()
//                    }
        } placeholder: {
            placeholder()
        }
    }
}

extension URLCache {

    static let iconCache = URLCache(memoryCapacity: 512_000_000, diskCapacity: 10_000_000_000)
}
