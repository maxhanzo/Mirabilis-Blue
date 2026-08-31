//
//  FileTransferState.swift
//  Mirabilis Blue
//
//  Created by Max Ueda on 31/08/26.
//

import Foundation

enum FileTransferState: Equatable {

    case idle

    case preparingUpload(Int)

    case uploading(
        transferred: Int,
        total: Int
    )

    case preparingDownload

    case downloading(Int)

    case completed(Data)

    case cancelled

    case failed(FileTransferError)
}
