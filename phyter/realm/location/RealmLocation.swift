//
// Created by Jeff Jones on 7/22/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation
import RealmSwift

class RealmLocation: RealmObjectHelper, Location {
  var latitude: Double {
    var val: Double!
    runOnMainQueue {
      val = _lat
    }
    return val
  }
  var longitude: Double {
    var val: Double!
    runOnMainQueue {
      val = _lon
    }
    return val
  }
  var altitude: Double {
    var val: Double!
    runOnMainQueue {
      val = _alt
    }
    return val
  }
  var horizontalAccuracy: Double {
    var val: Double!
    runOnMainQueue {
      val = _hA
    }
    return val
  }
  var verticalAccuracy: Double {
    var val: Double!
    runOnMainQueue {
      val = _vA
    }
    return val
  }
  var timestamp: Date {
    var val: Date!
    runOnMainQueue {
      val = _ts
    }
    return val
  }

  dynamic var _lat: Double = 0
  dynamic var _lon: Double = 0
  dynamic var _alt: Double = 0
  dynamic var _hA:  Double = 0
  dynamic var _vA:  Double = 0
  dynamic var _ts:  Date   = Date()

  open override class func ignoredProperties() -> [String] {
    return ["latitude", "longitude", "altitude", "horizontalAccuracy", "verticalAccuracy", "timestamp"]
  }
}
