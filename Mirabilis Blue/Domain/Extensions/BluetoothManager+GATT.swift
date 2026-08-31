//
//  BluetoothManager+GATT.swift
//  Mirabilis Blue
//
//  Created by Max Ueda on 31/08/26.
//

import CoreBluetooth
import Foundation
import OSLog

extension BluetoothManager {

    func read(
        _ characteristic: MirabilisUUID.Characteristic
    ) {
        bluetoothQueue.async { [weak self] in
            guard let self else {
                return
            }

            guard characteristic.supportsRead else {
                AppLogger.bluetooth.warning(
                    "READ requested for unsupported characteristic \(String(describing: characteristic), privacy: .public)"
                )

                self.emit(
                    .error(
                        .unsupportedOperation(characteristic)
                    )
                )

                return
            }

            guard
                let cbCharacteristic =
                    self.discoveredCharacteristics[characteristic],
                let peripheral = self.connectedPeripheral
            else {
                AppLogger.bluetooth.error(
                    "READ failed to start: characteristic \(String(describing: characteristic), privacy: .public) is unavailable"
                )

                self.emit(
                    .error(
                        .characteristicNotFound(characteristic)
                    )
                )

                return
            }

            AppLogger.bluetooth.debug(
                "READ → \(String(describing: characteristic), privacy: .public)"
            )

            peripheral.readValue(
                for: cbCharacteristic
            )
        }
    }

    func write(
        _ data: Data,
        to characteristic: MirabilisUUID.Characteristic
    ) {
        bluetoothQueue.async { [weak self] in
            guard let self else {
                return
            }

            guard let writeType =
                    characteristic.writeType else {

                AppLogger.bluetooth.warning(
                    "WRITE requested for unsupported characteristic \(String(describing: characteristic), privacy: .public)"
                )

                self.emit(
                    .error(
                        .unsupportedOperation(characteristic)
                    )
                )

                return
            }

            guard
                let cbCharacteristic =
                    self.discoveredCharacteristics[characteristic],
                let peripheral = self.connectedPeripheral
            else {
                AppLogger.bluetooth.error(
                    "WRITE failed to start: characteristic \(String(describing: characteristic), privacy: .public) is unavailable"
                )

                self.emit(
                    .error(
                        .characteristicNotFound(characteristic)
                    )
                )

                return
            }

            AppLogger.bluetooth.debug(
                "WRITE → \(String(describing: characteristic), privacy: .public) [\(data.count) bytes] type=\(String(describing: writeType), privacy: .public)"
            )

            peripheral.writeValue(
                data,
                for: cbCharacteristic,
                type: writeType
            )
        }
    }

    func setNotifications(
        _ enabled: Bool,
        for characteristic: MirabilisUUID.Characteristic
    ) {
        bluetoothQueue.async { [weak self] in
            guard let self else {
                return
            }

            guard characteristic.supportsNotifications else {
                AppLogger.bluetooth.warning(
                    "NOTIFY requested for unsupported characteristic \(String(describing: characteristic), privacy: .public)"
                )

                self.emit(
                    .error(
                        .unsupportedOperation(characteristic)
                    )
                )

                return
            }

            guard
                let cbCharacteristic =
                    self.discoveredCharacteristics[characteristic],
                let peripheral = self.connectedPeripheral
            else {
                AppLogger.bluetooth.error(
                    "NOTIFY failed to start: characteristic \(String(describing: characteristic), privacy: .public) is unavailable"
                )

                self.emit(
                    .error(
                        .characteristicNotFound(characteristic)
                    )
                )

                return
            }

            AppLogger.bluetooth.debug(
                "NOTIFY \(enabled ? "ON" : "OFF", privacy: .public) → \(String(describing: characteristic), privacy: .public)"
            )

            peripheral.setNotifyValue(
                enabled,
                for: cbCharacteristic
            )
        }
    }
}
