//
//  File.swift
//  
//
//  Created by Woodrow Melling on 6/14/24.
//

import Foundation
import SwiftUI

extension View {
    func frame(square sideLength: CGFloat) -> some View {
        self.frame(width: sideLength, height: sideLength, alignment: .center)
    }
}

extension CGSize {
    init(square edgeSize: CGFloat) {
        self.init(width: edgeSize, height: edgeSize)
    }
}
