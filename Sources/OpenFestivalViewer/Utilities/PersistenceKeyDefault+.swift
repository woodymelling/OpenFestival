//
//  File.swift
//  
//
//  Created by Woodrow Melling on 6/14/24.
//

import Foundation
import ComposableArchitecture

extension PersistenceKeyDefault {
    public init(
        _ key: Base,
        _ value: Base.Value,
        testValue: Base.Value? = nil,
        previewValue: Base.Value? = nil
    ) {
        @Dependency(\.context) var context
        let defaultValue = switch context {
        case .live: value
        case .test: testValue
        case .preview: previewValue
        }

        self.init(key, defaultValue ?? value)
    }
}
