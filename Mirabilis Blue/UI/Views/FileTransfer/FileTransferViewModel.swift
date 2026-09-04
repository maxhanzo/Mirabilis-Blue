//
//  FileTransferViewModel.swift
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
final class FileTransferViewModel {

    // MARK: - Dependencies

    private let bluetoothManager:
        BluetoothManaging

    private let fileTransferService:
        FileTransferService

    private let connectionController:
        BluetoothConnectionController

    // MARK: - Device

    let device: BluetoothDevice

    // MARK: - Statistics

    private(set) var totalUploadedBytes:
        UInt64?

    private(set) var
        isReadingTotalUploadedBytes = false

    // MARK: - File Selection

    private(set) var selectedFile:
        SelectedFile?

    // MARK: - Download Export

    private(set) var downloadedData:
        Data?

    var isFileExporterPresented = false

    let defaultDownloadFilename =
        "mirabilis_download.bin"

    // MARK: - Transfer

    private(set) var transferState:
        FileTransferState = .idle

    private(set) var errorMessage:
        String?

    @ObservationIgnored
    private var hasLoaded = false

    init(
        device: BluetoothDevice,
        bluetoothManager:
            BluetoothManaging,
        connectionController:
            BluetoothConnectionController
    ) {
        self.device = device

        self.bluetoothManager =
            bluetoothManager

        self.connectionController =
            connectionController

        let fileTransferService =
            FileTransferService(
                bluetoothManager:
                    bluetoothManager
            )

        self.fileTransferService =
            fileTransferService

        bluetoothManager.addObserver(
            self
        )

        fileTransferService.addObserver(
            self
        )

        AppLogger.ui.debug(
            "FileTransferViewModel initialized for \(device.displayName, privacy: .public)"
        )
    }
}

// MARK: - Connection

extension FileTransferViewModel {

    var isConnected: Bool {
        connectionController
            .isConnected
    }
}

// MARK: - Presentation

extension FileTransferViewModel {

    var totalUploadedBytesText:
        String {
        guard let totalUploadedBytes else {
            return "Not read"
        }

        return """
        \(totalUploadedBytes.formatted()) bytes
        """
    }

    var hasSelectedFile: Bool {
        selectedFile != nil
    }

    var canChooseFile: Bool {
        isConnected &&
        !transferState.isTransferring
    }

    var canReadStatistics: Bool {
        isConnected &&
        !isReadingTotalUploadedBytes &&
        !transferState.isTransferring
    }

    var canUpload: Bool {
        isConnected &&
        selectedFile != nil &&
        !transferState.isTransferring
    }

    var canDownload: Bool {
        isConnected &&
        !transferState.isTransferring
    }

    var canCancel: Bool {
        isConnected &&
        transferState.isTransferring
    }

    var uploadProgress: Double? {
        guard case let .uploading(
            bytesTransferred,
            totalBytes
        ) = transferState,
        totalBytes > 0 else {
            return nil
        }

        return Double(bytesTransferred) /
            Double(totalBytes)
    }

    var uploadProgressText: String? {
        guard case let .uploading(
            bytesTransferred,
            totalBytes
        ) = transferState else {
            return nil
        }

        return """
        \(bytesTransferred.formatted()) / \
        \(totalBytes.formatted()) bytes
        """
    }

    var transferStatusText: String? {
        switch transferState {

        case .idle:
            if !isConnected {
                return "Bluetooth disconnected"
            }

            return nil

        case .preparingUpload:
            return "Preparing upload…"

        case .uploading:
            return uploadProgressText

        case .preparingDownload:
            return "Preparing download…"

        case .downloading(
            let bytesTransferred
        ):
            return """
            \(bytesTransferred.formatted()) \
            bytes downloaded
            """

        case .completed(
            .upload(
                let bytesTransferred
            )
        ):
            return """
            Upload completed — \
            \(bytesTransferred.formatted()) bytes
            """

        case .completed(
            .download(
                let bytesTransferred
            )
        ):
            return """
            Download completed — \
            \(bytesTransferred.formatted()) bytes
            """

        case .cancelled:
            return "Transfer cancelled"

        case .failed(let error):
            return error.localizedDescription
        }
    }

    var downloadedDocument:
        DownloadedFileDocument? {
        guard let downloadedData else {
            return nil
        }

        return DownloadedFileDocument(
            data: downloadedData
        )
    }
}

// MARK: - Lifecycle / Statistics

extension FileTransferViewModel {

    func load() {
        guard !hasLoaded else {
            return
        }

        hasLoaded = true

        guard isConnected else {
            return
        }

        readTotalUploadedBytes()
    }

    func readTotalUploadedBytes() {
        guard isConnected else {
            handleNotConnected()
            return
        }

        guard !isReadingTotalUploadedBytes else {
            return
        }

        errorMessage = nil
        isReadingTotalUploadedBytes = true

        bluetoothManager.read(
            .totalUploadedBytes
        )
    }
}

// MARK: - File Selection

extension FileTransferViewModel {

