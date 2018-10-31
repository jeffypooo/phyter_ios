//
// Created by Jefferson Jones on 7/22/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation
import RxSwift
import CoreLocation

fileprivate let TAG = "CLLocationController"

class CLLocationController: NSObject, LocationController {
  var locationAccessAuthorized: Bool {
    return CLLocationManager.authorizationStatus() == .authorizedWhenInUse
  }
  
  var distanceBetweenUpdates: Int {
    get {
      return Int(clManager.distanceFilter)
    }
    set {
      clManager.distanceFilter = Double(newValue)
    }
  }
  
  var location: Observable<Location> {
    return locationSubject
  }
  
  fileprivate let authSubject:     PublishSubject<Bool>    = PublishSubject()
  fileprivate let locationSubject: ReplaySubject<Location> = ReplaySubject.create(bufferSize: 1)
  private let     clManager                                = CLLocationManager()
  
  override init() {
    super.init()
    clManager.distanceFilter = 3
    clManager.delegate = self
  }
  
  deinit {
    consoleLog(TAG, "deinit: cleaning up")
    self.stopUpdates()
    self.authSubject.onCompleted()
    self.locationSubject.onCompleted()
  }
  
  func requestLocationAccess() -> Observable<Bool> {
    guard !locationAccessAuthorized else {
      consoleLog(TAG, "requestLocationAccess: already authorized")
      return Observable.just(true)
    }
    consoleLog(TAG, "requesting authorization")
    clManager.requestWhenInUseAuthorization()
    return authSubject
  }
  
  func startUpdates() {
    guard locationAccessAuthorized else {
      consoleLog(TAG, "can't start updates, not authorized")
      return
    }
    consoleLog(TAG, "starting location updates")
    clManager.startUpdatingLocation()
  }
  
  func stopUpdates() {
    guard locationAccessAuthorized else {
      consoleLog(TAG, "can't stop updates, not authorized")
      return
    }
    consoleLog(TAG, "stopping location updates")
    clManager.stopUpdatingLocation()
  }
  
}

extension CLLocationController: CLLocationManagerDelegate {
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//    consoleLog(TAG, "locations updated: \(locations.last!)")
    let mostRecent = CLLocationWrapper(clLocation: locations.last!)
    locationSubject.onNext(mostRecent)
  }
  
  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    consoleLog(TAG, "authorization status changed: \(status)")
    authSubject.onNext(status == .authorizedWhenInUse)
  }
  
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    consoleLog(TAG, "CLLocationManager encountered an error: \(error)")
  }
}

fileprivate class CLLocationWrapper: Location {
  var latitude:           Double {
    return clLocation.coordinate.latitude
  }
  var longitude:          Double {
    return clLocation.coordinate.longitude
  }
  var altitude:           Double {
    return clLocation.altitude
  }
  var horizontalAccuracy: Double {
    return clLocation.horizontalAccuracy
  }
  var verticalAccuracy:   Double {
    return clLocation.verticalAccuracy
  }
  var timestamp:          Date {
    return clLocation.timestamp
  }
  
  fileprivate let clLocation: CLLocation
  
  init(clLocation: CLLocation) {
    self.clLocation = clLocation
  }
  
}
