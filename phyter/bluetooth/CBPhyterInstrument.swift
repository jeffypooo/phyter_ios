//
// Created by Jefferson Jones on 5/28/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation
import CoreBluetooth

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
  
  let peripheral:   CBPeripheral
  var lastReadRssi: NSNumber
  
  init(_ peripheral: CBPeripheral, rssi: NSNumber) {
    self.peripheral = peripheral
    peripheral.state
    self.lastReadRssi = rssi;
  }
}

extension CBPhyterInstrument: CBPeripheralDelegate {
  public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
    self.lastReadRssi = RSSI
  }
}
