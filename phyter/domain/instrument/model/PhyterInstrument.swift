//
// Created by Jefferson Jones on 5/28/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation
import RxSwift

struct MeasurementData {
  var pH:   Float32 = 0
  var temp: Float32 = 0
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
  func background(onComplete: @escaping () -> Void)
  func measure(onComplete: @escaping (_ data: MeasurementData) -> Void)
  
}



