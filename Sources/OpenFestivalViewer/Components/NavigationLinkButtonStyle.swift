//
//  File.swift
//  
//
//  Created by Woodrow Melling on 6/15/24.
//

import Foundation
import SwiftUI

struct NavigationArrow: View {

    init() {}

    @ScaledMetric var height = 12
    var body: some View {
        Image(systemName: "chevron.forward")
            .resizable()
            .foregroundStyle(.tertiary)
            .aspectRatio(contentMode: .fit)
            .fontWeight(.bold)
            .frame(height: self.height)
    }
}

struct NavigationLinkButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            NavigationArrow()
        }
    }
}

extension ButtonStyle where Self == NavigationLinkButtonStyle {
    static var navigationLink: Self {
        NavigationLinkButtonStyle()
    }
}
