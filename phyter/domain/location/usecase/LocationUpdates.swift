//
// Created by Jefferson Jones on 7/22/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation
import RxSwift

class LocationUpdatesUpdate: UseCaseUpdate {
  let location: Location
  
  init(_ location: Location) {
    self.location = location
  }
}

class LocationUpdates: OngoingLocationUseCase<UseCaseArgs, LocationUpdatesUpdate, UseCaseResult> {
  
  private var sub: Disposable?
  
  override func execute(
      _ args: UseCaseArgs?,
      onUpdate: @escaping (LocationUpdatesUpdate) -> Void,
      onSuccess: @escaping (UseCaseResult) -> Void,
      onError: @escaping (Error) -> Void) {
    controller.startUpdates()
    self.sub = controller.location.subscribe {
      event in
      if let loc = event.element {
        onUpdate(LocationUpdatesUpdate(loc))
      } else if let err = event.error {
        onError(err)
        self.terminate()
      } else if event.isCompleted {
        onSuccess(UseCaseResult())
        self.terminate()
      }
    }
  }
  
  override func terminate() {
    super.terminate()
    self.sub?.dispose()
    controller.stopUpdates()
  }
}
