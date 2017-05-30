//
// Created by Jefferson Jones on 5/28/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation
import RxSwift

protocol PhyterInstrument {
  var id:        UUID { get }
  var name:      String { get }
  var rssi:      Int { get }
  var connected: Bool { get }
  
  var salinity: Observable<Float32> { get }
  
  func setSalinity(_ salinity: Float32)
  func background(onComplete: @escaping () -> Void)
  func measure(onComplete: @escaping (_ pH: Float32, _ temp: Float32) -> Void)
  
}



