//
// Created by Jeff Jones on 7/4/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation

class CBWrapper {

  static let shared = CBWrapper()
  
  private var stubManager: InstrumentManager?

  private init() {
  }

  func instrumentManager() -> InstrumentManager {
    if let stub = stubManager { return stub }
    return CBInstrumentManager.shared
  }

  func stubManager(_ manager: InstrumentManager) {
    stubManager = manager
  }

}
