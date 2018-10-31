//
// Created by Jefferson Jones on 5/29/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation
import RxSwift

class Background: InstrumentUseCase<UseCaseArgs, UseCaseResult> {
  
  var bag: DisposeBag! = DisposeBag()
  
  open override func execute(
      _ args: UseCaseArgs?,
      onSuccess: @escaping (UseCaseResult) -> Void,
      onError: @escaping (Error) -> Void) {
    if let inst = instrumentProvider() {
      inst.background()
          .timeout(5.0, scheduler: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
          .subscribe(
              onCompleted: { onSuccess(UseCaseResult()) },
              onError: { onError($0) }
          )
          .disposed(by: bag)
    } else {
      onError(InstrumentUseCaseError.noInstrument)
    }
  }
}
