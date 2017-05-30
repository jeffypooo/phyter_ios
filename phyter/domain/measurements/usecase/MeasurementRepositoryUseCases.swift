//
// Created by Jefferson Jones on 5/29/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation

class MeasurementRepositoryOngoingUseCase<A:UseCaseArgs, U:UseCaseUpdate, R:UseCaseResult>: OngoingUseCase<A, U, R> {
  
  let repo: MeasurementRepository
  
  init(_ repo: MeasurementRepository) {
    self.repo = repo
  }
  
}

class MeasurementRepositoryUseCase<A:UseCaseArgs, R:UseCaseResult>: OneShotUseCase<A, R> {
  
  let repo: MeasurementRepository
  
  init(_ repo: MeasurementRepository) {
    self.repo = repo
  }
  
}