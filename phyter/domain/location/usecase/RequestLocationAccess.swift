//
// Created by Jefferson Jones on 7/22/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation
import RxSwift

class RequestLocationAccessUpdate: UseCaseUpdate {
  let authorized: Bool
  
  init(_ authorized: Bool) {
    self.authorized = authorized
  }
}

class RequestLocationAccess: OngoingLocationUseCase<UseCaseArgs, RequestLocationAccessUpdate, UseCaseResult> {
  
  private var sub: Disposable?
  
  override func execute(
      _ args: UseCaseArgs?,
      onUpdate: @escaping (RequestLocationAccessUpdate) -> Void,
      onSuccess: @escaping (UseCaseResult) -> Void,
      onError: @escaping (Error) -> Void) {
    self.sub = controller.requestLocationAccess().subscribe {
      event in
      if let auth = event.element {
        onUpdate(RequestLocationAccessUpdate(auth))
        self.terminate()
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
  }
}