    func selectFile(
        at url: URL
    ) {
        errorMessage = nil

        let didStartAccessing =
            url.startAccessingSecurityScopedResource()

        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let resourceValues =
                try url.resourceValues(
                    forKeys: [
                        .fileSizeKey,
                        .isRegularFileKey
                    ]
                )

            guard resourceValues
                .isRegularFile == true else {
                throw FileSelectionError
                    .notARegularFile
            }

            if let fileSize =
                resourceValues.fileSize {

                guard fileSize > 0 else {
                    throw FileSelectionError
                        .emptyFile
                }

                guard fileSize <=
                        FileTransferProtocol
                            .maximumFileSize else {
                    throw FileSelectionError
                        .fileTooLarge
                }
            }

            let data = try Data(
                contentsOf: url
            )

            guard !data.isEmpty else {
                throw FileSelectionError
                    .emptyFile
            }

            guard data.count <=
                    FileTransferProtocol
                        .maximumFileSize else {
                throw FileSelectionError
                    .fileTooLarge
            }

            selectedFile =
                SelectedFile(
                    name:
                        url.lastPathComponent,
                    data: data
                )

            AppLogger.ui.info(
                "Selected file: \(url.lastPathComponent, privacy: .public), \(data.count) bytes"
            )

        } catch let error
            as FileSelectionError {

            selectedFile = nil
            errorMessage =
                error.localizedDescription

        } catch {
            selectedFile = nil
            errorMessage =
                "Unable to read the selected file."

            AppLogger.ui.error(
                "Unable to read selected file: \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    func handleFileImporterError(
        _ error: Error
    ) {
        errorMessage =
            error.localizedDescription
    }

    func handleFileExporterResult(
        _ result: Result<URL, Error>
    ) {
        switch result {

        case .success(let url):
            AppLogger.ui.info(
                "Downloaded file exported to \(url.lastPathComponent, privacy: .public)"
            )

        case .failure(let error):
            errorMessage =
                error.localizedDescription
        }
    }
}

// MARK: - Transfer Actions

extension FileTransferViewModel {

    func uploadSelectedFile() {
        guard isConnected else {
            handleNotConnected()
            return
        }

        guard let selectedFile else {
            return
        }

        errorMessage = nil
        downloadedData = nil

        do {
            try fileTransferService.upload(
                selectedFile.data
            )

        } catch let error
            as FileTransferError {

            transferState =
                .failed(error)

            errorMessage =
                error.localizedDescription

        } catch {
            errorMessage =
                error.localizedDescription
        }
    }

    func downloadFile() {
        guard isConnected else {
            handleNotConnected()
            return
        }

        errorMessage = nil
        downloadedData = nil

        do {
            try fileTransferService
                .download()

        } catch let error
            as FileTransferError {

            transferState =
                .failed(error)

            errorMessage =
                error.localizedDescription

        } catch {
            errorMessage =
                error.localizedDescription
        }
    }

    func cancelTransfer() {
        guard isConnected else {
            handleNotConnected()
            return
        }

        fileTransferService.cancel()
    }
}

// MARK: - FileTransferServiceObserving

extension FileTransferViewModel:
    FileTransferServiceObserving {

    func fileTransferService(
        _ service: FileTransferService,
        didChangeState state:
            FileTransferState
    ) {
        transferState = state

        switch state {

        case .completed(.upload):
            if isConnected {
                readTotalUploadedBytes()
            }

        case .completed(.download):
            downloadedData =
                service.downloadedData

            if downloadedData != nil {
                isFileExporterPresented =
                    true
            }

        case .failed(let error):
            errorMessage =
                error.localizedDescription

        default:
            break
        }
    }
}

// MARK: - BluetoothObserving

extension FileTransferViewModel:
    BluetoothObserving {

    func bluetoothManager(
        _ manager: any BluetoothManaging,
        didReceive event:
            BluetoothEvent
    ) {
        switch event {

        case .connected(let connectedDevice):
            guard connectedDevice.id ==
                    device.id else {
                return
            }

            errorMessage = nil

            if hasLoaded {
                readTotalUploadedBytes()
            }

        case .disconnected(
            deviceID: let deviceID
        ):
            guard deviceID ==
                    device.id else {
                return
            }

            isReadingTotalUploadedBytes =
                false

            if !transferState
                .isTransferring {
                errorMessage = nil
            }

        case .valueUpdated(
            characteristic:
                .totalUploadedBytes,
            data: let data
        ):
            handleTotalUploadedBytes(
                data
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

// MARK: - Bluetooth Errors

private extension FileTransferViewModel {

    func handleBluetoothError(
        _ error: BluetoothError
    ) {
        let wasReadingTotalUploadedBytes =
            isReadingTotalUploadedBytes

        if wasReadingTotalUploadedBytes {
            isReadingTotalUploadedBytes =
                false
        }

        switch error {

        case .notConnected:
            handleNotConnected()

        default:
            /*
             FileTransferService owns transfer-related
             Bluetooth errors. Only surface unrelated
             BLE errors here when this feature initiated
             a statistics read.
             */
            if wasReadingTotalUploadedBytes {
                errorMessage =
                    error.localizedDescription
            }
        }
    }

    func handleNotConnected() {
        isReadingTotalUploadedBytes =
            false

        errorMessage =
            "Connect to the device before using file transfer."
    }
}

// MARK: - Total Uploaded Bytes Decoding

private extension FileTransferViewModel {

    func handleTotalUploadedBytes(
        _ data: Data
    ) {
        isReadingTotalUploadedBytes =
            false

        guard let value =
                decodeUInt64LittleEndian(
                    from: data
                ) else {
            errorMessage =
                """
                Invalid Total Uploaded Bytes \
                response.
                """

            return
        }

        totalUploadedBytes = value
    }

    func decodeUInt64LittleEndian(
        from data: Data
    ) -> UInt64? {
        guard data.count >= 8 else {
            return nil
        }

        var value: UInt64 = 0

        for (index, byte) in
            data.prefix(8).enumerated() {

            value |=
                UInt64(byte) <<
                UInt64(index * 8)
        }

        return value
    }
}

