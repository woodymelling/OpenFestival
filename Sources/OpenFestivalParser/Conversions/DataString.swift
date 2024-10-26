//
//  DataString.swift
//  OpenFestival
//
//  Created by Woodrow Melling on 10/25/24.
//

import Foundation
import Parsing

struct DataStringConversion: Conversion {
    typealias Input = Data
    typealias Output = String

    func apply(_ input: Data) throws -> String {
        String(decoding: input, as: UTF8.self)
    }

    func unapply(_ output: String) throws -> Data {
        Data(output.utf8)
    }
}
