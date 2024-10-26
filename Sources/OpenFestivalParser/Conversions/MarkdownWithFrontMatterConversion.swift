//
//  MarkdownWithFrontMatterConversion.swift
//  OpenFestival
//
//  Created by Woodrow Melling on 10/25/24.
//

import Parsing

struct MarkdownWithFrontMatterConversion<T: Codable>: Conversion {
    typealias Input = String
    typealias Output = MarkdownWithFrontMatter<T>

    func apply(_ input: String) throws -> MarkdownWithFrontMatter<T> {
        return try MarkdownWithFrontMatter.Parser().parse(input)
    }

    func unapply(_ output: MarkdownWithFrontMatter<T>) throws -> String {
        var outputString: Substring = ""

        try MarkdownWithFrontMatter.Parser().print(output, into: &outputString)

        return String(outputString)
    }
}
