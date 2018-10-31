//
// Created by Jefferson Jones on 6/17/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation
import RxSwift

class DisconnectInstrumentArgs: UseCaseArgs {
  let instrument: PhyterInstrument
  
  init(_ instrument: PhyterInstrument) {
    self.instrument = instrument
  }
}

class DisconnectInstrument: OneShotUseCase<DisconnectInstrumentArgs, UseCaseResult> {
  
  let manager:        InstrumentManager
  var disconnectSubs: DisposeBag!
  
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
    disconnectSubs = DisposeBag()
    manager.disconnect(fromInstrument: inst)
        .subscribe(onCompleted: { onSuccess(.empty) }, onError: { onError($0) })
        .disposed(by: disconnectSubs)
  }
}
