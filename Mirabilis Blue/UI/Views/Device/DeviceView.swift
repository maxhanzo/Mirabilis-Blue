//
//  DeviceView.swift
//  Mirabilis Blue
//
//  Created by Max Ueda on 31/08/26.
//

import CoreBluetooth
import SwiftUI

struct DeviceView: View {

    @State var viewModel: DeviceViewModel

    var body: some View {
        List {
            deviceInformationSection
            tutorialCharacteristicsSection
        }
        .navigationTitle(
            viewModel.device.displayName
        )
        .navigationBarTitleDisplayMode(
            .inline
        )
    }
}

// MARK: - Device Information

private extension DeviceView {

    var deviceInformationSection:
        some View {

        Section(
            "Device Information"
        ) {
            informationRow(
                title: "Serial Number",
                value: viewModel.serialNumber
            )

            informationRow(
                title: "Hardware Revision",
                value: viewModel.hardwareRevision
            )

            informationRow(
                title: "Firmware Revision",
                value: viewModel.firmwareRevision
            )
        }
    }

    func informationRow(
        title: String,
        value: String?
    ) -> some View {
        HStack {
            Text(title)

            Spacer()

            if let value {
                Text(value)
                    .foregroundStyle(
                        .secondary
                    )
            } else {
                ProgressView()
                    .controlSize(
                        .small
                    )
            }
        }
    }
}

// MARK: - Tutorial Characteristics

private extension DeviceView {

    var tutorialCharacteristicsSection:
        some View {

        Section(
            "Tutorial Characteristics"
        ) {
            if viewModel
                .tutorialCharacteristics
                .isEmpty {

                Text(
                    "No characteristics discovered"
                )
                .foregroundStyle(
                    .secondary
                )

            } else {
                ForEach(
                    viewModel
                        .tutorialCharacteristics,
                    id: \.self
                ) { characteristic in

                    characteristicRow(
                        characteristic
                    )
                }
            }
        }
    }

    func characteristicRow(
        _ characteristic:
            MirabilisUUID.Characteristic
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 4
        ) {
            Text(
                characteristic.displayName
            )

            Text(
                characteristic.uuid.uuidString
            )
            .font(
                .caption
            )
            .foregroundStyle(
                .secondary
            )
        }
    }
}

extension MirabilisUUID.Characteristic {

    var displayName: String {
        switch self {

        case .serialNumber:
            return "Serial Number"

        case .hardwareRevision:
            return "Hardware Revision"

        case .firmwareRevision:
            return "Firmware Revision"

        case .basicWrite:
            return "Basic Write"

        case .lastWrittenValue:
            return "Last Written Value"

        case .observableWrite:
            return "Observable Write"

        case .observableValue:
            return "Observable Value"

        case .periodicEventStream:
            return "Periodic Event Stream"

        case .writeWithoutResponse:
            return "Write Without Response"

        case .lastWriteWithoutResponseValue:
            return "Last WNR Value"

        case .secureWrite:
            return "Secure Write"

        case .secureState:
            return "Secure State"

        case .fileTransferRX:
            return "File Transfer RX"

        case .fileTransferTX:
            return "File Transfer TX"

        case .totalUploadedBytes:
            return "Total Uploaded Bytes"
        }
    }
}

