//
// Created by Jefferson Jones on 5/28/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation
import CoreBluetooth
import Crashlytics

enum CBInstrumentManagerError: Error {
  case unknownPeripheralUUID
  case connectionFailed
}

class CBInstrumentManager: NSObject, InstrumentManager {
  
  static let shared: CBInstrumentManager = CBInstrumentManager()
  
  var delegate: InstrumentManagerDelegate? = nil
  
  private let     cbManager:           CBCentralManager
  private let     phyterServiceUUID                             = CBUUID(string: "FFE0")
  fileprivate var connectCallbacks:    [UUID: (Error?) -> Void] = [:]
  fileprivate var disconnectCallbacks: [UUID: (Error?) -> Void] = [:]
  fileprivate var shouldScanOnPowerOn                           = false
  
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
    Answers.logCustomEvent(
        withName: "Connect to Peripheral",
        customAttributes: ["name": matchingPeripherals[0].name ?? "?"]
    )
    if cbManager.isScanning {
      stopScanForInstruments()
    }
    cbManager.connect(matchingPeripherals[0])
  }
  
  func disconnect(fromInstrument instrument: PhyterInstrument, onComplete: @escaping (Error?) -> Void) {
    let matchingPeripherals = cbManager.retrievePeripherals(withIdentifiers: [instrument.id])
    guard matchingPeripherals.count > 0 else {
      onComplete(CBInstrumentManagerError.unknownPeripheralUUID)
      return
    }
    disconnectCallbacks[instrument.id] = onComplete
    Answers.logCustomEvent(
        withName: "Disconnect from Peripheral",
        customAttributes: ["name": matchingPeripherals[0].name ?? "?"]
    )
    cbManager.cancelPeripheralConnection(matchingPeripherals[0])
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
    Answers.logCustomEvent(withName: "Discovered Peripheral", customAttributes: ["name": peripheral.name ?? "?"])
    let instrument = CBPhyterInstrument(peripheral, rssi: RSSI)
    delegate?.instrumentManager(didDiscoverInstrument: instrument)
    stopScanForInstruments()
  }
  
  public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    Answers.logCustomEvent(withName: "Peripheral Connected", customAttributes: ["name": peripheral.name ?? "?"])
    let key = peripheral.identifier
    guard let callback = connectCallbacks[key] else { return }
    callback(nil)
    connectCallbacks[key] = nil
  }
  
  public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
    Answers.logCustomEvent(withName: "Peripheral Connection Failed", customAttributes: ["name": peripheral.name ?? "?"])
    let key = peripheral.identifier
    guard let callback = connectCallbacks[key] else { return }
    callback(CBInstrumentManagerError.connectionFailed)
    connectCallbacks[key] = nil
  }
  
  public func centralManager(
      _ central: CBCentralManager,
      didDisconnectPeripheral peripheral: CBPeripheral,
      error: Error?) {
    Answers.logCustomEvent(withName: "Peripheral Disconnected", customAttributes: ["name": peripheral.name ?? "?"])
    let key = peripheral.identifier
    guard let cb = disconnectCallbacks[key] else { return }
    cb(nil)
    disconnectCallbacks[key] = nil
  }
}


