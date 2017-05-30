//
// Created by Jefferson Jones on 5/29/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation
import RealmSwift
import Dispatch

class RealmObjectHelper: Object {
  
  func writeSafely(_ block: @escaping () -> Void) {
    runOnMainQueue {
      if let realm = self.realm {
        if realm.isInWriteTransaction {
          block()
        } else {
          try! realm.write {
            block()
          }
        }
      } else {
        block()
      }
    }
  }
  
  func runOnMainQueue(_ block: () -> Void) {
    if Thread.isMainThread {
      block()
    } else {
      DispatchQueue.main.sync {
        block()
      }
    }
  }
  
}
