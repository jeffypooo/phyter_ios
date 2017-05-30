//
// Created by Jefferson Jones on 5/28/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation
import CoreBluetooth
import RxSwift

class CBPhyterInstrument: NSObject, PhyterInstrument {
  var id: UUID {
    return peripheral.identifier
  }
  
  var name: String {
    return peripheral.name ?? "N/A"
  }
  
  var rssi: Int {
    return Int(lastReadRssi)
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
  var ioInitialized                                    = false
  var sppService:         CBService?
  var txRxCharacteristic: CBCharacteristic?
  var runAfterIOInit:     (() -> Void)?
  var backgroundHandlers: [() -> Void]                 = []
  var measureHandlers:    [(Float32, Float32) -> Void] = []
  
  init(_ peripheral: CBPeripheral, rssi: NSNumber) {
    self.peripheral = peripheral
    self.lastReadRssi = rssi;
    super.init()
    self.peripheral.delegate = self
  }
  
  func setSalinity(_ salinity: Float32) {
    if !ioInitialized {
      runAfterIOInit = {
        self.setSalinity(salinity)
      }
      lazyInitializeIO()
      return
    }
    sendSetSalinityCommand(salinity)
  }
  
  func background(onComplete: @escaping () -> Void) {
    if !ioInitialized {
      runAfterIOInit = {
        self.background(onComplete: onComplete)
      }
      lazyInitializeIO()
      return
    }
    backgroundHandlers.append(onComplete)
    sendBackgroundCommand()
  }
  
  func measure(onComplete: @escaping (Float32, Float32) -> Void) {
    if !ioInitialized {
      runAfterIOInit = {
        self.measure(onComplete: onComplete)
      }
      lazyInitializeIO()
      return
    }
    measureHandlers.append(onComplete)
    sendMeasureCommand()
  }
  
  private func lazyInitializeIO() {
    guard peripheral.state == .connected else { return }
    print("lazy initializing IO...")
    peripheral.discoverServices([PHYTER_SPP_SERVICE_UUID])
  }
  
  private func sendSetSalinityCommand(_ sal: Float32) {
    print("sending set salinity cmd")
    var data: [UInt8] = [Command.setSalinity.rawValue]
    data.append(contentsOf: toBytes(sal))
    guard let txRx = self.txRxCharacteristic else { return }
    peripheral.writeValue(Data(bytes: data), for: txRx, type: .withoutResponse)
  }
  
  private func sendBackgroundCommand() {
    print("sending background cmd")
    guard let txRx = self.txRxCharacteristic else { return }
    peripheral.writeValue(Data(bytes: [Command.background.rawValue]), for: txRx, type: .withoutResponse)
  }
  
  private func sendMeasureCommand() {
    print("sending measure cmd")
    guard let txRx = self.txRxCharacteristic else { return }
    peripheral.writeValue(Data(bytes: [Command.measure.rawValue]), for: txRx, type: .withoutResponse)
  }
  
  
}

extension CBPhyterInstrument: CBPeripheralDelegate {
  
  public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
    self.lastReadRssi = RSSI
  }
  
  public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    if let sppService = peripheral.services?.first(where: { service in service.uuid == PHYTER_SPP_SERVICE_UUID }) {
      print("discovered SPP service...")
      self.sppService = sppService
      peripheral.discoverCharacteristics([PHYTER_SPP_TX_RX_UUID], for: sppService)
    }
    
  }
  
  public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
    if let txRx = service.characteristics?.first(where: { char in char.uuid == PHYTER_SPP_TX_RX_UUID }) {
      print("discovered TX/RX characteristic")
      self.txRxCharacteristic = txRx
      peripheral.setNotifyValue(true, for: txRx)
      ioInitialized = true
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
      print("salinity resp: \(sal)")
      salinitySubject.onNext(sal)
      break
    case .background:
      print("background resp")
      guard backgroundHandlers.count > 0 else { break }
      let handler = backgroundHandlers.removeFirst()
      handler()
      break
    case .measure:
      print("measure resp")
      guard measureHandlers.count > 0 else { break }
      let handler = measureHandlers.removeFirst()
      let pH      = fromBytes([UInt8](bytes[1...4]), Float32.self)
      let temp    = fromBytes([UInt8](bytes.suffix(4)), Float32.self)
      handler(pH, temp)
      break
    case .ledIntensityCheck:
      print("led intensity check resp")
      break
    case .error:
      print("err resp")
      break
    }
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
