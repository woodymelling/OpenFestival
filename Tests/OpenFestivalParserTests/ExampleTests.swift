import XCTest
@testable import OpenFestivalParser
import OpenFestivalModels
import Dependencies
import CustomDump

final class FullDecodingTest: XCTestCase {

    func getResourceDirectory(organization: String, event: String) -> URL? {
        // Use the Bundle to get the URL for the directory
        let testBundle = Bundle.module
        return testBundle.url(
            forResource: "\(organization)/\(event)",
            withExtension: nil,
            subdirectory: "ExampleFestivals"
        )
    }

    func testPreview() async throws {
        let preview = Event.testival
    }

    func testExampleFestival() async throws {
        // Get the URL for the example festival directory
        guard let festivalDirectory = getResourceDirectory(organization: "Testival", event: "2024") else {
            XCTFail("Festival directory not found")
            return
        }

        try await withDependencies {
            $0.fileManager = .liveValue
            $0.calendar = .current
            $0.timeZone = .current
        } operation: {
            let event = try await OpenFestivalParser.liveValue.parse(from: festivalDirectory)

            customDump(event)
        }
    }
}

