//
//  CBManager.swift
//  cardiowatchtest
//
//  Created by David A on 2021/11/18.
//

//Known services and characteristics for cardiowatch
//<CBService: 0x281b40f80, isPrimary = YES, UUID = FE59>
//<CBService: 0x281b40d80, isPrimary = YES, UUID = Heart Rate>
//<CBService: 0x281b414c0, isPrimary = YES, UUID = Battery>
//<CBService: 0x281b40f40, isPrimary = YES, UUID = 2E8C0001-2D91-5533-3117-59380A40AF8F>
//
//<CBCharacteristic: 0x282a1ed00, UUID = 8EC90003-F315-4F60-9FB8-838830DAEA50, properties = 0x28, value = (null), notifying = NO>
//<CBCharacteristic: 0x282a1c300, UUID = 2A37, properties = 0x10, value = (null), notifying = NO>
//<CBCharacteristic: 0x282a1ed60, UUID = 2A38, properties = 0x2, value = (null), notifying = NO>
//<CBCharacteristic: 0x282a1edc0, UUID = Battery Level, properties = 0x12, value = (null), notifying = NO>
//<CBCharacteristic: 0x282a08540, UUID = 2E8C0003-2D91-5533-3117-59380A40AF8F, properties = 0xC, value = (null), notifying = NO>
//<CBCharacteristic: 0x282a092c0, UUID = 2E8C0002-2D91-5533-3117-59380A40AF8F, properties = 0x10, value = (null), notifying = NO>

import Foundation
import CoreBluetooth
import SwiftUI


class CBManager : NSObject, ObservableObject, CBCentralManagerDelegate {
    
    let heartRateServiceID = "2E8C0001-2D91-5533-3117-59380A40AF8F"
    
    //Characteristics IDs
    let heartRateMeasurementCharacteristicCBUUID = CBUUID(string: "2A37")
    let bodySensorLocationCharacteristicCBUUID = CBUUID(string: "2A38")
    
    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral!
    
    @Published var cardioWatchUUIDString : String?
    @Published var state = ""
    @Published var bpm = 0
    
    var bound = false
    
    var uuid : UUID? {
        guard let id = cardioWatchUUIDString else { return nil }
        return UUID(uuidString: id)
    }

    
    struct defaultsKeys {
        static let deviceId = "device_id"
    }
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        cardioWatchUUIDString = getID()
        bound = cardioWatchUUIDString != nil
    }
    
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
            case .unknown:
                state = "central.state is .unknown"
            case .resetting:
                state = "central.state is .resetting"
            case .unsupported:
                state = "central.state is .unsupported,simulator not supported"
            case .unauthorized:
                state = "central.state is .unauthorized"
            case .poweredOff:
                state = "central.state is .poweredOff"
            case .poweredOn:
                state = "central.state is .poweredOn"
                setup()
            @unknown default:
                state = "central.state is default"
        }
        print(state)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print(peripheral)
        if peripheral.name == "H110-8504" { //once conected does not appear in the scan
            self.peripheral = peripheral
            centralManager.stopScan()
            connect(self.peripheral)
            cardioWatchUUIDString =  peripheral.identifier.uuidString
            saveID(id: cardioWatchUUIDString!)
        }
    }
    
    fileprivate func connect(_ peripheral: CBPeripheral) {
        peripheral.delegate = self
        centralManager.connect(peripheral, options: [:])
    }
    
    func setup() {
        if bound { //device has already been bound so reconnect otherwise scan for device
            guard let id = uuid else {return}
            let devices = centralManager.retrievePeripherals(withIdentifiers: [id])
            if devices.count > 0 {
                self.peripheral = devices.first!
                connect(self.peripheral)
            }
        } else {
            centralManager.scanForPeripherals(withServices: nil, options: [:])
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("connected!")
        self.peripheral.discoverServices(nil)
//        self.peripheral.discoverServices([CBUUID(string: heartRateServiceID)])
    }
    
    func disconnect() {
        
    }
    
    private func saveID(id:String) {
        let defaults = UserDefaults.standard
        defaults.set(id, forKey: defaultsKeys.deviceId)
    }
    
    private func getID() -> String?{
        let defaults = UserDefaults.standard
        return defaults.string(forKey: defaultsKeys.deviceId)
    }
    
    
   
}

extension CBManager : CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }

        for service in services {
            print(service)
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }

          for characteristic in characteristics {
              print(characteristic)
              peripheral.readValue(for: characteristic)
              if characteristic.properties.contains(.notify) {
                  print("\(characteristic.uuid): properties contains .notify")
                  peripheral.setNotifyValue(true, for: characteristic)
              }
          }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
      switch characteristic.uuid {
        case heartRateMeasurementCharacteristicCBUUID:
          print("HR")
          bpm = heartRate(from: characteristic)
        default:
          print("Unhandled Characteristic UUID: \(characteristic.uuid)")
      }
    }
    
    private func heartRate(from characteristic: CBCharacteristic) -> Int {
      guard let characteristicData = characteristic.value else { return -1 }
      let byteArray = [UInt8](characteristicData)

      let firstBitValue = byteArray[0] & 0x01
      if firstBitValue == 0 {
        // Heart Rate Value Format is in the 2nd byte
        return Int(byteArray[1])
      } else {
        // Heart Rate Value Format is in the 2nd and 3rd bytes
        return (Int(byteArray[1]) << 8) + Int(byteArray[2])
      }
    }

    
}
