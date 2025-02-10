import Testing
@testable import OpenFestivalParser
import OpenFestivalModels
import Dependencies
import CustomDump
import Foundation

extension URL {
    static let resourcesFolder = Bundle.module.bundleURL.appending(component: "Contents/Resources/ExampleFestivals")
}


struct EventDecodingTests {

    @Test
    func testival() async throws {
        let url = URL.resourcesFolder.appending(component: "Testival").appendingPathComponent("2024")
        try await withDependencies {
            $0.calendar = .current
            $0.timeZone = .current
            $0.date = .constant(.now)
        } operation: {
            let event = try await OpenFestivalDecoder().decode(from: url)

            customDump(event)
        }
    }
}

