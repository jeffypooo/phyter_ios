//
// Created by Jefferson Jones on 5/28/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation

protocol PhyterInstrument {
  var id:        UUID { get }
  var name:      String { get }
  var rssi:      Int { get }
  var connected: Bool { get }
  
  
}



