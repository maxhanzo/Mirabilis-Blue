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

    func popToScanner() {
        path.removeAll()
    }
}

// MARK: - ViewModels

extension AppCoordinator {

    func makeDeviceViewModel(
        device: BluetoothDevice
    ) -> DeviceViewModel {

        let viewModel = DeviceViewModel(
            device: device,
            bluetoothManager: bluetoothManager
        )

        viewModel.onDisconnected = { [weak self] in
            self?.popToScanner()
        }

        return viewModel
    }
}
