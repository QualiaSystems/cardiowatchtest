//
//  CBManager.swift
//  cardiowatchtest
//
//  Created by David A on 2021/11/18.
//

import Foundation
import CoreBluetooth
import SwiftUI


class CBManager : NSObject, ObservableObject, CBCentralManagerDelegate {
    
    let heartRateServiceID = 0x281586080
    
    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral!
    
    @Published var cardioWatchUUIDString : String?
    @Published var state = ""
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
                state = "central.state is .unsupported"
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
        }
    }
    
}
