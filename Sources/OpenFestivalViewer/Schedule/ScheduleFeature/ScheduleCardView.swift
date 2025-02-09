//
//  SwiftUIView.swift
//  
//
//  Created by Woody on 2/20/22.
//

import SwiftUI
import ComposableArchitecture
import OpenFestivalModels

struct ScheduleCardView: View {
    let performance: Event.Performance
    let isSelected: Bool

    @ScaledMetric var scale: CGFloat = 1

    public init(_ performance: Event.Performance, isSelected: Bool, isFavorite: Bool) {
        self.performance = performance
        self.isSelected = isSelected
    }
    
    @Shared(.event) var event
    @Environment(\.eventColorScheme) var eventColorScheme


    var isFavorite: Bool {
        @Shared(.favoriteArtists) var favorites

        return favorites.contains(performance)
    }

    public var body: some View {
        ScheduleCardBackground(color: eventColorScheme.stageColors[performance.stageID], isSelected: isSelected) {
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text(performance.title)
                    Text(performance.startTime..<performance.endTime, format: .performanceTime)
                        .font(.caption)
                }

                Spacer()
                
                if isFavorite {
                    Image(systemName: "heart.fill")
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(square: 20)
                        .padding()
                }
            }
            .padding(.top, 2)

        }
        .id(performance.id)
        .tag(performance.id)
    }
 
}
