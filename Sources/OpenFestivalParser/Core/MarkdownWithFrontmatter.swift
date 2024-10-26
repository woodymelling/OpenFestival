//
//  File.swift
//  
//
//  Created by Woodrow Melling on 8/18/24.
//

import Foundation
import Parsing

struct MarkdownWithFrontMatter<FrontMatter> {
    let frontMatter: FrontMatter?
    let body: String

    struct Parser {}
}

extension MarkdownWithFrontMatter: Equatable where FrontMatter: Equatable {}

extension MarkdownWithFrontMatter.Parser: Parser, ParserPrinter where FrontMatter: Codable {
    typealias Input = Substring
    typealias Output = MarkdownWithFrontMatter

    var body: some ParserPrinter<Input, Output> {
        ParsePrint(.memberwise(MarkdownWithFrontMatter.init(frontMatter:body:))) {
            Optionally {
                Parsers.FrontMatter<FrontMatter>()
                Whitespace(1, .vertical)
            }

            Rest().map(.string)
        }
    }
}

extension Parsers {
    struct FrontMatter<FrontMatter: Codable>: ParserPrinter {
        typealias Input = Substring

        // We need to be careful here, because we want to parse everything between the delimiters as Yaml.
        // This is subtly different than parsing delimiter, yaml, delimiter.
        var body: some ParserPrinter<Input, FrontMatter> {
            "---"
            Whitespace(1, .vertical)
            PrefixUpTo("---").pipe {
                Yaml<FrontMatter>()
            }
            "---"
        }
    }
}


