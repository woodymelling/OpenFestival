//
//  SwiftUIView.swift
//  
//
//  Created by Woodrow Melling on 5/21/22.
//

import SwiftUI
import ComposableArchitecture
import OpenFestivalModels

@Reducer
public struct LocationFeature {
    @ObservableState
    public struct State: Equatable {
        @Shared var location: Event.Location
    }
    
    public enum Action {
        case didTapOpenInAppleMaps
        case didTapOpenInGoogleMaps
    }
    
    public func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .didTapOpenInAppleMaps:
            reportIssue("REIMPLEMENT")
            return .none

//            guard let url = URL(string: "http://maps.apple.com/?daddr=\(state.latitude),\(state.longitude)") else { return .none }
//
//            return .run { _ in
//                @Dependency(\.openURL) var openURL
//                await openURL(url)
//            }
            
        case .didTapOpenInGoogleMaps:
            reportIssue("REIMPLEMENT")
            return .none
//            guard let url = URL(string: "https://www.google.com/maps/?q=\(state.latitude),\(state.longitude)") else { return .none }
//            
//            return .run { _ in
//                @Dependency(\.openURL) var openURL
//                await openURL(url)
//            }
        }
    }
}

struct AddressView: View {
    let store: StoreOf<LocationFeature>
    
    var body: some View {
        List {
            Text(store.location.address)
                .font(.headline)
                .textSelection(.enabled)

            Button { store.send(.didTapOpenInAppleMaps) } label: {
                Label {
                    Text("Open in Apple Maps")
                } icon: {
                    Image("apple-maps", bundle: .module)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            }


            Button { store.send(.didTapOpenInGoogleMaps) } label: {
                Label {
                    Text("Open in Google Maps")

                } icon: {
                    Image("google-maps", bundle: .module)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            }
        }
        .navigationTitle("Address")
    }
}

struct AddressView_Previews: PreviewProvider {
    static var previews: some View {
        AddressView(
            store: Store(
                initialState: .init(
                    location: Shared(value: Event.Location(address: "3901 Kootenay Hwy, Fairmont Hot Springs, BC V0B 1L1, Canada"))
                ),
                reducer: LocationFeature.init
            )
        )
    }
}
