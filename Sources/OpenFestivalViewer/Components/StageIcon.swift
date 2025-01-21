//
//  File.swift
//  
//
//  Created by Woodrow Melling on 6/15/24.
//

import Foundation
import SwiftUI
import OpenFestivalModels
import ComposableArchitecture
import ImageCaching

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
            CachedAsyncIcon(
                url: stage.iconImageURL,
                placeholder: {
                    DefaultStageIcon(stage: stage)
            })
            .foregroundStyle(colorScheme == .light ? stageColor : .white)
        }
    }
}

struct DefaultStageIcon: View {
    var stage: Event.Stage
    @Environment(\.eventColorScheme) var eventColorScheme

    var stageColor: Color {
        eventColorScheme.stageColors[stage.id]
    }
    var body: some View {
        ZStack {
            Text("\(stage.name.first.map(String.init) ?? "")")
                .font(.system(size: 300, weight: .heavy))
                .minimumScaleFactor(0.001)
                .padding()
                .background {
                    Circle()
                        .fill(stageColor)
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
        CachedAsyncImage(url: url) {
            $0.resizable()
                .renderingMode(hasTransparency ? .template : .original)
                .aspectRatio(contentMode: .fit)
                .frame(alignment: .center)
            
        } placeholder: {
            placeholder()
        }
    }
}

extension URLCache {

    static let iconCache = URLCache(memoryCapacity: 512_000_000, diskCapacity: 10_000_000_000)
}
