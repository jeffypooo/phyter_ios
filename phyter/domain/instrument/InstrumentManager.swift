//
// Created by Jefferson Jones on 5/28/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation
import RxSwift

protocol InstrumentManagerDelegate {
  func instrumentManager(didDiscoverInstrument instrument: PhyterInstrument)
}

protocol InstrumentManager {
  
  var delegate: InstrumentManagerDelegate? { get set }
  
  func scanForInstruments()
  func stopScanForInstruments()
  func connect(toInstrument instrument: PhyterInstrument) -> Completable
  func disconnect(fromInstrument instrument: PhyterInstrument) -> Completable
  
}
