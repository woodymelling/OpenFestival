//
//  Explore.swift
//  OpenFestival
//
//  Created by Woodrow Melling on 1/3/25.
//

import SwiftUI
import ComposableArchitecture

@Reducer
public struct ExploreFeature {
    public struct State {}
    
    public enum Action {}
}

// TODO: Explore
struct ExploreView: View {
    let store: StoreOf<ExploreFeature>

    var body: some View {
        Text("TODO: Explore")
    }
}
