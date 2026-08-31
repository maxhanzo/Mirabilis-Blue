//
//  DeviceViewModel.swift
//  Mirabilis Blue
//
//  Created by Max Ueda on 31/08/26.
//

import Foundation
import Observation
import OSLog
import CoreBluetooth

@MainActor
@Observable
final class DeviceViewModel {

    // MARK: - State

    enum State: Equatable {
        case loading
        case ready
        case disconnected
        case failed(String)
    }

    // MARK: - Dependencies

    private let bluetoothManager: BluetoothManaging

    // MARK: - Device

    let device: BluetoothDevice

    // MARK: - Presentation State

    private(set) var state: State = .loading

    private(set) var serialNumber: String?
    private(set) var hardwareRevision: String?
    private(set) var firmwareRevision: String?

    private(set) var characteristics: [
        MirabilisUUID.Characteristic
    ] = []

    // MARK: - Init

    init(
        device: BluetoothDevice,
        bluetoothManager: BluetoothManaging
    ) {
        self.device = device
        self.bluetoothManager = bluetoothManager

        bluetoothManager.addObserver(self)

        AppLogger.ui.debug(
            "DeviceViewModel initialized for \(device.displayName, privacy: .public)"
        )
    }
}

// MARK: - Presentation

extension DeviceViewModel {

    var deviceInformationCharacteristics: [
        MirabilisUUID.Characteristic
    ] {
        characteristics.filter {
            $0.service == .deviceInformation
        }
    }

    var tutorialCharacteristics: [
        MirabilisUUID.Characteristic
    ] {
        characteristics.filter {
            $0.service == .tutorial
        }
    }

    var isLoading: Bool {
        state == .loading
    }
}

// MARK: - Lifecycle

extension DeviceViewModel {

    func tearDown() {
        bluetoothManager.removeObserver(self)

        AppLogger.ui.debug(
            "DeviceViewModel torn down"
        )
    }
}

// MARK: - Bluetooth Events

extension DeviceViewModel: BluetoothObserving {

    func bluetoothManager(
        _ manager: any BluetoothManaging,
        didReceive event: BluetoothEvent
    ) {
        switch event {

        case .characteristicsDiscovered(
            let characteristics
        ):
            handleDiscoveredCharacteristics(
                characteristics
            )

        case .valueUpdated(
            characteristic: let characteristic,
            data: let data
        ):
            handleUpdatedValue(
                data,
                for: characteristic
            )

        case .disconnected(
            deviceID: let deviceID
        ):
            handleDisconnectedDevice(
                deviceID
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

// MARK: - Characteristic Discovery

private extension DeviceViewModel {

    func handleDiscoveredCharacteristics(
        _ discoveredCharacteristics:
            Set<MirabilisUUID.Characteristic>
    ) {
        characteristics = discoveredCharacteristics
            .sorted {
                $0.uuid.uuidString <
                    $1.uuid.uuidString
            }

        AppLogger.ui.debug(
            "Device characteristics discovered: \(discoveredCharacteristics.count)"
        )

        readDeviceInformation()

        state = .ready
    }

    func readDeviceInformation() {
        readIfAvailable(
            .serialNumber
        )

        readIfAvailable(
            .hardwareRevision
        )

        readIfAvailable(
            .firmwareRevision
        )
    }

    func readIfAvailable(
        _ characteristic:
            MirabilisUUID.Characteristic
    ) {
        guard characteristics.contains(
            characteristic
        ) else {
            return
        }

        bluetoothManager.read(
            characteristic
        )
    }
}

// MARK: - Value Updates

private extension DeviceViewModel {

    func handleUpdatedValue(
        _ data: Data,
        for characteristic:
            MirabilisUUID.Characteristic
    ) {
        switch characteristic {

        case .serialNumber:
            serialNumber = decodeString(
                from: data
            )

        case .hardwareRevision:
            hardwareRevision = decodeString(
                from: data
            )

        case .firmwareRevision:
            firmwareRevision = decodeString(
                from: data
            )

        default:
            break
        }
    }

    func decodeString(
        from data: Data
    ) -> String? {
        String(
            data: data,
            encoding: .utf8
        )?
        .trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }
}

// MARK: - Connection Handling

private extension DeviceViewModel {

    func handleDisconnectedDevice(
        _ deviceID: UUID
    ) {
        guard deviceID == device.id else {
            return
        }

        state = .disconnected

        AppLogger.ui.info(
            "Device disconnected while DeviceView is active"
        )
    }

    func handleBluetoothError(
        _ error: BluetoothError
    ) {
        AppLogger.ui.error(
            "Device flow error: \(error.localizedDescription, privacy: .public)"
        )

        state = .failed(
            error.localizedDescription
        )
    }
}
