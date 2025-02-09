//
//  SwiftUIView.swift
//
//
//  Created by Woodrow Melling on 4/22/22.
//

import SwiftUI
import PDFKit
//import Kingfisher
import ComposableArchitecture
import Zoomable
import Nuke
import NukeUI
import OpenFestivalModels

@Reducer
public struct SiteMapFeature {

    @ObservableState
    public struct State: Equatable {
        @Shared var url: Event.SiteMapImageURL
    }

    public enum Action: Equatable {}

    public var body: some ReducerOf<Self> {
        EmptyReducer()
    }
}

struct SiteMapView: View {

    let store: StoreOf<SiteMapFeature>

    var body: some View {

        LazyImage(url: store.url.rawValue) { state in
            if let image = state.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
//                    .zoomable()
            } else if state.error != nil {
                Color.red // Indicates an error
            } else {
                ProgressView()
            }
        }
//        LazyImage(url: store.url) {
//            $0
//                .resizable()
//                .aspectRatio(contentMode: .fit)
//                .zoomable()
//        } placeholder: {
//            ProgressView()
//        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Site Map")
    }
}


extension URLCache {

    static let siteMapImageCache = URLCache(memoryCapacity: 512_000_000, diskCapacity: 10_000_000_000)
}
