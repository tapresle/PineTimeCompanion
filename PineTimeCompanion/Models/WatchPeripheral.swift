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
  public static let watchGATTFirmwareUpdateUUID = CBUUID.init(string: "00001530-1212-EFDE-1523-785FEABCD123")
  public static let gattCurrentTimeUUID = CBUUID.init(string: "0x1805")
  public static let gattCurrentTimeCharacteristicUUID = CBUUID.init(string: "0x2A2B")
  public static let gattAlertNotificationServiceUUID = CBUUID.init(string: "0x1811")
  public static let gattNewAlertCharacteristicUUID = CBUUID.init(string: "0x2A46")
  public static let gattSupportedNewAlertCategoryUUID = CBUUID.init(string: "0x2A47")
  public static let gattSupportedUnreadAlertCategoryUUID = CBUUID.init(string: "0x2A48")
  public static let watchGATTMusicServiceUUID = CBUUID.init(string: "00000000-78fc-48fe-8e23-433b3a1942d0")
  public static let watchGATTMusicNotifyChacteristicUUID = CBUUID.init(string: "00000001-78fc-48fe-8e23-433b3a1942d0")
  public static let watchGATTMusicStatusChacteristicUUID = CBUUID.init(string: "00000002-78fc-48fe-8e23-433b3a1942d0")
  public static let watchGATTArtistChacteristicUUID = CBUUID.init(string: "00000003-78fc-48fe-8e23-433b3a1942d0")
  public static let watchGATTTrackChacteristicUUID = CBUUID.init(string: "00000004-78fc-48fe-8e23-433b3a1942d0")
  public static let watchGATTAlbumChacteristicUUID = CBUUID.init(string: "00000005-78fc-48fe-8e23-433b3a1942d0")
  public static let watchGATTPositionChacteristicUUID = CBUUID.init(string: "00000006-78fc-48fe-8e23-433b3a1942d0")
  public static let watchGATTTotalLengthChacteristicUUID = CBUUID.init(string: "00000007-78fc-48fe-8e23-433b3a1942d0")
  public static let watchGATTMusicAppActiveChacteristicID = 224
  public static let watchGATTMusicAppPlayChacteristicID = 0
  public static let watchGATTMusicAppPauseChacteristicID = 1
  public static let watchGATTMusicAppReverseChacteristicID = 4
  public static let watchGATTMusicAppForwardChacteristicID = 3

}
