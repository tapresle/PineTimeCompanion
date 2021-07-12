//
//  ViewController.swift
//  PineTimeCompanion
//
//  Created by Ted Presley on 7/9/21.
//

import UIKit
import CoreBluetooth
import MediaPlayer

class ViewController: UIViewController, CBPeripheralDelegate, CBCentralManagerDelegate {
  private var centralManager: CBCentralManager!
  private var peripheral: CBPeripheral!
  private var characteristic: CBCharacteristic!
  private var alertCharacteristic: CBCharacteristic!
  private var musicNotifyCharacteristic: CBCharacteristic!
  private var musicStatusCharacteristic: CBCharacteristic!
  private var musicTrackCharacteristic: CBCharacteristic!
  private var musicArtistCharacteristic: CBCharacteristic!
  private var musicAlbumCharacteristic: CBCharacteristic!
  private var musicPositionCharacteristic: CBCharacteristic!
  private var musicTotalLengthCharacteristic: CBCharacteristic!
  
  let audioInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo
  
  @IBOutlet weak var setCurrentTimeButton: UIButton!
  @IBOutlet weak var connectionLabel: UILabel!
  
  @IBAction func setCurrentTimeButtonPressed(_ sender: Any) {
    setTime(peripheral: self.peripheral, characteristic: self.characteristic)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.
    let notificationCenter = NotificationCenter.default
    notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
    notificationCenter.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    centralManager = CBCentralManager(delegate: self, queue: nil)
  }
  
  @objc func appMovedToBackground() {
    if self.peripheral != nil {
      //centralManager.cancelPeripheralConnection(self.peripheral)
    }
  }
  
  @objc func appMovedToForeground() {
    if self.centralManager != nil {
      startScanning(self.centralManager)
    }
  }
  
