//
//  File.swift
//  
//
//  Created by Woodrow Melling on 4/21/23.
//

import Foundation
import SwiftUI
import CoreMotion
import ComposableArchitecture

struct ScheduleComingSoonView: View {
    var imageURL: URL?
    
    @State var degrees: Angle = .degrees(0)
    
    @Shared(.event) var event

    var body: some View {
        ZStack {
            
//            
//            CachedAsyncImage(url: event.imageURL) {
//                ProgressView()
//            }
//            .frame(square: 300)
//            .foregroundColor(.label)
//            .rotationEffect(degrees)
////            .animation(.spring(), value: degrees)
//            .task {
//                while true {
//
//                    let animationDuration: Double = .random(in: 4...10)
//                    withAnimation(.easeInOut(duration: animationDuration)) {
//                        degrees += .degrees(.random(in: -360...360))
//                    }
//
//                    _ = try? await Task.sleep(nanoseconds: UInt64(animationDuration) * NSEC_PER_SEC)
//                }
//            }
 
            Color(.systemBackground)
                .opacity(0.6)
//            .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.thinMaterial)
            
            
            VStack {
                CachedAsyncImage(url: imageURL) {
                    $0.resizable()
                } placeholder: {
                    ProgressView()
                }
                .frame(square: 200)
                .foregroundColor(Color(.label))
//                .shadow(radius: 5, .quaternaryLabel)
                
                
                Text("Schedule Coming Soon!")
                    .font(.title)
    //                    .fontWeight(.heavy)
                    
            }
            .shadow()
        }
        
        

            
    }
}

import OpenFestivalModels

struct ScheduleComingSoonView_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleComingSoonView(imageURL: Event.testival.imageURL)
    }
}

