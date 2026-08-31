//
//  FileTransferService.swift
//  Mirabilis Blue
//
//  Created by Max Ueda on 31/08/26.
//

import Foundation
import OSLog

final class FileTransferService {

    private let bluetoothManager: BluetoothManaging

    private(set) var state: FileTransferState = .idle

    init(
        bluetoothManager: BluetoothManaging
    ) {
        self.bluetoothManager = bluetoothManager

        bluetoothManager.addObserver(self)

        AppLogger.fileTransfer.debug(
            "FileTransferService initialized"
        )
    }

    deinit {
        bluetoothManager.removeObserver(self)

        AppLogger.fileTransfer.debug(
            "FileTransferService deinitialized"
        )
    }
}

// MARK: - Operations

extension FileTransferService {

    func upload(
        _ data: Data
    ) throws {
        guard data.count <=
                FileTransferProtocol.maximumFileSize else {

            AppLogger.fileTransfer.error(
                "Upload rejected: \(data.count) bytes exceeds maximum \(FileTransferProtocol.maximumFileSize) bytes"
            )

            throw FileTransferError.fileTooLarge(
                actual: data.count,
                maximum:
                    FileTransferProtocol.maximumFileSize
            )
        }

        AppLogger.fileTransfer.info(
            "Preparing upload: \(data.count) bytes"
        )

        state = .preparingUpload(
            data.count
        )

        // Upload state machine will be implemented here.
    }

    func download() {
        AppLogger.fileTransfer.info(
            "Preparing download"
        )

        state = .preparingDownload

        // Download state machine will be implemented here.
    }

    func cancel() {
        AppLogger.fileTransfer.info(
            "Cancelling file transfer"
        )

        bluetoothManager.write(
            Data([
                FileTransferProtocol
                    .Control
                    .cancel
                    .rawValue
            ]),
            to: .fileTransferRX
        )

        state = .cancelled
    }
}

// MARK: - BluetoothObserving

extension FileTransferService: BluetoothObserving {

    func bluetoothManager(
        _ manager: any BluetoothManaging,
        didReceive event: BluetoothEvent
    ) {
        switch event {

        case .valueUpdated(
            characteristic: .fileTransferTX,
            data: let data
        ):
            AppLogger.fileTransfer.debug(
                "RX ← fileTransferTX [\(data.count) bytes]"
            )

            handleIncomingTransferData(
                data
            )

        case .disconnected:
            handleDisconnect()

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

private extension FileTransferService {

    func handleIncomingTransferData(
        _ data: Data
    ) {
        AppLogger.fileTransfer.debug(
            "Processing incoming transfer packet [\(data.count) bytes]"
        )

        // ACK / NACK / chunk parsing will be
        // implemented with the transfer state machine.
    }

    func handleDisconnect() {
        guard isTransferActive else {
            return
        }

        AppLogger.fileTransfer.error(
            "File transfer aborted: Bluetooth disconnected"
        )

        state = .failed(
            .disconnected
        )
    }

    func handleBluetoothError(
        _ error: BluetoothError
    ) {
        guard isTransferActive else {
            return
        }

        AppLogger.fileTransfer.error(
            "File transfer failed due to Bluetooth error: \(error.localizedDescription, privacy: .public)"
        )

        state = .failed(
            .bluetooth(error)
        )
    }

    var isTransferActive: Bool {
        switch state {

        case .preparingUpload,
             .uploading,
             .preparingDownload,
             .downloading:
            return true

        case .idle,
             .completed,
             .cancelled,
             .failed:
            return false
        }
    }
}
