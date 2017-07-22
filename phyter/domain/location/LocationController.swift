//
// Created by Jefferson Jones on 7/22/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation
import RxSwift


protocol LocationController {
  
  var locationAccessAuthorized: Bool { get }
  var distanceBetweenUpdates:   Int { get set }
  var location:                 Observable<Location> { get }
  
  func requestLocationAccess() -> Observable<Bool>
  func startUpdates()
  func stopUpdates()
  
}
