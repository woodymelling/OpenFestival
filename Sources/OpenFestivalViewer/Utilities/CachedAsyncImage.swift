//
//  File.swift
//  
//
//  Created by Woodrow Melling on 7/14/24.
//

import Foundation
import NukeUI
import SwiftUI

public typealias CachedAsyncImage = LazyImage

public extension CachedAsyncImage where Content == AnyView {
    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> some View,
        @ViewBuilder placeholder: () -> some View
    ) {
        let placeholder = placeholder()

        self.init(
            url: url,
            content: { state in
                AnyView(erasing: Group {
                    if let image = state.image {
                        content(image)
                    } else if state.error != nil {
                        Color.red // Indicates an error
                    } else {
                        placeholder
                    }
                })

            }
        )
    }
}
