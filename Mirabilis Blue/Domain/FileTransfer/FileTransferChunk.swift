//
//  FileTransferChunk.swift
//  Mirabilis Blue
//
//  Created by Max Ueda on 31/08/26.
//

import Foundation

struct FileTransferChunk: Equatable {

    let marker: FileTransferProtocol.Marker
    let sequence: UInt8
    let payload: Data

    init(
        marker: FileTransferProtocol.Marker,
        sequence: UInt8,
        payload: Data
    ) throws {
        guard payload.count <=
                FileTransferProtocol.payloadSize else {
            throw FileTransferError.payloadTooLarge
        }

        self.marker = marker
        self.sequence = sequence
        self.payload = payload
    }

    var data: Data {
        var result = Data([
            marker.rawValue,
            sequence
        ])

        result.append(payload)

        return result
    }
}
