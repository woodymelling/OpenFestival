//
//  SwiftUIView.swift
//
//
//  Created by Woodrow Melling on 4/22/22.
//

import SwiftUI
import PDFKit
import ImageCaching
import ComposableArchitecture
import Zoomable
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
        CachedAsyncImage(url: store.url.rawValue) {
            ProgressView()
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Site Map")
    }
}


extension URLCache {

    static let siteMapImageCache = URLCache(memoryCapacity: 512_000_000, diskCapacity: 10_000_000_000)
}
