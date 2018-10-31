//
// Created by Jefferson Jones on 5/28/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation
import CoreBluetooth
import Crashlytics
import RxSwift

enum CBInstrumentManagerError: Error {
  case unknownPeripheralUUID
  case connectionFailed
}

fileprivate let TAG = "CBInstrumentManager"

class CBInstrumentManager: NSObject, InstrumentManager {
  
  static let shared: CBInstrumentManager = CBInstrumentManager()
  
  var delegate: InstrumentManagerDelegate? = nil
  
  private let cbManager:             CBCentralManager
  private let phyterServiceUUID                                 = CBUUID(string: "FFE0")
  private var discoveredInstruments: [UUID: CBPhyterInstrument] = [:]
  private var connectSubjects:       [UUID: PublishSubject<()>] = [:]
  private var disconnectSubjects:    [UUID: PublishSubject<()>] = [:]
  private var shouldScanOnPowerOn                               = false
  
  private override init() {
    cbManager = CBCentralManager()
    super.init()
    cbManager.delegate = self
    
  }
  
  func scanForInstruments() {
    guard cbManager.state == .poweredOn else {
      consoleLog(TAG, "scan will start after manager is ready.")
      shouldScanOnPowerOn = true
      return
    }
    consoleLog(TAG, "starting instrument scan...")
    cbManager.scanForPeripherals(withServices: [phyterServiceUUID])
  }
  
  func stopScanForInstruments() {
    consoleLog(TAG, "stopping instrument scan...")
    cbManager.stopScan()
  }
  
  func connect(toInstrument instrument: PhyterInstrument) -> Completable {
    guard let instrument = discoveredInstruments[instrument.id] else {
      return .error(CBInstrumentManagerError.unknownPeripheralUUID)
    }
    return Completable.deferred { [weak self] in
      guard let this = self else { return .never() }
      let subject = PublishSubject<()>()
      this.connectSubjects[instrument.id] = subject
      Answers.logCustomEvent(
          withName: "Connect to Peripheral",
          customAttributes: ["name": instrument.name]
      )
      if this.cbManager.isScanning {
        this.stopScanForInstruments()
      }
      this.cbManager.connect(instrument.peripheral)
      return subject.take(1).ignoreElements()
    }
  }
  
  func disconnect(fromInstrument instrument: PhyterInstrument) -> Completable {
    guard let instrument = discoveredInstruments[instrument.id] else {
      return .error(CBInstrumentManagerError.unknownPeripheralUUID)
    }
    return Completable.deferred { [weak self] in
      guard let this = self else { return .never() }
      let subject = PublishSubject<()>()
      this.disconnectSubjects[instrument.id] = subject
      Answers.logCustomEvent(
          withName: "Disconnect from Peripheral",
          customAttributes: ["name": instrument.name]
      )
      this.cbManager.cancelPeripheralConnection(instrument.peripheral)
      return subject.take(1).ignoreElements()
    }
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
    Answers.logCustomEvent(withName: "Discovered Peripheral", customAttributes: ["name": peripheral.name ?? "?"])
    consoleLog(TAG, "discovered peripheral '\(peripheral.name ?? "?")'")
    let instrument = CBPhyterInstrument(peripheral, rssi: RSSI)
    discoveredInstruments[peripheral.identifier] = instrument
    delegate?.instrumentManager(didDiscoverInstrument: instrument)
  }
  
  public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    Answers.logCustomEvent(withName: "Peripheral Connected", customAttributes: ["name": peripheral.name ?? "?"])
    consoleLog(TAG, "connected to peripheral '\(peripheral.name ?? "?")'")
    guard let subject = connectSubjects.removeValue(forKey: peripheral.identifier) else { return }
    subject.onNext(())
    subject.onCompleted()
  }
  
  public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
    Answers.logCustomEvent(withName: "Peripheral Connection Failed", customAttributes: ["name": peripheral.name ?? "?"])
    consoleLog(TAG, "failed to connect peripheral '\(peripheral.name ?? "?")'")
    guard let subject = connectSubjects.removeValue(forKey: peripheral.identifier) else { return }
    subject.onError(CBInstrumentManagerError.connectionFailed)
  }
  
  public func centralManager(
      _ central: CBCentralManager,
      didDisconnectPeripheral peripheral: CBPeripheral,
      error: Error?) {
    Answers.logCustomEvent(withName: "Peripheral Disconnected", customAttributes: ["name": peripheral.name ?? "?"])
    consoleLog(TAG, "disconnected peripheral '\(peripheral.name ?? "?")'")
    discoveredInstruments[peripheral.identifier]?.notifyDisconnected()
    guard let subject = disconnectSubjects.removeValue(forKey: peripheral.identifier) else { return }
    subject.onNext(())
    subject.onCompleted()
  }
}


