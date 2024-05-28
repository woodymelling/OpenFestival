import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
struct FileManagerClient {
    var contentsOfDirectory: (_ in: URL) throws -> [URL]
    var contents: (_ of: URL) throws -> Data
}

extension FileManagerClient: DependencyKey {
    public static var liveValue = FileManagerClient(
        contentsOfDirectory: { try FileManager.default.contentsOfDirectory(at: $0, includingPropertiesForKeys: nil) },
        contents: { try Data(contentsOf: $0) }
    )
}

extension DependencyValues {
    var fileManager: FileManagerClient {
        get { self[FileManagerClient.self] }
        set { self[FileManagerClient.self] = newValue }
    }
}