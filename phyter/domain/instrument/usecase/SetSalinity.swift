//
// Created by Jefferson Jones on 5/29/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation
import RxSwift

class SetSalinityArgs: UseCaseArgs {
  let salinity: Float32
  
  init(salinity: Float32) {
    self.salinity = salinity
  }
}

class SetSalinity: InstrumentUseCase<SetSalinityArgs, UseCaseResult> {
  
  open override func execute(
      _ args: SetSalinityArgs?,
      onSuccess: @escaping (UseCaseResult) -> Void,
      onError: @escaping (Error) -> Void) {
    guard let sal = args?.salinity else {
      onError(UseCaseError.argsRequired)
      return
    }
    if let inst = instrumentProvider() {
      inst.setSalinity(sal)
      onSuccess(UseCaseResult())
    } else {
      onError(InstrumentUseCaseError.noInstrument)
    }
  }
}
