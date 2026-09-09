//
//  BluetoothConnectionController.swift
//  Mirabilis Blue
//
//  Created by Max Ueda on 04/09/26.
//

import CoreBluetooth
import Foundation
import Observation
import OSLog

@MainActor
@Observable
final class BluetoothConnectionController {

    enum State: Equatable {
        case disconnected
        case connecting
        case connected(BluetoothDevice)
    }

    private let bluetoothManager:
        BluetoothManaging

    private(set) var state:
        State = .disconnected

    private(set) var lastConnectedDevice:
        BluetoothDevice?

    private(set) var isReconnecting = false
    
    var shouldPresentReconnectAlert = false

    @ObservationIgnored
    private var intentionalDisconnectDeviceID:
        UUID?

    init(
        bluetoothManager: BluetoothManaging
    ) {
        self.bluetoothManager = bluetoothManager

        bluetoothManager.addObserver(self)

        AppLogger.bluetooth.debug(
            "BluetoothConnectionController initialized"
        )
    }

    deinit {
        bluetoothManager.removeObserver(self)
    }
}

// MARK: - Presentation

extension BluetoothConnectionController {

    var isConnected: Bool {
        if case .connected = state {
            return true
        }

        return false
    }

    var isConnecting: Bool {
        state == .connecting
    }

    var reconnectMessage: String {
        guard let device =
                lastConnectedDevice else {
            return """
            The Bluetooth connection was lost.
            """
        }

        return """
        The connection to \
        \(device.displayName) was lost. \
        Move closer to the device and try again.
        """
    }
}

// MARK: - Actions

extension BluetoothConnectionController {

    func retryConnection() {
        guard let device =
                lastConnectedDevice else {
            shouldPresentReconnectAlert = false
            return
        }

        guard !isReconnecting else {
            return
        }

        shouldPresentReconnectAlert = false
        isReconnecting = true
        state = .connecting

        AppLogger.bluetooth.info(
            "Retrying connection to \(device.displayName, privacy: .public)"
        )

        bluetoothManager.connect(
            to: device
        )
    }

    func dismissReconnectAlert() {
        shouldPresentReconnectAlert = false
    }
}

// MARK: - BluetoothObserving

extension BluetoothConnectionController:
    BluetoothObserving {

    func bluetoothManager(
        _ manager: any BluetoothManaging,
        didReceive event: BluetoothEvent
    ) {
        switch event {

        case .connected(let device):
            handleConnected(
                device
            )

        case .disconnected(let deviceID):
            handleDisconnected(
                deviceID
            )

        case .stateChanged(let bluetoothState):
            handleBluetoothStateChanged(
                bluetoothState
            )

        case .error(let error):
            handleBluetoothError(
                error
            )

        default:
            break
        }
    }
}

// MARK: - Event Handling

private extension BluetoothConnectionController {

    func handleConnected(
        _ device: BluetoothDevice
    ) {
        lastConnectedDevice = device
        intentionalDisconnectDeviceID = nil
        shouldPresentReconnectAlert = false
        isReconnecting = false
        state = .connected(device)
    }

    func handleDisconnected(
        _ deviceID: UUID
    ) {
        let wasIntentional =
            intentionalDisconnectDeviceID ==
            deviceID

        intentionalDisconnectDeviceID = nil
        state = .disconnected

        guard !wasIntentional,
              lastConnectedDevice?.id ==
                deviceID else {
            shouldPresentReconnectAlert = false
            return
        }

        shouldPresentReconnectAlert = true

        AppLogger.bluetooth.info(
            "Connection controller: unexpected disconnect"
        )
    }

    func handleBluetoothStateChanged(
        _ bluetoothState: BluetoothState
    ) {
        switch bluetoothState.activity {

        case .disconnecting(let deviceID):
            intentionalDisconnectDeviceID =
                deviceID

        case .connecting:
            state = .connecting

        case .connected:
            break

        case .idle,
             .scanning:
            break
        }
    }

    func handleBluetoothError(
        _ error: BluetoothError
    ) {
        guard isReconnecting else {
            return
        }

        switch error {

        case .connectionFailed,
             .deviceNotFound,
             .bluetoothUnavailable:

            isReconnecting = false
            state = .disconnected

            shouldPresentReconnectAlert =
                lastConnectedDevice != nil

        default:
            break
        }
    }
}
