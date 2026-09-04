//
//  AppCoordinatorView.swift
//  Mirabilis Blue
//
//  Created by Max Ueda on 31/08/26.
//

import SwiftUI

struct AppCoordinatorView: View {

    @Bindable var coordinator: AppCoordinator

    var body: some View {
        NavigationStack(
            path: $coordinator.path
        ) {
            ScannerView(
                viewModel: coordinator.scannerViewModel
            )
            .navigationDestination(
                for: AppCoordinator.Route.self
            ) { route in
                destination(
                    for: route
                )
            }
        }
    }
}

// MARK: - Destinations

private extension AppCoordinatorView { // 'AppCoordinatorView' is ambiguous for type lookup in this context

    @ViewBuilder
    func destination(
        for route: AppCoordinator.Route
    ) -> some View {
        switch route {

        case .device(let device):
            DeviceView(
                viewModel:
                    coordinator.makeDeviceViewModel(
                        device: device
                    ),
                onFileTransferTapped: {
                    coordinator.showFileTransfer(
                        for: device
                    )
                }
            )

        case .fileTransfer(let device):
            FileTransferView(
                viewModel:
                    coordinator.makeFileTransferViewModel(
                        device: device
                    )
            )
        }
    }
}
