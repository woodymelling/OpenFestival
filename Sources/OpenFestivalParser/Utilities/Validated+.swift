import Validated

extension Validated {
    init(
        run: () throws -> Value,
        mappingError: (Swift.Error) -> Error
    ) {
        do {
            self = try .valid(run())
        } catch {
            self = .error(mappingError(error))
        }
    }
}

extension Validated where Error == Swift.Error {
    init(run: () throws -> Value) {
        do {
            self = try .valid(run())
        } catch {
            self = .error(error)
        }
    }
}


extension Validated {
    func mapErrors<NewError>(_ transform: (Error) -> NewError) -> Validated<Value, NewError> {
        switch self {
        case .valid(let value): .valid(value)
        case .invalid(let errors): .invalid(errors.map(transform))
        }
    }
}

typealias AnyValidated<T> = Validated<T, Swift.Error>

extension Array {
    func sequence<Value, Error>() -> Validated<[Value], Error> where Element == Validated<Value, Error> {
        var values = [Value]()
        var errors = [Error]()

        for element in self {
            switch element {
            case .valid(let value):
                values.append(value)
            case .invalid(let errorArray):
                errors.append(contentsOf: errorArray)
            }
        }

        if errors.isEmpty {
            return .valid(values)
        } else {
            return .invalid(NonEmptyArray(errors)!)
        }
    }
}
