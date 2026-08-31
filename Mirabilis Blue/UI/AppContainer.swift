//
//  AppContainer.swift
//  Mirabilis Blue
//
//  Created by Max Ueda on 31/08/26.
//


//
//  AppContainer.swift
//  Mirabilis Blue
//
//  Created by Max Ueda on 31/08/26.
//

import Foundation

final class AppContainer {

    let bluetoothManager: BluetoothManaging

    init() {
        bluetoothManager = BluetoothManager()
    }
}