//
// Created by Jefferson Jones on 5/29/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation

class MeasureResult: UseCaseResult {
  let pH:   Float32
  let temp: Float32
  
  init(_ pH: Float32, temp: Float32) {
    self.pH = pH
    self.temp = temp
  }
}

class Measure: InstrumentUseCase<UseCaseArgs, MeasureResult> {
  open override func execute(
      _ args: UseCaseArgs?,
      onSuccess: @escaping (MeasureResult) -> Void,
      onError: @escaping (Error) -> Void) {
    instrument.measure { pH, temp in onSuccess(MeasureResult(pH, temp: temp)) }
  }
}
