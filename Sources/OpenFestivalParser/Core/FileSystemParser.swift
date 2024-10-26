//
//  File.swift
//  
//
//  Created by Woodrow Melling on 8/18/24.
//

import Foundation
import Parsing

extension OpenFestivalParser {
    struct FileSystem: ParserPrinter {
        typealias Input = URL
        typealias Output = Data

        func parse(_ input: inout URL) throws -> Data {
            try Data(contentsOf: input)
        }

        func print(_ output: Data, into input: inout URL) throws {
            try output.write(to: input)
        }
    }
}
