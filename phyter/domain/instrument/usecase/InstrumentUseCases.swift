//
// Created by Jefferson Jones on 5/29/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation


class InstrumentUseCase<A:UseCaseArgs, R:UseCaseResult>: OneShotUseCase<A, R> {
  
  let instrument: PhyterInstrument
  
  init(_ instrument: PhyterInstrument) {
    self.instrument = instrument
  }
  
}

class InstrumentOngoingUseCase<A:UseCaseArgs, U:UseCaseUpdate, R:UseCaseResult>: OngoingUseCase<A, U, R> {
  
  let instrument: PhyterInstrument
  
  init(_ instrument: PhyterInstrument) {
    self.instrument = instrument
  }
  
  
}