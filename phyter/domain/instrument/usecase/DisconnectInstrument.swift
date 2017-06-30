//
// Created by Jefferson Jones on 6/17/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation

class DisconnectInstrumentArgs: UseCaseArgs {
  let instrument: PhyterInstrument
  
  init(_ instrument: PhyterInstrument) {
    self.instrument = instrument
  }
}

class DisconnectInstrument: OneShotUseCase<DisconnectInstrumentArgs, UseCaseResult> {
  
  let manager: InstrumentManager
  
  init(_ manager: InstrumentManager) {
    self.manager = manager
  }
  
  open override func execute(
      _ args: DisconnectInstrumentArgs?,
      onSuccess: @escaping (UseCaseResult) -> Void,
      onError: @escaping (Error) -> Void) {
    guard let inst = args?.instrument else {
      onError(UseCaseError.argsRequired)
      return
    }
    manager.disconnect(fromInstrument: inst) {
      maybeErr in
      if let err = maybeErr {
        onError(err)
      } else {
        onSuccess(UseCaseResult())
      }
    }
  }
}
