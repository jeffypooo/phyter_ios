//
// Created by Jefferson Jones on 5/28/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation
import RxSwift

class ConnectInstrumentArgs: UseCaseArgs {
  let toConnect: PhyterInstrument
  
  init(toConnect: PhyterInstrument) {
    self.toConnect = toConnect
  }
}

class ConnectInstrument: OneShotUseCase<ConnectInstrumentArgs, UseCaseResult> {
  
  let manager:     InstrumentManager
  var connectSubs: DisposeBag!
  
  init(_ manager: InstrumentManager) {
    self.manager = manager
  }
  
  open override func execute(
      _ args: ConnectInstrumentArgs?,
      onSuccess: @escaping (UseCaseResult) -> Void,
      onError: @escaping (Error) -> Void) {
    guard let inst = args?.toConnect else {
      onError(UseCaseError.argsRequired)
      return
    }
    connectSubs = DisposeBag()
    manager.connect(toInstrument: inst)
        .subscribe(onCompleted: { onSuccess(.empty) }, onError: { onError($0) })
        .disposed(by: connectSubs)
  }
}
