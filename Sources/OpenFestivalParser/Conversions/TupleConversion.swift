//
//  TupleConversion.swift
//  OpenFestival
//
//  Created by Woodrow Melling on 10/25/24.
//

import Parsing

extension Conversions {
    struct Tuple<each C: Conversion>: Conversion {
        typealias Input = (repeat (each C).Input)
        typealias Output = (repeat (each C).Output)

        let conversions: (repeat each C)

        init(_ conversions: repeat each C) {
            self.conversions = (repeat each conversions)
        }

        func apply(_ inputs: Input) throws -> Output {
            func apply<T: Conversion>(conversion: T, to input: T.Input) throws -> T.Output {
                try conversion.apply(input)
            }

            return (repeat try apply(conversion: each conversions, to: each inputs))
        }

        func unapply(_ output: (repeat (each C).Output)) throws -> (repeat (each C).Input) {
            func unapply<T: Conversion>(conversion: T, to output: T.Output) throws -> T.Input {
                try conversion.unapply(output)
            }

            return (repeat try unapply(conversion: each conversions, to: each output))
        }

    }
}


