//
//  File.swift
//  
//
//  Created by Woodrow Melling on 6/28/24.
//

import Foundation
import Dependencies
import DependenciesMacros
import OpenFestivalModels
import Yams
import GitClient


extension URL {
    static var organizations: URL {
        documentsDirectory.appendingPathComponent("openfestival-organizations")
    }
}

public struct OrganizationReference {
    public var url: URL
    public var info: Organization.Info
    public var events: [Event]

    public struct Event {
        public var url: URL
        public var name: String
    }
}

@DependencyClient
public struct OpenFestivalClient {
    public var fetchMyOrganizationURLs: () async throws -> [URL]
    public var fetchOrganizationsFromDisk: () async throws -> [OrganizationReference]
    public var loadOrganizationFromGithub: (URL) async throws -> Void
    public var refreshOrganizations: () async throws -> Void
}

private func getOrganizationDirectories() throws -> [URL] {
    let fileManager = FileManager.default
    let organizationsDirectory = URL.organizations

    let organizationDirectories = try fileManager.contentsOfDirectory(at: organizationsDirectory, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)

    return organizationDirectories
}

extension OpenFestivalClient: DependencyKey {
    public static var liveValue = OpenFestivalClient(
        fetchMyOrganizationURLs: {
            try getOrganizationDirectories()
        },
        fetchOrganizationsFromDisk: {
            let fileManager = FileManager.default

            var organizations: [OrganizationReference] = []

            for directory in try getOrganizationDirectories() {
                let infoFile = directory.appendingPathComponent("organization-info.yaml")

                guard fileManager.fileExists(atPath: infoFile.path) else {
                    continue
                }

                let yamlContent = try String(contentsOf: infoFile, encoding: .utf8)
                if let data = yamlContent.data(using: .utf8) {
                    let organization = try YAMLDecoder().decode(Organization.Info.self, from: data)

                    var events: [OrganizationReference.Event] = []
                    let eventDirectories = try fileManager.contentsOfDirectory(
                        at: directory,
                        includingPropertiesForKeys: nil,
                        options: .skipsHiddenFiles
                    ).filter { $0.hasDirectoryPath }
                    for directory in eventDirectories {
                        events.append(
                            .init(
                                url: directory,
                                name: directory.lastPathComponent
                            )
                        )
                    }
                    organizations.append(
                        OrganizationReference(
                            url: directory,
                            info: organization,
                            events: events
                        )
                    )
                }
            }

            return organizations
        },
        loadOrganizationFromGithub: { url in
            let fileManager = FileManager.default
            let temporaryDirectory = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString)

            print("Ensuring directory exists at path: \(temporaryDirectory.path)")

            try fileManager.ensureDirectoryExists(at: temporaryDirectory)

            print("Directory exists, starting clone operation to: \(temporaryDirectory.path)")


            @Dependency(GitClient.self) var gitClient
            try await gitClient.cloneRepository(
                from: url,
                destination: temporaryDirectory
            )

            @Dependency(OpenFestivalParser.self) var parser
            let organization = try await parser.parse(from: temporaryDirectory)


            let newDirectoryPath = URL.organizations.appendingPathComponent(organization.info.name)

            print("Moving directory from \(temporaryDirectory) to \(newDirectoryPath.absoluteString)")
            // Move the directory to the new path
            try fileManager.moveItem(at: temporaryDirectory, to: newDirectoryPath)
        },
        refreshOrganizations: {
            @Dependency(GitClient.self) var gitClient
            for orgDirectory in try getOrganizationDirectories() {
                try await gitClient.pull(at: orgDirectory)
            }
        }
    )
}

extension FileManager {
    func ensureDirectoryExists(at path: URL) throws {
        if !fileExists(atPath: path.path) {
            try createDirectory(at: path, withIntermediateDirectories: true, attributes: nil)
        }
    }
}
