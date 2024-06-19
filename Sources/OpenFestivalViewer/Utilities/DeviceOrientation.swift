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
import ComposableArchitecture

public enum DeviceOrientation {
    case portrait
    case landscape

    static func deviceOrientationPublisher() -> AnyPublisher<DeviceOrientation, Never> {
        NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
            .compactMap { ($0.object as? UIDevice)?.orientation }
            .compactMap { deviceOrientation -> DeviceOrientation? in
                if deviceOrientation.isPortrait {
                    return .portrait
                } else if deviceOrientation.isLandscape {
                    return .landscape
                } else {
                    return nil
                }
            }
            .eraseToAnyPublisher()

    }

    init(_ deviceOrientation: UIDeviceOrientation) {
        if deviceOrientation.isLandscape {
            self = .landscape
        } else {
            self = .portrait
        }
    }
}

private enum DeviceOrientationKey: DependencyKey {
    public static let liveValue = DeviceOrientation.deviceOrientationPublisher()
}

public extension DependencyValues {
    var deviceOrientationPublisher: AnyPublisher<DeviceOrientation, Never> {
        get { self[DeviceOrientationKey.self] }
        set { self[DeviceOrientationKey.self] = newValue }
    }
}
#endif


struct DeviceOrientationReaderKey: PersistenceReaderKey, Hashable {
    typealias Value = DeviceOrientation

    public let id = UUID()
    func load(initialValue: DeviceOrientation?) -> DeviceOrientation? {
        DeviceOrientation(UIDevice.current.orientation)
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
