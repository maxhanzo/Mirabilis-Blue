//
//  BluetoothManager+Scan.swift
//  Mirabilis Blue
//
//  Created by Max Ueda on 31/08/26.
//

import CoreBluetooth
import Foundation
import OSLog

extension BluetoothManager {

    func startScanning() {
        bluetoothQueue.async { [weak self] in
            guard let self else {
                return
            }

            guard self.centralManager.state == .poweredOn else {
                AppLogger.bluetooth.warning(
                    "Scan requested while Bluetooth is unavailable"
                )

                self.emit(
                    .error(
                        .bluetoothUnavailable(
                            self.state.availability
                        )
                    )
                )

                return
            }

            AppLogger.bluetooth.debug(
                "Starting BLE scan"
            )

            self.discoveredPeripherals.removeAll()

            self.state.activity = .scanning
            self.emit(
                .stateChanged(self.state)
            )

            self.centralManager.scanForPeripherals(
                withServices: [
                    MirabilisUUID.Service.tutorial.uuid
                ],
                options: [
                    CBCentralManagerScanOptionAllowDuplicatesKey:
                        false
                ]
            )
        }
    }

    func stopScanning() {
        bluetoothQueue.async { [weak self] in
            guard let self else {
                return
            }

            AppLogger.bluetooth.debug(
                "Stopping BLE scan"
            )

            self.centralManager.stopScan()

            if case .scanning = self.state.activity {
                self.state.activity = .idle

                self.emit(
                    .stateChanged(self.state)
                )
            }
        }
    }
}
