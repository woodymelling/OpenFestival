import ArgumentParser
import OpenFestivalParser
import Dependencies
import GitClient
import Foundation

@main
struct OpenFestival: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "openfestival",
        abstract: "A Swift command-line tool to parse OpenFestival data",
        subcommands: [Validate.self, Download.self]
    )

    struct Validate: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "validate",
            abstract: "Parse OpenFestival data from a YAML file"
        )

        @Argument(help: "The path to the openFestival directory to parse")
        var path: String

        func run() async throws {
            @Dependency(OpenFestivalParser.self) var parser
            let _ = try await parser.parse(from: path)
            print("Parsed successfully! This data can be used in the OpenFestival app 🎉")
        }
    }

    struct Download: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "download",
            abstract: "download OpenFestival data from a github repository"
        )

        @Argument(help: "The path to the openFestival directory to parse")
        var path: String

        @Argument
        var destination: String

        func run() async throws {
            @Dependency(GitClient.self)
            var gitClient

            try await gitClient.cloneRepository(
                from: URL(string: path)!,
                destination: URL(string: destination)!
            )
        }

    }
}
