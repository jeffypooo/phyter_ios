//
// Created by Jefferson Jones on 5/29/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation

class Background: InstrumentUseCase<UseCaseArgs, UseCaseResult> {
  open override func execute(
      _ args: UseCaseArgs?,
      onSuccess: @escaping (UseCaseResult) -> Void,
      onError: @escaping (Error) -> Void) {
    instrument.background {
      onSuccess(UseCaseResult())
    }
  }
}
