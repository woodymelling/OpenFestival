//
//  File.swift
//  
//
//  Created by Woodrow Melling on 6/27/24.
//

import Foundation
import Dependencies
import DependenciesMacros
import AsyncSwiftGit


@DependencyClient
public struct GitClient {
    public var cloneRepository: (_ from: URL, _ destination: URL) async throws -> Void
    public var pull: (_ at: URL) async throws -> Void
}

extension GitClient: DependencyKey {
    public static var liveValue = GitClient(
        cloneRepository: { url, destinationPath in
            let repository = try await Repository.clone(from: url, to: destinationPath)
        },
        pull: { path in
            let repository = try Repository(openAt: path)
            for try await progress in repository.fetchProgress(remote: "origin") {
                continue
            }
            let result = try repository.merge(revisionSpecification: "origin/main", signature: .init(name: "", email: ""))
        }
    )
}

