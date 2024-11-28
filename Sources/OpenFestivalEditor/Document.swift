//
//  Document.swift
//  OpenFestival
//
//  Created by Woodrow Melling on 11/27/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct OpenFestivalFileDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.directory]

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        
    }
    
    init(configuration: ReadConfiguration) throws {

    }


}
