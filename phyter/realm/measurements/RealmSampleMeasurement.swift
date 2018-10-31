//
// Created by Jefferson Jones on 5/29/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation
import RealmSwift

class RealmSampleMeasurement: RealmObjectHelper, SampleMeasurement {
  var instrumentId: UUID {
    get {
      var id: UUID!
      runOnMainQueue {
        id = UUID(uuidString: _instIdStr) ?? UUID()
      }
      return id
    }
    set {
      writeSafely {
        self._instIdStr = newValue.uuidString
      }
    }
  }
  var timestamp: Date {
    get {
      var date: Date!
      runOnMainQueue {
        date = Date(timeIntervalSince1970: _timestamp.timeIntervalSince1970)
      }
      return date
    }
    set {
      writeSafely {
        self._timestamp = newValue
      }
    }
  }
  var salinity: Float32 {
    get {
      var sal: Float32!
      runOnMainQueue {
        sal = Float32(self._sal)
      }
      return sal
    }
    set {
      writeSafely {
        self._sal = Double(newValue)
      }
    }
  }
  var pH: Float32 {
    get {
      var ph: Float32!
      runOnMainQueue {
        ph = Float32(self._pH)
      }
      return ph
    }
    set {
      writeSafely {
        self._pH = Double(newValue)
      }
    }
  }
  var temperature: Float32 {
    get {
      var temp: Float32!
      runOnMainQueue {
        temp = Float32(self._temp)
      }
      return temp
    }
    set {
      writeSafely {
        self._temp = Double(newValue)
      }
    }
  }
  var s578: Float32 {
    get {
      var s: Float32!
      runOnMainQueue { s = Float32(_s578) }
      return s
    }
    set {
      writeSafely { self._s578 = Double(newValue) }
    }
  }
  var s434: Float32 {
    get {
      var s: Float32!
      runOnMainQueue { s = Float32(_s434) }
      return s
    }
    set {
      writeSafely { self._s434 = Double(newValue) }
    }
  }
  var dark: Float32 {
    get {
      var d: Float32!
      runOnMainQueue {
        d = Float32(self._dark)
      }
      return d
    }
    set {
      writeSafely {
        self._dark = Double(newValue)
      }
    }
  }
  
  var a578: Float32 {
    get {
      var a: Float32!
      runOnMainQueue {
        a = Float32(_a578)
      }
      return a
    }
    set {
      writeSafely {
        self._a578 = Double(newValue)
      }
    }
  }
  var a434: Float32 {
    get {
      var a: Float32!
      runOnMainQueue {
        a = Float32(_a434)
      }
      return a
    }
    set {
      writeSafely {
        self._a434 = Double(newValue)
      }
    }
  }
  var location: Location? {
    get {
      var val: Location?
      runOnMainQueue {
        val = _loc
      }
      return val
    }
    set {
      writeSafely {
        if let rlmLoc = newValue as? RealmLocation {
          self._loc = rlmLoc
        } else if let loc = newValue {
          let rlmLoc = RealmLocation()
          rlmLoc._lat = loc.latitude
          rlmLoc._lon = loc.longitude
          rlmLoc._alt = loc.altitude
          rlmLoc._hA = loc.horizontalAccuracy
          rlmLoc._vA = loc.verticalAccuracy
          rlmLoc._ts = loc.timestamp
          self._loc = rlmLoc
        } else {
          self._loc = nil
        }
      }
    }
  }
  @objc dynamic var _instIdStr: String = ""
  @objc dynamic var _timestamp: Date   = Date()
  @objc dynamic var _sal:       Double = 0
  @objc dynamic var _pH:        Double = 0
  @objc dynamic var _temp:      Double = 0
  @objc dynamic var _dark:      Double = 0
  @objc dynamic var _s578:      Double = 0
  @objc dynamic var _s434:      Double = 0
  @objc dynamic var _a578:      Double = 0
  @objc dynamic var _a434:      Double = 0
  @objc dynamic var _loc:       RealmLocation?
  
  open override class func ignoredProperties() -> [String] {
    return ["instrumentId", "timestamp", "salinity", "pH", "temperature", "dark", "s578", "s434", "a578", "a434", "location"]
  }
  
}
