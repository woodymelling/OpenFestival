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
import CachedAsyncImage
import Zoomable

@Reducer
public struct SiteMapFeature {

    @ObservableState
    public struct State: Equatable {
        var url: URL
    }

    public enum Action: Equatable {}

    public var body: some ReducerOf<Self> {
        EmptyReducer()
    }
}

struct SiteMapView: View {

    let store: StoreOf<SiteMapFeature>

    var body: some View {
        WithPerceptionTracking {
            CachedAsyncImage(url: store.url) {
                $0
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .zoomable()
            } placeholder: {
                ProgressView()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Site Map")
    }
}
