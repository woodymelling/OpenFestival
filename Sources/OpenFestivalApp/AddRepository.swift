//
//  AddRepository.swift
//  OpenFestivalApp
//
//  Created by Woodrow Melling on 6/30/24.
//

import Foundation
import GitClient
import ComposableArchitecture
import OpenFestivalParser
import SwiftUI

@Reducer
public struct AddRepository {
    @ObservableState
    public struct State {
        var urlInput = ""
        var isAdding = false

        var errorMessage: String?
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case didTapAddRepositoryButton
        case successfullyAddedRepository
    }

    public var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .didTapAddRepositoryButton:
                guard let url = URL(string: state.urlInput)
                else {
                    state.errorMessage = "Invalid URL"
                    return .none
                }

                state.isAdding = true

                return .run { send in
                    @Dependency(OpenFestivalClient.self)
                    var openFestivalClient

                    try await openFestivalClient.loadOrganizationFromGithub(url)

                    await send(.successfullyAddedRepository)
                } catch: { error, send in
                    print(error)
                }
            case .successfullyAddedRepository:
                state.isAdding = false
                return .run { _ in
                    @Dependency(\.dismiss) var dismiss
                    await dismiss()
                }
            case .binding:
                return .none
            }
        }
    }
}

struct AddRepositoryView: View {
    @Perception.Bindable var store: StoreOf<AddRepository>

    var body: some View {
        WithPerceptionTracking {

            NavigationStack{
                VStack {
                    VStack(alignment: .leading) {
                        TextField("URL", text: $store.urlInput)
                            .controlSize(.large)
                            .textFieldStyle(.roundedBorder)

                        if let errorMessage = store.errorMessage {
                            Text(errorMessage)
                                .foregroundStyle(.red)
                        }

                        Text("Add a festival from a github repository")
                            .font(.caption)
                    }
                    Spacer()
                    Button {
                        store.send(.didTapAddRepositoryButton)
                    } label: {
                        if store.isAdding {
                            ProgressView()
                        } else {
                            Text("Add Repository")
                        }
                    }
                    .disabled(store.isAdding)
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .navigationTitle("Add Festival")
            }
            .presentationDetents([.medium])
        }
    }
}
