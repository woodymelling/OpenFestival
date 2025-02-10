
//  File.swift
//  
//
//  Created by Woodrow Melling on 6/14/24.
//

import Foundation
import ComposableArchitecture
import Sharing

extension _SharedKeyDefault {

    public static subscript(
      _ key: Base,
      default value: @autoclosure @escaping @Sendable () -> Base.Value,
      previewValue: @autoclosure @escaping @Sendable () -> Base.Value,
      testValue: @autoclosure @escaping @Sendable () -> Base.Value? = nil
    ) -> Self {
        @Dependency(\.context) var context
        let defaultValue = switch context {
        case .live: value
        case .test: testValue
        case .preview: previewValue
        }

        return Self[key, default: defaultValue() ?? value()]
    }
}
