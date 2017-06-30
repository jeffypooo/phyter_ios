//
// Created by Jefferson Jones on 6/29/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation

class DeleteMeasurementArgs: UseCaseArgs {
  let measurement: SampleMeasurement
  
  init(measurement: SampleMeasurement) {
    self.measurement = measurement
  }
}

enum DeleteMeasurementError: Error {
  case deletionFailed
}


class DeleteMeasurement: MeasurementRepositoryUseCase<DeleteMeasurementArgs, UseCaseResult> {
  open override func execute(
      _ args: DeleteMeasurementArgs?,
      onSuccess: @escaping (UseCaseResult) -> Void,
      onError: @escaping (Error) -> Void) {
    guard let measurement = args?.measurement else {
      onError(UseCaseError.argsRequired)
      return
    }
    let res = repo.delete(measurement: measurement)
    if res {
      onSuccess(UseCaseResult())
    } else {
      onError(DeleteMeasurementError.deletionFailed)
    }
  }
}
