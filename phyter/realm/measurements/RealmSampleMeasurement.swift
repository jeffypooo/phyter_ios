//
// Created by Jefferson Jones on 5/29/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation

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
  var dark: Float32 {
    get {
      var d: Float32!
      runOnMainQueue {
        d = Float32(_dark)
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
  
  dynamic var _instIdStr: String = ""
  dynamic var _timestamp: Date   = Date()
  dynamic var _sal:       Double = 0
  dynamic var _pH:        Double = 0
  dynamic var _temp:      Double = 0
  dynamic var _dark:      Double = 0
  dynamic var _a578:      Double = 0
  dynamic var _a434:      Double = 0
  
  open override class func ignoredProperties() -> [String] {
    return ["instrumentId", "timestamp", "salinity", "pH", "temperature", "dark", "a578", "a434"]
  }
  
}
