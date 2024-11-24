//
//  ArtistEditor.swift
//  OpenFestival
//
//  Created by Woodrow Melling on 11/9/24.
//



import ComposableArchitecture
import SwiftUI
import OpenFestivalModels


@Reducer
struct ArtistEditor {
    @ObservableState
    struct State: Equatable {
        @Shared var artist: Event.Artist
    }
}

struct ArtistEditorView: View {
    let store: StoreOf<ArtistEditor>
    var body: some View {
        Label("Artists Editor for: \(store.artist.name)", systemImage: "person")
    }
}

@Reducer
struct ScheduleEditor {
    @ObservableState
    struct State: Equatable {
        @Shared var schedule: Event.Schedule
    }
}

struct ScheduleEditorView: View {
    let store: StoreOf<ScheduleEditor>
    var body: some View {
        VStack {
            Label("Schedule Editor for: \(store.schedule.name)", systemImage: "calendar")
        }
    }
}
