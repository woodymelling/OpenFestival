//
//  File.swift
//  
//
//  Created by Woodrow Melling on 6/14/24.
//

import Foundation
import OpenFestivalModels
import ComposableArchitecture

public typealias FavoriteArtists = Set<Event.Artist.ID>

public extension FavoriteArtists {
    func contains(_ performance: Event.Performance) -> Bool {
        performance.artistIDs.contains(where: { self.contains($0) })
    }

    subscript(_ artist: Event.Artist.ID) -> Bool {
        get { self.contains(artist) }
        set { 
            self.remove(artist)
            if newValue {
                self.insert(artist)
            }
        }
    }
}

public extension Set {
    mutating func toggle(_ value: Element) {
        if self.contains(value) {
            self.remove(value)
        } else {
            self.insert(value)
        }
    }
}

public extension PersistenceKey where Self == PersistenceKeyDefault<FileStorageKey<FavoriteArtists>> {
    static var favoriteArtists: Self {
        .init(.fileStorage(.libraryDirectory.appending(path: "userFavorites.json")), [])
    }
}
