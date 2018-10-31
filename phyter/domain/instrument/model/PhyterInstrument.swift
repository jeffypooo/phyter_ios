//
// Created by Jefferson Jones on 5/28/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation
import RxSwift

enum InstrumentError: Error {
  case disconnected
  case commandError
}

struct MeasurementData {
  var pH:   Float32 = 0
  var temp: Float32 = 0
  var s578: Float32 = 0
  var s434: Float32 = 0
  var a578: Float32 = 0
  var a434: Float32 = 0
  var dark: Float32 = 0
}

protocol PhyterInstrument {
  var id:        UUID { get }
  var name:      String { get }
  var rssi:      Int { get }
  var connected: Bool { get }
  
  var salinity: Observable<Float32> { get }
  
  func setSalinity(_ salinity: Float32)
  func background() -> Completable
  func measure() -> Single<MeasurementData>
  
}



