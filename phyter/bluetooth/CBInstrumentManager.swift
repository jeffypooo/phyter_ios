//
// Created by Jefferson Jones on 5/28/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation
import CoreBluetooth

enum CBInstrumentManagerError: Error {
  case unknownPeripheralUUID
  case connectionFailed
}

class CBInstrumentManager: NSObject, InstrumentManager {
  
  var delegate: InstrumentManagerDelegate? = nil
  
  private let     cbManager:        CBCentralManager
  private let     phyterServiceUUID                          = CBUUID(string: "FFE0")
  fileprivate var connectCallbacks: [UUID: (Error?) -> Void] = [:]
  fileprivate var shouldScanOnPowerOn                        = false
  
  public override init() {
    cbManager = CBCentralManager()
    super.init()
    cbManager.delegate = self
    
  }
  
  func scanForInstruments() {
    guard cbManager.state == .poweredOn else {
      print("scan will start after manager is ready.")
      shouldScanOnPowerOn = true
      return
    }
    print("starting instrument scan...")
    cbManager.scanForPeripherals(withServices: [phyterServiceUUID])
  }
  
  func stopScanForInstruments() {
    print("stopping instrument scan...")
    cbManager.stopScan()
  }
  
  func connect(
      toInstrument instrument: PhyterInstrument,
      onComplete: @escaping (Error?) -> Void) {
    let matchingPeripherals = cbManager.retrievePeripherals(withIdentifiers: [instrument.id])
    guard matchingPeripherals.count > 0 else {
      onComplete(CBInstrumentManagerError.unknownPeripheralUUID)
      return
    }
    connectCallbacks[instrument.id] = onComplete
    cbManager.connect(matchingPeripherals[0])
  }
  
  
}

extension CBInstrumentManager: CBCentralManagerDelegate {
  
  
  public func centralManagerDidUpdateState(_ central: CBCentralManager) {
    if central.state == .poweredOn && shouldScanOnPowerOn {
      shouldScanOnPowerOn = false
      scanForInstruments()
    }
  }
  
  public func centralManager(
      _ central: CBCentralManager,
      didDiscover peripheral: CBPeripheral,
      advertisementData: [String: Any],
      rssi RSSI: NSNumber) {
    print("discovered peripheral \(peripheral.name ?? "?")")
    let instrument = CBPhyterInstrument(peripheral, rssi: RSSI)
    delegate?.instrumentManager(didDiscoverInstrument: instrument)
  }
  
  public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    let key = peripheral.identifier
    guard let callback = connectCallbacks[key] else { return }
    callback(nil)
    connectCallbacks[key] = nil
  }
  
  public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
    let key = peripheral.identifier
    guard let callback = connectCallbacks[key] else { return }
    callback(CBInstrumentManagerError.connectionFailed)
    connectCallbacks[key] = nil
  }
  
  public func centralManager(
      _ central: CBCentralManager,
      didDisconnectPeripheral peripheral: CBPeripheral,
      error: Error?) {
    
  }
}


