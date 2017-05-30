//
// Created by Jefferson Jones on 5/29/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation
import RxSwift

class ObserveSalinityUpdate: UseCaseUpdate {
  let salinity: Float32
  
  init(_ salinity: Float32) {
    self.salinity = salinity
  }
}

class ObserveSalinity: InstrumentOngoingUseCase<UseCaseArgs, ObserveSalinityUpdate, UseCaseResult> {
  
  var salinitySubs: Disposable?
  
  open override func execute(
      _ args: UseCaseArgs?,
      onUpdate: @escaping (ObserveSalinityUpdate) -> Void,
      onSuccess: @escaping (UseCaseResult) -> Void,
      onError: @escaping (Error) -> Void) {
    terminate()
    salinitySubs = instrument.salinity.subscribe(onNext: { sal in onUpdate(ObserveSalinityUpdate(sal)) })
  }
  
  open override func terminate() {
    salinitySubs?.dispose()
  }
}
