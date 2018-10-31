//
// Created by Jefferson Jones on 5/28/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation
import CoreBluetooth
import RxSwift
import Crashlytics

fileprivate let TAG = "CBPhyterInstrument"

class CBPhyterInstrument: NSObject, PhyterInstrument {
  var id: UUID {
    return peripheral.identifier
  }
  
  var name: String {
    return peripheral.name ?? "N/A"
  }
  
  var rssi: Int {
    return Int(truncating: lastReadRssi)
  }
  
  var connected: Bool {
    return peripheral.state == .connected
  }
  
  var salinity: Observable<Float32> {
    return salinitySubject
  }
  
  let salinitySubject: PublishSubject<Float32> = PublishSubject()
  
  let peripheral:         CBPeripheral
  var lastReadRssi:       NSNumber
  var sppService:         CBService?
  var txRxCharacteristic: CBCharacteristic?
  var runAfterIOInit:     (() -> Void)?
  var ioInitialized                                       = false
  var backgroundSubject:  PublishSubject<()>              = PublishSubject()
  var measureSubject:     PublishSubject<MeasurementData> = PublishSubject()
  var currentMeasurement: MeasurementData?
  
  init(_ peripheral: CBPeripheral, rssi: NSNumber) {
    self.peripheral = peripheral
    self.lastReadRssi = rssi;
    super.init()
    self.peripheral.delegate = self
  }
  
  func setSalinity(_ salinity: Float32) {
    guard connected else { return }
    if !ioInitialized {
      runAfterIOInit = {
        self.setSalinity(salinity)
      }
      lazyInitializeIO()
      return
    }
    Answers.logCustomEvent(withName: "Set Salinity", customAttributes: ["value": NSNumber(value: salinity)])
    sendSetSalinityCommand(salinity)
  }
  
  func background() -> Completable {
    return Completable.deferred { [weak self] in
      guard let this = self else { return .empty() }
      guard this.connected else { return .error(InstrumentError.disconnected) }
      this.doBackground()
      return this.backgroundSubject.take(1).ignoreElements()
    }
  }
  
  func measure() -> Single<MeasurementData> {
    return Single.deferred { [weak self] in
      guard let this = self else { return .never() }
      guard this.connected else { return .error(InstrumentError.disconnected) }
      this.doMeasure()
      return this.measureSubject.take(1).asSingle()
    }
  }
  
  private func doBackground() {
    if !ioInitialized {
      runAfterIOInit = { self.doBackground() }
      lazyInitializeIO()
      return
    }
    Answers.logCustomEvent(withName: "Background")
    sendBackgroundCommand()
  }
  
  private func doMeasure() {
    if !ioInitialized {
      runAfterIOInit = { self.doMeasure() }
      lazyInitializeIO()
      return
    }
    Answers.logCustomEvent(withName: "Measure")
    sendMeasureCommand()
  }
  
  private func lazyInitializeIO() {
    let connected = peripheral.state == .connected
    Answers.logCustomEvent(withName: "IO Lazy Init", customAttributes: ["device connected": connected ? "yes" : "no"])
    guard connected else { return }
    consoleLog(TAG, "lazy initializing IO...")
    peripheral.discoverServices([PHYTER_SPP_SERVICE_UUID])
  }
  
  private func sendSetSalinityCommand(_ sal: Float32) {
    consoleLog(TAG, "sending set salinity cmd")
    var data: [UInt8] = [Command.setSalinity.rawValue]
    data.append(contentsOf: toBytes(sal))
    guard let txRx = self.txRxCharacteristic else { return }
    peripheral.writeValue(Data(bytes: data), for: txRx, type: .withoutResponse)
  }
  
  private func sendBackgroundCommand() {
    consoleLog(TAG, "sending background cmd")
    guard let txRx = self.txRxCharacteristic else { return }
    peripheral.writeValue(Data(bytes: [Command.background.rawValue]), for: txRx, type: .withoutResponse)
  }
  
  private func sendMeasureCommand() {
    consoleLog(TAG, "sending measure cmd")
    guard let txRx = self.txRxCharacteristic else { return }
    peripheral.writeValue(Data(bytes: [Command.measure.rawValue]), for: txRx, type: .withoutResponse)
  }
  
  private func emitErrorAndResetSubjects(_ error: Error) {
    // emit errors to observers if necessary and then recreate the subjects
    if backgroundSubject.hasObservers {
      backgroundSubject.onError(error)
      backgroundSubject.dispose()
    }
    if measureSubject.hasObservers {
      measureSubject.onError(error)
      measureSubject.dispose()
    }
    backgroundSubject = PublishSubject()
    measureSubject = PublishSubject()
  }
  
}

