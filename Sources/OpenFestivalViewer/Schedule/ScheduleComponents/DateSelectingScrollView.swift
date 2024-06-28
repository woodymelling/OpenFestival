//
//  SwiftUIView.swift
//  
//
//  Created by Woody on 2/21/22.
//

import SwiftUI
import Combine

public struct DateSelectingScrollView<Content: View>: View {
    var content: () -> Content
    var tag: Date?

    public init(selecting tag: Date?, @ViewBuilder content: @escaping () -> Content) {
        self.content = content
        self.tag = tag
    }

    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                content()
                    .onChange(of: tag) { newDate in
                        if let newDate {
                            
                            let hour = Calendar.current.component(.hour, from: newDate)

                            withAnimation {
                                proxy.scrollTo(ScheduleHourTag(hour: hour), anchor: .center)
                            }
                        }
                    }
            }
        }
    }
}


