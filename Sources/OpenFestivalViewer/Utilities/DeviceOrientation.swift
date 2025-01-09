//
//  File.swift
//
//
//  Created by Woodrow Melling on 6/15/24.
//


import Foundation
import Dependencies
import Combine
#if canImport(UIKit)
import UIKit
#endif
import ComposableArchitecture


import SwiftUI

extension InterfaceOrientation {
    init?(_ orientation: UIInterfaceOrientation) {
        switch orientation {
        case .portrait: self = .portrait
        case .landscapeLeft: self = .landscapeLeft
        case .landscapeRight: self = .landscapeRight
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .unknown: return nil
        @unknown default: return nil
        }
    }

    var isPortrait: Bool {
        switch self {
        case .landscapeLeft, .landscapeRight: return false
        case .portrait, .portraitUpsideDown: return true
        default:
            return false
        }
    }
}

struct InterfaceOrientationReaderKey: PersistenceReaderKey, Hashable {
    typealias Value = InterfaceOrientation

    public let id = UUID()
    func load(initialValue: InterfaceOrientation?) -> InterfaceOrientation? {
        #if canImport(UIKit)
        getCurrentWindowSceneOrientation()
        #else
        nil
        #endif
    }

    func subscribe(
        initialValue: InterfaceOrientation?,
        didSet: @escaping (InterfaceOrientation?) -> Void
    ) -> Shared<InterfaceOrientation>.Subscription {
        let cancellable = NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
            .compactMap { ($0.object as? UIDevice)?.orientation }
            .compactMap { InterfaceOrientation -> InterfaceOrientation? in
                getCurrentWindowSceneOrientation()
            }
            .sink(
                receiveCompletion: { _ in },
                receiveValue: {
                    didSet($0)
                }
            )

        return .init {
            cancellable.cancel()
        }
    }

    private func getCurrentWindowSceneOrientation() -> InterfaceOrientation? {
        let scenes = UIApplication.shared.connectedScenes

        guard let windowScene = scenes.first as? UIWindowScene else {
            reportIssue("Cannot determine window scene")
            return nil
        }

        if scenes.count > 1 {
            reportIssue("More than one window scene, cannot accurately determine orientation")
        }

        return InterfaceOrientation(windowScene.interfaceOrientation)
    }
}


extension PersistenceReaderKey where Self == PersistenceKeyDefault<InterfaceOrientationReaderKey> {
    static var interfaceOrientation: Self {
        .init(
            InterfaceOrientationReaderKey(),
            .portrait
        )
    }
}
