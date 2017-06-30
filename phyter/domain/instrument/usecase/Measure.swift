//
// Created by Jefferson Jones on 5/29/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation

class MeasureResult: UseCaseResult {
  let data: MeasurementData
  
  init(_ data: MeasurementData) {
    self.data = data
  }
}

class Measure: InstrumentUseCase<UseCaseArgs, MeasureResult> {
  open override func execute(
      _ args: UseCaseArgs?,
      onSuccess: @escaping (MeasureResult) -> Void,
      onError: @escaping (Error) -> Void) {
    if let inst = instrumentProvider() {
      inst.measure { data in onSuccess(MeasureResult(data)) }
    } else {
      onError(InstrumentUseCaseError.noInstrument)
    }
  }
}