  // If we're powered on, start scanning
  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    startScanning(central)
  }
  
  func startScanning(_ central: CBCentralManager) {
    print("Central state update")
    if central.state != .poweredOn {
      print("Central is not powered on")
    } else {
      print("Central scanning for", WatchPeripheral.watchGATTFirmwareUpdateUUID);
      centralManager.scanForPeripherals(withServices: [WatchPeripheral.watchGATTFirmwareUpdateUUID],
                                        options: [CBCentralManagerScanOptionAllowDuplicatesKey : true])
    }
  }
  
  // Handles the result of the scan
  func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
    
    self.connectionLabel.text = "Connecting..."
    
    if (peripheral.name == "InfiniTime") {
      // We've found it so stop scan
      self.centralManager.stopScan()
      print("found")
      
      // Copy the peripheral instance
      self.peripheral = peripheral
      self.peripheral.delegate = self
      
      // Connect!
      self.centralManager.connect(self.peripheral, options: nil)
    } else {
      print("found: " + (peripheral.name ?? "N/A"))
    }
    
  }
  
  // The handler if we do connect succesfully
  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    if peripheral == self.peripheral {
      print("Connected to InfiniTime Watch")
      self.connectionLabel.text = "Connected to \(peripheral.name!)"
      self.connectionLabel.numberOfLines = 0
      self.connectionLabel.sizeToFit()
      peripheral.discoverServices([])
    }
  }
  
  // Handles discovery event
  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    if let services = peripheral.services {
      for service in services {
        if service.uuid == WatchPeripheral.gattCurrentTimeUUID {
          print("GATT current time service found")
          //Now kick off discovery of characteristics
          peripheral.discoverCharacteristics([], for: service)
        }
        
        if service.uuid == WatchPeripheral.gattAlertNotificationServiceUUID {
          print("GATT Alert Service found")
          peripheral.discoverCharacteristics([], for: service)
        }
        
        if service.uuid == WatchPeripheral.watchGATTMusicServiceUUID {
          print("GATT InfiniTime Music Service found")
          peripheral.discoverCharacteristics([], for: service)
        }
      }
    }
  }
  
  // Handling discovery of characteristics
  func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
    if let characteristics = service.characteristics {
      for characteristic in characteristics {
        if characteristic.uuid == WatchPeripheral.gattCurrentTimeCharacteristicUUID {
          print("GATT current time characteristic found")
          self.characteristic = characteristic
        }
        if characteristic.uuid == WatchPeripheral.gattNewAlertCharacteristicUUID {
          print("GATT new alert characteristic found")
          self.alertCharacteristic = characteristic
          sendAlert(peripheral: self.peripheral, characteristic: self.alertCharacteristic, text: "Connected to iPhone")
        }
        if characteristic.uuid == WatchPeripheral.watchGATTMusicStatusChacteristicUUID {
          self.musicStatusCharacteristic = characteristic
        }
        if characteristic.uuid == WatchPeripheral.watchGATTMusicNotifyChacteristicUUID {
          self.musicNotifyCharacteristic = characteristic
          peripheral.setNotifyValue(true, for: characteristic)
        }
        if characteristic.uuid == WatchPeripheral.watchGATTArtistChacteristicUUID {
          self.musicArtistCharacteristic = characteristic
        }
        if characteristic.uuid == WatchPeripheral.watchGATTTrackChacteristicUUID {
          self.musicTrackCharacteristic = characteristic
        }
        if characteristic.uuid == WatchPeripheral.watchGATTAlbumChacteristicUUID {
          self.musicAlbumCharacteristic = characteristic
        }
        if characteristic.uuid == WatchPeripheral.watchGATTPositionChacteristicUUID {
          self.musicPositionCharacteristic = characteristic
        }
        if characteristic.uuid == WatchPeripheral.watchGATTTotalLengthChacteristicUUID {
          self.musicTotalLengthCharacteristic = characteristic
        }
      }
    }
  }
  
  func peripheral(_ peripheral: CBPeripheral,
                  didUpdateValueFor characteristic: CBCharacteristic,
                  error: Error?) {
    if characteristic.value![0] == WatchPeripheral.watchGATTMusicAppActiveChacteristicID {
      print("Music app active")
      loadMusicFromAppleMusic()
      print(AVAudioSession.sharedInstance().isOtherAudioPlaying)
      if AVAudioSession.sharedInstance().isOtherAudioPlaying {
        peripheral.writeValue(NSData(bytes: Array("1".utf8), length: Array("1".utf8).count) as Data, for: self.musicStatusCharacteristic, type: .withResponse)
      } else {
        peripheral.writeValue(NSData(bytes: [], length: 0) as Data, for: self.musicStatusCharacteristic, type: .withResponse)
      }
    }
    if characteristic.value![0] == WatchPeripheral.watchGATTMusicAppReverseChacteristicID {
      print("Rewind")
      let player = MPMusicPlayerController.systemMusicPlayer
      player.skipToPreviousItem()
      loadMusicFromAppleMusic()
    }
    if characteristic.value![0] == WatchPeripheral.watchGATTMusicAppForwardChacteristicID {
      print("Forward")
      let player = MPMusicPlayerController.systemMusicPlayer
      player.skipToNextItem()
      loadMusicFromAppleMusic()
    }
    if characteristic.value![0] == WatchPeripheral.watchGATTMusicAppPlayChacteristicID {
      print("Play")
      let player = MPMusicPlayerController.systemMusicPlayer
      player.play()
      peripheral.writeValue(NSData(bytes: Array("1".utf8), length: Array("1".utf8).count) as Data, for: self.musicStatusCharacteristic, type: .withResponse)
      loadMusicFromAppleMusic()
    }
    if characteristic.value![0] == WatchPeripheral.watchGATTMusicAppPauseChacteristicID {
      print("Pause")
      let player = MPMusicPlayerController.systemMusicPlayer
      player.pause()
      loadMusicFromAppleMusic()
      peripheral.writeValue(NSData(bytes: [], length: 0) as Data, for: self.musicStatusCharacteristic, type: .withResponse)
    }
  }
  
  func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
    if peripheral == self.peripheral {
      print("Disconnected")
      self.peripheral = nil
      self.connectionLabel.text = "Disconnected"
    }
  }
  
  func setTime(peripheral: CBPeripheral, characteristic: CBCharacteristic) {
    let date = Date()
    let calendar = Calendar.current
    let comp = calendar.dateComponents([.day, .month, .year, .hour, .minute, .second, .weekday, .nanosecond], from: date)
    
    let currentTimeArray = [Int8(bitPattern: UInt8(comp.year! % 256)), Int8(bitPattern: UInt8(comp.year! / 256)), Int8(bitPattern: UInt8(comp.month!)), Int8(bitPattern: UInt8(comp.day!)), Int8(bitPattern: UInt8(comp.hour!)), Int8(bitPattern: UInt8(comp.minute!)), Int8(bitPattern: UInt8(comp.second!)), Int8(bitPattern: UInt8(0)), Int8(bitPattern: UInt8(220))]
    let currentTimeArray_data = NSData(bytes: currentTimeArray, length: currentTimeArray.count)
    
    peripheral.writeValue(currentTimeArray_data as Data, for: characteristic, type: .withResponse)
    print("Current Time Set")
  }
  
  func sendAlert(peripheral: CBPeripheral, characteristic: CBCharacteristic, text: String) {
    let message = "   " + text // No idea why Infinitime truncates the first 3 bytes
    let array: [UInt8] = Array(message.utf8)
    peripheral.writeValue(NSData(bytes: array, length: array.count) as Data, for: characteristic, type: .withResponse)
  }
  
  // TOOD: Need access to Spotify API to retrieve data from them apparently.
  func loadMusicFromAppleMusic() {
    let player = MPMusicPlayerController.systemMusicPlayer
    if let mediaItem = player.nowPlayingItem {
      let artist = mediaItem.value(forProperty: MPMediaItemPropertyArtist) as! String
      let album = mediaItem.value(forProperty: MPMediaItemPropertyAlbumTitle) as! String
      let track = mediaItem.value(forProperty: MPMediaItemPropertyTitle) as! String

      peripheral.writeValue(NSData(bytes: Array(artist.utf8), length: Array(artist.utf8).count) as Data, for: self.musicArtistCharacteristic, type: .withResponse)
      peripheral.writeValue(NSData(bytes: Array(album.utf8), length: Array(album.utf8).count) as Data, for: self.musicAlbumCharacteristic, type: .withResponse)
      peripheral.writeValue(NSData(bytes: Array(track.utf8), length: Array(track.utf8).count) as Data, for: self.musicTrackCharacteristic, type: .withResponse)
      peripheral.writeValue(NSData(bytes: withUnsafeBytes(of: Int32(player.currentPlaybackTime).bigEndian, Array.init), length: 4) as Data, for: self.musicPositionCharacteristic, type: .withResponse)
      peripheral.writeValue(NSData(bytes: withUnsafeBytes(of: Int32(mediaItem.playbackDuration).bigEndian, Array.init), length: 4) as Data, for: self.musicTotalLengthCharacteristic, type: .withResponse)
    }
  }
}

