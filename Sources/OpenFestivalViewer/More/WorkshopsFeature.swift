//
//  WorkshopsFeature.swift
//  OpenFestival
//
//  Created by Woodrow Melling on 1/3/25.
//

import ComposableArchitecture
import SwiftUI

@Reducer
public struct WorkshopsFeature {
    public struct State {}
    public enum Action {}
}

struct WorkshopsView: View {
    let store: StoreOf<WorkshopsFeature>
    
    var body: some View {
        Text("TODO: Workshops")
    }
}

