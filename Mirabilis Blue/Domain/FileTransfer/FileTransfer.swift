//
//  FileTransfer.swift
//  Mirabilis Blue
//
//  Created by Max Ueda on 31/08/26.
//

import Foundation

enum FileTransferProtocol {

    static let packetSize = 20
    static let payloadSize = 18
    static let chunksPerAcknowledgement = 8
    static let maximumFileSize = 16_384

    enum Marker: UInt8 {
        case str = 0x02
        case etx = 0x03
    }

    enum Control: UInt8 {
        case acknowledgement = 0x06
        case negativeAcknowledgement = 0x15
        case cancel = 0x18
    }

    enum Command: UInt8 {
        case upload = 0x55
        case download = 0x44
    }
}
