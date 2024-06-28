//
//  File.swift
//  
//
//  Created by Woodrow Melling on 6/27/24.
//

import Foundation
import Clibgit2
import Dependencies
import DependenciesMacros

@DependencyClient
public struct GitClient {
    public var cloneRepository: (_ from: URL, _ destination: URL) async throws -> Void
}

extension GitClient: DependencyKey {
    public static var liveValue = GitClient(
        cloneRepository: { url, destinationPath in

            return try await withCheckedThrowingContinuation { continuation in
                git_libgit2_init()

                var repo: OpaquePointer?

                guard let urlCString = url.absoluteString.cString(using: .utf8),
                      let destinationCString = destinationPath.absoluteString.cString(using: .utf8) else {
                    continuation.resume(throwing: NSError(domain: "Invalid URL or destination path", code: -1, userInfo: nil))
                    return
                }

                let cloneOptions = UnsafeMutablePointer<git_clone_options>.allocate(capacity: 1)
                git_clone_init_options(cloneOptions, UInt32(GIT_CLONE_OPTIONS_VERSION))

                let result = git_clone(&repo, urlCString, destinationCString, cloneOptions)

                if result == 0 {
                    continuation.resume(returning: ())
                } else {
                    let errorMessage = git_error_last()?.pointee.message.map { String(cString: $0) } ?? "Unknown error"
                    let error = NSError(domain: "libgit2", code: Int(result), userInfo: [NSLocalizedDescriptionKey: errorMessage])
                    continuation.resume(throwing: error)
                }

                git_repository_free(repo)
                git_libgit2_shutdown()
            }

        }
    )
}
