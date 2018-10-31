//
// Created by Jefferson Jones on 5/29/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation
import RxSwift

class MeasureResult: UseCaseResult {
  let data: MeasurementData
  
  init(_ data: MeasurementData) {
    self.data = data
  }
}

class Measure: InstrumentUseCase<UseCaseArgs, MeasureResult> {
  
  var bag: DisposeBag! = DisposeBag()
  
  open override func execute(
      _ args: UseCaseArgs?,
      onSuccess: @escaping (MeasureResult) -> Void,
      onError: @escaping (Error) -> Void) {
    if let inst = instrumentProvider() {
      inst.measure()
          .subscribe(
              onSuccess: { onSuccess(MeasureResult($0)) },
              onError: { onError($0) }
          )
          .disposed(by: bag)
    } else {
      onError(InstrumentUseCaseError.noInstrument)
    }
  }
}
