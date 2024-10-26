//
//  File.swift
//  
//
//  Created by Woodrow Melling on 8/18/24.
//

import Foundation
import Yams
import Parsing

extension Parsers {
    struct Yaml<T: Decodable>: Parsing.Parser {
        typealias Input = Substring
        typealias Output = T

        func parse(_ input: inout Substring) throws -> T {
            let result = try YAMLDecoder().decode(T.self, from: String(input))
            input = ""
            return result
        }
    }
}

extension Parsers.Yaml: ParserPrinter where T: Encodable {
    func print(_ output: T, into input: inout Substring) throws {
        try input.append(contentsOf: YAMLEncoder().encode(output))
    }
}
