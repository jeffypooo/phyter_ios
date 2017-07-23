//
// Created by Jefferson Jones on 7/22/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation

class OneShotLocationUseCase<A:UseCaseArgs, R:UseCaseResult>: OneShotUseCase<A, R> {
  
  let controller: LocationController
  
  init(controller: LocationController) {
    self.controller = controller
  }
  
}

class OngoingLocationUseCase<A:UseCaseArgs, U:UseCaseUpdate, R:UseCaseResult>: OngoingUseCase<A, U, R> {
  
  let controller: LocationController
  
  init(controller: LocationController) {
    self.controller = controller
  }
  
}
