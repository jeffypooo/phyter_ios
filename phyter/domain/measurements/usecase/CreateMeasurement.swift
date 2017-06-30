//
// Created by Jefferson Jones on 5/29/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation

class CreateMeasurementArgs: UseCaseArgs {
  let instrumentId: UUID
  let salinity:     Float32
  let pH:           Float32
  let temp:         Float32
  let dark:         Float32
  let a578:         Float32
  let a434:         Float32
  
  init(
      instrumentId: UUID,
      salinity: Float32,
      pH: Float32,
      temp: Float32,
      dark: Float32,
      a578: Float32,
      a434: Float32
  ) {
    self.instrumentId = instrumentId
    self.salinity = salinity
    self.pH = pH
    self.temp = temp
    self.dark = dark
    self.a578 = a578
    self.a434 = a434
  }
}

class CreateMeasurementResult: UseCaseResult {
  let measurement: SampleMeasurement
  
  init(_ measurement: SampleMeasurement) {
    self.measurement = measurement
  }
}

class CreateMeasurement: MeasurementRepositoryUseCase<CreateMeasurementArgs, CreateMeasurementResult> {
  open override func execute(
      _ args: CreateMeasurementArgs?,
      onSuccess: @escaping (CreateMeasurementResult) -> Void,
      onError: @escaping (Error) -> Void) {
    guard let args = args else {
      onError(UseCaseError.argsRequired)
      return
    }
    let measurement = repo.createMeasurement(
        instrumentId: args.instrumentId,
        salinity: args.salinity,
        pH: args.pH,
        temp: args.temp,
        dark: args.dark,
        a578: args.a578,
        a434: args.a434
    )
    onSuccess(CreateMeasurementResult(measurement))
  }
}
