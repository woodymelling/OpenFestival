//
//  SwiftUIView.swift
//  
//
//  Created by Woodrow Melling on 5/21/22.
//

import SwiftUI
import ComposableArchitecture

@Reducer
public struct AddressFeature {
    

    
    @ObservableState
    public struct State: Equatable {
        var address: String
        var latitude: String
        var longitude: String
    }
    
    public enum Action {
        case didTapOpenInAppleMaps
        case didTapOpenInGoogleMaps
    }
    
    public func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .didTapOpenInAppleMaps:
            guard let url = URL(string: "http://maps.apple.com/?daddr=\(state.latitude),\(state.longitude)") else { return .none }

            return .run { _ in
                @Dependency(\.openURL) var openURL
                await openURL(url)
            }
            
        case .didTapOpenInGoogleMaps:
            guard let url = URL(string: "https://www.google.com/maps/?q=\(state.latitude),\(state.longitude)") else { return .none }
            
            return .run { _ in
                @Dependency(\.openURL) var openURL
                await openURL(url)
            }
        }
    }
}

struct AddressView: View {
    let store: StoreOf<AddressFeature>
    
    var body: some View {
        List {
            Text(store.address)
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
                    address: "3901 Kootenay Hwy, Fairmont Hot Springs, BC V0B 1L1, Canada",
                    latitude: "",
                    longitude: ""
                ),
                reducer: AddressFeature.init
            )
        )
    }
}
