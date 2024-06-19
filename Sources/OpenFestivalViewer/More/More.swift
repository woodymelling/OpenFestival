//
// MoreDomain.swift
//
//
//  Created by Woody on 4/22/2022.
//

import Foundation
import ComposableArchitecture
import SwiftUI

@Reducer
public struct More {
    public init() {}

    @ObservableState
    public struct State: Equatable {
        public init() {}

        @Shared(.event) var event

        @Presents var destination: Destination.State?
    }

    public enum Action {

        case didTapNotifications
        case didTapSiteMap
        case didTapContactInfo
        case didTapAddress
        case didTapWorkshops

        case didExitEvent

        case destination(PresentationAction<Destination.Action>)
    }

    @Reducer(state: .equatable)
    public enum Destination {
        case address(AddressFeature)
        case contactInfo(ContactInfoFeature)
        case siteMap(SiteMapFeature)
        //        case notifications(Notifications)
        //        case workshops(WorkshopsFeature)
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {

            case .didExitEvent:
                break

            case .didTapNotifications:
                break

            case .didTapSiteMap:

                guard let siteMapImageURL = state.event.siteMapImageURL else {
                    return .none
                }
                state.destination = .siteMap(SiteMapFeature.State(url: siteMapImageURL))

            case .didTapContactInfo:
                guard state.event.contactNumbers.hasElements
                else { return .none }

                state.destination = .contactInfo(ContactInfoFeature.State(contactNumbers: state.event.contactNumbers))

            case .didTapAddress:
                guard let address = state.event.address else {
                    return .none
                }

                state.destination = .address(
                    AddressFeature.State(
                        address: address,
                        latitude: state.event.latitude ?? "",
                        longitude: state.event.longitude ?? ""
                    )
                )

            case .didTapWorkshops:
                //                state.destination = .workshops(.init())
                break

            case .destination:

                return .none
            }
            return .none
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

public struct MoreView: View {
    @Perception.Bindable var store: StoreOf<More>

    public init(store: StoreOf<More>) {
        self.store = store
    }

    @Environment(\.eventColorScheme) var eventColorScheme

    public var body: some View {
        WithPerceptionTracking {
            List {
                Section {
                    MoreButton(
                        "Workshops",
                        image: Image(systemName: "figure.yoga"),
                        color: eventColorScheme.workshopsColor
                    ) {
                        store.send(.didTapWorkshops)
                    }
                }

                Section {
                    if store.event.siteMapImageURL != nil {
                        MoreButton(
                            "Site Map",
                            systemName: "map.fill",
                            color: eventColorScheme.otherColors[1]
                        ) {
                            store.send(.didTapSiteMap)
                        }
                    }

                    if store.event.address != nil {
                        MoreButton(
                            "Address",
                            systemName: "mappin",
                            color: eventColorScheme.otherColors[2]
                        ) {
                            store.send(.didTapAddress)
                        }
                    }
                }

                Section {
                    MoreButton(
                        "Notifications",
                        systemName: "bell.badge.fill",
                        color: eventColorScheme.otherColors[3]
                    ) {
                        store.send(.didTapNotifications)
                    }
                }

                Section {
                    if store.event.contactNumbers.hasElements {
                        MoreButton(
                            "Emergency Contact",
                            systemName: "phone.fill",
                            color: eventColorScheme.otherColors[4]
                        ) {
                            store.send(.didTapContactInfo)
                        }
                    }
                }

                //                    Section {
                //                        if !store.isEventSpecificApplication {
                //                            Button {
                //                                store.send(.didExitEvent, animation: .default)
                //                            } label: {
                //                                Text("Exit \(store.eventData.event.name)")
                //                            }
                //                        }
                //                    }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("More")
            //            .navigationDestinationWrapper(
            //                item: $store.scope(state: \.destination?.workshops, action: \.destination.workshops),
            //                destination: WorkshopsView.init
            //            )
            .navigationDestination(
                item: $store.scope(state: \.destination?.siteMap, action: \.destination.siteMap),
                destination: SiteMapView.init
            )
            .navigationDestination(
                item: $store.scope(state: \.destination?.address, action: \.destination.address),
                destination: AddressView.init
            )
            //            .navigationDestinationWrapper(
            //                item: $store.scope(state: \.destination?.notifications, action: \.destination.notifications),
            //                destination: NotificationsView.init
            //            )
            .navigationDestination(
                item: $store.scope(state: \.destination?.contactInfo, action: \.destination.contactInfo),
                destination: ContactInfoView.init
            )


        }
    }

    struct MoreButton: View {
        var title: () -> Text
        var image: () -> Image
        var color: Color
        var action: () -> Void

        init(_ title: LocalizedStringKey, systemName: String, color: Color, action: @escaping () -> Void) {
            self.title = { Text(title) }
            self.image = { Image(systemName: systemName) }
            self.color = color
            self.action = action
        }

        init(_ title: LocalizedStringKey, image: Image, color: Color, action: @escaping () -> Void) {
            self.title = { Text(title) }
            self.image = { image.resizable() }
            self.color = color
            self.action = action
        }

        var body: some View {
            Button(action: action) {
                Label(title: title, icon: image)
                    .labelStyle(ColorfulIconLabelStyle(color: color))
            }
        }

        internal struct ColorfulIconLabelStyle: LabelStyle {
            var color: Color

            func makeBody(configuration: Configuration) -> some View {
                Label {
                    configuration.title
                        .foregroundStyle(Color(.label))
                } icon: {
                    configuration.icon
                        .aspectRatio(contentMode: .fit)
                        .font(.system(size: 17))
                        .frame(square: 20)
                        .foregroundColor(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 7)
                                .frame(square: 28)
                                .foregroundColor(color)
                        )
                }
            }
        }
    }
}







struct MoreView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MoreView(
                store: .init(
                    initialState: .init(),
                    reducer: More.init
                )
            )
        }
    }
}
