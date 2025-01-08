//
//  NotificationsFeature.swift
//  OpenFestival
//
//  Created by Woodrow Melling on 1/3/25.
//
import ComposableArchitecture
import SwiftUI

@Reducer
public struct NotificationsFeature {
    public struct State {}
    public enum Action {}
}


struct NotificationsView: View {
    let store: StoreOf<NotificationsFeature>

    var body: some View {
        Text("TODO: NotificationsView")
    }
}
