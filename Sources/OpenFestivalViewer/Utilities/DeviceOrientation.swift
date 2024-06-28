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

public enum DeviceOrientation {
    case portrait
    case landscape

    static func deviceOrientationPublisher() -> AnyPublisher<DeviceOrientation, Never> {
        #if canImport(UIKit)
        NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
            .compactMap { ($0.object as? UIDevice)?.orientation }
            .compactMap { deviceOrientation -> DeviceOrientation? in
                DeviceOrientation(deviceOrientation)
            }
            .eraseToAnyPublisher()

        #else
        Just(DeviceOrientation.landscape).eraseToAnyPublisher()
        #endif

    }

    #if canImport(UIKit)
    init(_ deviceOrientation: UIDeviceOrientation) {
        if deviceOrientation.isLandscape {
            self = .landscape
        } else {
            self = .portrait
        }
    }
    #endif
}

struct DeviceOrientationReaderKey: PersistenceReaderKey, Hashable {
    typealias Value = DeviceOrientation

    public let id = UUID()
    func load(initialValue: DeviceOrientation?) -> DeviceOrientation? {
        #if canImport(UIKit)
        DeviceOrientation(UIDevice.current.orientation)
        #else
        nil
        #endif
    }

    func subscribe(
        initialValue: DeviceOrientation?,
        didSet: @escaping (DeviceOrientation?) -> Void
    ) -> Shared<DeviceOrientation>.Subscription {
        let cancellable = DeviceOrientation
            .deviceOrientationPublisher()
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
}


extension PersistenceReaderKey where Self == PersistenceKeyDefault<DeviceOrientationReaderKey> {
    static var deviceOrientation: Self {
        .init(
            DeviceOrientationReaderKey(),
            .portrait
        )
    }
}
