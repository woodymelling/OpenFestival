//
//  SwiftUIView.swift
//  
//
//  Created by Woody on 2/20/22.
//

import SwiftUI
import ComposableArchitecture
import ScheduleComponents
import OpenFestivalModels

struct ScheduleCardView: View {
    let card: Event.Performance
    let isSelected: Bool
    let isFavorite: Bool

    @ScaledMetric var scale: CGFloat = 1

    public init(_ card: Event.Performance, isSelected: Bool, isFavorite: Bool) {
        self.card = card
        self.isSelected = isSelected
        self.isFavorite = isFavorite
    }
    
    @Shared(.event) var event
    @Environment(\.eventColorScheme) var eventColorScheme

    public var body: some View {
        ScheduleCardBackground(color: eventColorScheme.stageColors[card.stageID], isSelected: isSelected) {
            HStack(alignment: .center) {
                
                GeometryReader { geo in
                    VStack(alignment: .leading) {
                        Text(card.title)
                        Text(card.startTime..<card.endTime, format: .performanceTime)
                            .font(.caption)
                        
//                        if let subtext = card.subtext {
//                            Text(subtext)
//                                .font(.caption2)
//                        }
                    }
                    .padding(.top, 2)
                }
                
                Spacer()
                
                if isFavorite {
                    Image(systemName: "heart.fill")
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(square: 15)
                        .padding(.trailing)
                }
            }
        }
        .id(card.id)
        .tag(card.id)
    }
 
}
