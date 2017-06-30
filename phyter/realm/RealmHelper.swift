//
// Created by Jefferson Jones on 5/29/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift
import Dispatch

class RealmHelper {
  
  private var realmInstance: Realm
  
  init() {
    var config = Realm.Configuration()
    config.deleteRealmIfMigrationNeeded = true
    self.realmInstance = try! Realm(configuration: config)
  }
  
  func onRealm(_ block: (Realm) -> Void) {
    if Thread.isMainThread {
      block(realmInstance)
    } else {
      DispatchQueue.main.sync {
        block(realmInstance)
      }
    }
  }
  
}