extension CBPhyterInstrument: CBPeripheralDelegate {
  
  public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
    self.lastReadRssi = RSSI
  }
  
  public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    if let sppService = peripheral.services?.first(where: { service in service.uuid == PHYTER_SPP_SERVICE_UUID }) {
      self.sppService = sppService
      peripheral.discoverCharacteristics([PHYTER_SPP_TX_RX_UUID], for: sppService)
    }
    
  }
  
  public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
    if let txRx = service.characteristics?.first(where: { char in char.uuid == PHYTER_SPP_TX_RX_UUID }) {
      consoleLog(TAG, "discovered TX/RX characteristic")
      self.txRxCharacteristic = txRx
      peripheral.setNotifyValue(true, for: txRx)
      ioInitialized = true
      Answers.logCustomEvent(withName: "Lazy IO Init Complete")
      DispatchQueue.global().async {
        self.runAfterIOInit?()
      }
    }
  }
  
  public func peripheral(
      _ peripheral: CBPeripheral,
      didUpdateValueFor characteristic: CBCharacteristic,
      error: Error?) {
    parseResponse()
  }
  
  private func parseResponse() {
    guard let value = self.txRxCharacteristic?.value else { return }
    var bytes = [UInt8](repeating: 0, count: value.count)
    value.copyBytes(to: &bytes, count: value.count)
    guard let resp = Response(rawValue: bytes[0]) else { return }
    switch resp {
      case .setSalinity:
        let sal = fromBytes([UInt8](bytes.suffix(4)), Float32.self)
        consoleLog(TAG, "salinity resp: \(sal)")
        Answers.logCustomEvent(withName: "Salinity Response", customAttributes: ["value": NSNumber(value: sal)])
        salinitySubject.onNext(sal)
        break
      case .background:
        consoleLog(TAG, "background resp")
        Answers.logCustomEvent(withName: "Background Response")
        backgroundSubject.onNext(())
        break
      case .measure:
        consoleLog(TAG, "measure resp (1/2)")
        currentMeasurement = MeasurementData()
        currentMeasurement!.pH = fromBytes([UInt8](bytes[1...4]), Float32.self)
        currentMeasurement!.temp = fromBytes([UInt8](bytes[5...8]), Float32.self)
        currentMeasurement!.dark = fromBytes([UInt8](bytes[9...12]), Float32.self)
        Answers.logCustomEvent(
            withName: "Measure Response",
            customAttributes: [
              "pH": NSNumber(value: currentMeasurement!.pH),
              "temp": NSNumber(value: currentMeasurement!.temp),
              "dark": NSNumber(value: currentMeasurement!.dark)
            ]
        )
        break
      case .measure2:
        consoleLog(TAG, "measure resp (2/2)")
        guard var measurement = currentMeasurement else { return }
        measurement.a578 = fromBytes([UInt8](bytes[1...4]), Float32.self)
        measurement.a434 = fromBytes([UInt8](bytes[5...8]), Float32.self)
        measurement.s578 = fromBytes([UInt8](bytes[9...12]), Float32.self)
        measurement.s434 = fromBytes([UInt8](bytes[13...16]), Float32.self)
        measureSubject.onNext(measurement)
        break
      case .ledIntensityCheck:
        Answers.logCustomEvent(withName: "LED Intensity Check Response")
        consoleLog(TAG, "led intensity check resp")
        break
      case .error:
        Answers.logCustomEvent(withName: "Error Response")
        consoleLog(TAG, "err resp")
        emitErrorAndResetSubjects(InstrumentError.commandError)
        break
    }
  }
}

extension CBPhyterInstrument {
  /// Notify this instance that the backing peripheral has been disconnected.
  func notifyDisconnected() {
    consoleLog(TAG, "received disconnect notification")
    ioInitialized = false
    sppService = nil
    txRxCharacteristic = nil
    runAfterIOInit = nil
    currentMeasurement = nil
    emitErrorAndResetSubjects(InstrumentError.disconnected)
  }
}

func toBytes<T>(_ value: T) -> [UInt8] {
  var mv: T = value
  let size  = MemoryLayout<T>.size
  return withUnsafePointer(to: &mv, {
    $0.withMemoryRebound(to: UInt8.self, capacity: size, {
      Array(UnsafeBufferPointer(start: $0, count: size))
    })
  })
}

func fromBytes<T>(_ value: [UInt8], _: T.Type) -> T {
  return value.withUnsafeBufferPointer({
    $0.baseAddress!.withMemoryRebound(to: T.self, capacity: 1, {
      $0.pointee
    })
  })
}
