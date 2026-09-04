//
//  AppCoordinator.swift
//  Mirabilis Blue
//
//  Created by Max Ueda on 31/08/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class AppCoordinator {

    // MARK: - Route

    enum Route: Hashable {
        case device(BluetoothDevice)
        case fileTransfer(BluetoothDevice)
    }

    // MARK: - Dependencies

    private let bluetoothManager: BluetoothManaging

    // MARK: - Navigation

    var path: [Route] = []

    // MARK: - ViewModels

    let scannerViewModel: ScannerViewModel

    // MARK: - Init

    init(
        bluetoothManager: BluetoothManaging
    ) {
        self.bluetoothManager = bluetoothManager

        self.scannerViewModel = ScannerViewModel(
            bluetoothManager: bluetoothManager
        )

        self.scannerViewModel.onConnected = { [weak self] device in
            self?.showDevice(
                device
            )
        }
    }
}

// MARK: - Navigation

extension AppCoordinator {

    func showDevice(
        _ device: BluetoothDevice
    ) {
        path.append(
            .device(device)
        )
    }
    
    func showFileTransfer(
        for device: BluetoothDevice
    ) {
        path.append(
            .fileTransfer(device)
        )
    }

    func popToScanner() {
        path.removeAll()
    }
}

// MARK: - ViewModels
extension AppCoordinator {

    func makeDeviceViewModel(
        device: BluetoothDevice
    ) -> DeviceViewModel {
        DeviceViewModel(
            device: device,
            bluetoothManager: bluetoothManager
        )
    }

    func makeFileTransferViewModel(
        device: BluetoothDevice
    ) -> FileTransferViewModel {
        FileTransferViewModel(
            device: device,
            bluetoothManager: bluetoothManager
        )
    }
}
