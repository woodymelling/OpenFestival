//
//  File.swift
//  
//
//  Created by Woodrow Melling on 6/13/24.
//


import Foundation
import Yams

struct MarkdownWithFrontMatter<FrontMatter: Decodable>: Decodable {
    let frontMatter: FrontMatter?
    let body: String
}

extension MarkdownWithFrontMatter: Equatable where FrontMatter: Equatable {}

struct MarkdownWithFrontmatterDecoder {
    func decode<T: Decodable>(
        _ type: T.Type = T.self,
        from markdown: String
    ) throws -> MarkdownWithFrontMatter<T> {
        let (frontMatter, body) = try MarkdownWithFrontmatterDecoder.splitFrontMatterAndBody(from: markdown)

        let frontMatterDecoded: T?
        if let frontMatter = frontMatter {
            let yamlDecoder = YAMLDecoder()
            frontMatterDecoded = try yamlDecoder.decode(T.self, from: frontMatter)
        } else {
            frontMatterDecoded = nil
        }

        return MarkdownWithFrontMatter(frontMatter: frontMatterDecoded, body: body)
    }

    private static func splitFrontMatterAndBody(from markdown: String) throws -> (String?, String) {
        let pattern = #"(?s)^---\s*\n(.*?)\n---\s*\n(.*)$"#
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        let nsString = markdown as NSString
        let range = NSRange(location: 0, length: nsString.length)

        if let match = regex.firstMatch(in: markdown, options: [], range: range) {
            let frontMatterRange = match.range(at: 1)
            let bodyRange = match.range(at: 2)

            let frontMatter = nsString.substring(with: frontMatterRange)
            let body = nsString.substring(with: bodyRange).trimmingCharacters(in: .whitespacesAndNewlines)

            return (frontMatter, body)
        } else {
            let body = markdown.trimmingCharacters(in: .whitespacesAndNewlines)
            return (nil, body)
        }
    }
}
