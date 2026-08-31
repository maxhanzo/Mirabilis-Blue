//
//  FileTransferError.swift
//  Mirabilis Blue
//
//  Created by Max Ueda on 31/08/26.
//

import Foundation

enum FileTransferError: Error, Equatable {

    case fileTooLarge(
        actual: Int,
        maximum: Int
    )

    case payloadTooLarge

    case malformedPacket

    case unexpectedSequence(
        expected: UInt8,
        received: UInt8
    )

    case negativeAcknowledgement(UInt8?)

    case timeout

    case disconnected

    case bluetooth(BluetoothError)
}
