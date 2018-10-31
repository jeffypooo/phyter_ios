//
// Created by Jefferson Jones on 5/28/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation

open class UseCaseArgs {
}
open class UseCaseUpdate {
}
open class UseCaseResult {
  
  static let empty = UseCaseResult()
}

enum UseCaseError: Error {
  case argsRequired
}

open class OneShotUseCase<A:UseCaseArgs, R:UseCaseResult> {
  
  
  open func execute(
      _ args: A?,
      onSuccess: @escaping (R) -> Void = { _ in },
      onError: @escaping (Error) -> Void = { _ in }) {
    
  }
  
}

open class OngoingUseCase<A:UseCaseArgs, U:UseCaseUpdate, R:UseCaseResult> {
  
  open func execute(
      _ args: A?,
      onUpdate: @escaping (U) -> Void = { _ in },
      onSuccess: @escaping (R) -> Void = { _ in },
      onError: @escaping (Error) -> Void = { _ in }) {
    
  }
  
  open func terminate() {
  
  }
}