//
//  ViewController.swift
//  PineTimeCompanion
//
//  Created by Ted Presley on 7/9/21.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBPeripheralDelegate, CBCentralManagerDelegate {
  private var centralManager: CBCentralManager!
  private var peripheral: CBPeripheral!
  private var characteristic: CBCharacteristic!
  
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
    centralManager.cancelPeripheralConnection(self.peripheral)
  }
  
  @objc func appMovedToForeground() {
    print("Central scanning for", WatchPeripheral.watchGATTFirmwareUpdateUUID);
    centralManager.scanForPeripherals(withServices: [WatchPeripheral.watchGATTFirmwareUpdateUUID],
                                      options: [CBCentralManagerScanOptionAllowDuplicatesKey : true])
  }
  
  // If we're powered on, start scanning
  func centralManagerDidUpdateState(_ central: CBCentralManager) {
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
      
      print(self.connectionLabel.text!)
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
          return
        }
      }
    }
  }
  
  // Handling discovery of characteristics
  func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
    if let characteristics = service.characteristics {
      for characteristic in characteristics {
        if characteristic.uuid == WatchPeripheral.gattCurrentTimeCharacteristicUUID {
          print("GATT characteristic found")
          self.characteristic = characteristic
        }
      }
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
  
  
}

