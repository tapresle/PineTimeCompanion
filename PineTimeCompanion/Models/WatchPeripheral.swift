//
//  WatchPeripheral.swift
//  PineTimeCompanion
//
//  Created by Ted Presley on 7/9/21.
//

import Foundation

import UIKit
import CoreBluetooth

class WatchPeripheral: NSObject {
  public static let gattCurrentTimeUUID = CBUUID.init(string: "0x1805")
  public static let gattCurrentTimeCharacteristicUUID = CBUUID.init(string: "0x2A2B")
  public static let watchGATTFirmwareUpdateUUID = CBUUID.init(string: "00001530-1212-EFDE-1523-785FEABCD123")
}
