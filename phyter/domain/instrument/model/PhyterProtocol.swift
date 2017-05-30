//
// Created by Jefferson Jones on 5/29/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation

enum Command: UInt8 {
  case setSalinity       = 0x1
  case background        = 0x2
  case measure           = 0x3
  case ledIntensityCheck = 0x4
}

enum Response: UInt8 {
  case setSalinity       = 0x81
  case background        = 0x82
  case measure           = 0x83
  case ledIntensityCheck = 0x84
  case error             = 0xFF
}


