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

typealias AnyValidated<T> = Validated<T, Swift.Error>