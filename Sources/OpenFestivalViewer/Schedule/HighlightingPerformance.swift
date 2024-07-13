//
//  File.swift
//  
//
//  Created by Woodrow Melling on 7/3/24.
//

import Foundation
import ComposableArchitecture
import OpenFestivalModels

extension PersistenceKey where Self == InMemoryKey<Event.Performance.ID?> {
    static var highlightedPerformance: Self {
        .inMemory("highlightingPerformance")
    }
}
