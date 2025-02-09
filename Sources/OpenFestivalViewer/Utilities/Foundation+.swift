//
//  File.swift
//  
//
//  Created by Woodrow Melling on 6/14/24.
//

import Foundation

extension Collection {
    public func sorted(by keyPath: KeyPath<Element, some Comparable>) -> [Element] {
        self.sorted { $0[keyPath: keyPath] < $1[keyPath: keyPath] }
    }
    var hasElements: Bool {
        !self.isEmpty
    }
}

