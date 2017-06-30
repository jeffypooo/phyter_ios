//
// Created by Jefferson Jones on 5/29/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation


enum InstrumentUseCaseError: Error {
  case noInstrument
}

class InstrumentUseCase<A:UseCaseArgs, R:UseCaseResult>: OneShotUseCase<A, R> {
  
  let instrumentProvider: () -> PhyterInstrument?
  
  init(_ provider: @escaping () -> PhyterInstrument?) {
    self.instrumentProvider = provider
  }
  
}

class InstrumentOngoingUseCase<A:UseCaseArgs, U:UseCaseUpdate, R:UseCaseResult>: OngoingUseCase<A, U, R> {
  
  let instrumentProvider: () -> PhyterInstrument?
  
  init(_ provider: @escaping () -> PhyterInstrument?) {
    self.instrumentProvider = provider
  }
  
  
}