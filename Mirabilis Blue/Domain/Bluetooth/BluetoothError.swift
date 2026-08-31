//
//  BluetoothError.swift
//  Mirabilis Blue
//
//  Created by Max Ueda on 31/08/26.
//

import Foundation

enum BluetoothError: Error, Equatable {

    case bluetoothUnavailable(
        BluetoothState.Availability
    )

    case deviceNotFound(UUID)

    case serviceNotFound(
        MirabilisUUID.Service
    )

    case characteristicNotFound(
        MirabilisUUID.Characteristic
    )

    case connectionFailed(
        deviceID: UUID,
        reason: String?
    )

    case disconnected(
        deviceID: UUID,
        reason: String?
    )

    case serviceDiscoveryFailed(String)

    case characteristicDiscoveryFailed(String)

    case readFailed(
        MirabilisUUID.Characteristic,
        reason: String
    )

    case writeFailed(
        MirabilisUUID.Characteristic,
        reason: String
    )

    case notificationFailed(
        MirabilisUUID.Characteristic,
        reason: String
    )

    case unsupportedOperation(
        MirabilisUUID.Characteristic
    )

    case securityRequired

    case securityStateMismatch
}
