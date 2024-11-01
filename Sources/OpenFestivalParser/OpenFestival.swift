import Foundation
import Yams
import CustomDump
import OpenFestivalModels

import Dependencies
import DependenciesMacros
import Parsing

import FileTree



extension Conversions {
    struct DataToString: Conversion {
        func apply(_ input: Data) throws -> String {
            String(decoding: input, as: UTF8.self)
        }

        func unapply(_ output: String) throws -> Data {
            output.data(using: .utf8)!
        }
        
        typealias Input = Data
        typealias Output = String
    }
}


