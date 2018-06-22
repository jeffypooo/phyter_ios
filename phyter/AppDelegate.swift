//
//  AppDelegate.swift
//  phyter
//
//  Created by Jefferson Jones on 5/28/17.
//  Copyright © 2017 Jefferson Jones. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics
import RxSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  func application(
      _ application: UIApplication,
      didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    // Override point for customization after application launch.
    if ProcessInfo.processInfo.environment["DemoMode"] == "YES" {
      print("using stubbed instrument manager")
      CBWrapper.shared.stubManager(StubInstrumentManager())
    }
    Fabric.with([Crashlytics.self])
    return true
  }

  func applicationWillResignActive(_ application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
  }

  func applicationDidEnterBackground(_ application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
  }

  func applicationWillEnterForeground(_ application: UIApplication) {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
  }

  func applicationDidBecomeActive(_ application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  }

  func applicationWillTerminate(_ application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }

}

class StubInstrumentManager: InstrumentManager {
  var delegate: InstrumentManagerDelegate?

  func scanForInstruments() {
    let secs = Int(arc4random_uniform(5))
    delayAsync(seconds: secs) {
      self.delegate?.instrumentManager(didDiscoverInstrument: StubInstrument())
    }
  }

  func stopScanForInstruments() {
  }

  func connect(toInstrument instrument: PhyterInstrument, onComplete: @escaping (Error?) -> Void) {
    delayAsync {
      if let stub = instrument as? StubInstrument {
        stub.setConnected(true)
        onComplete(nil)
      }
    }
  }

  func disconnect(fromInstrument instrument: PhyterInstrument, onComplete: @escaping (Error?) -> Void) {
    delayAsync {
      if let stub = instrument as? StubInstrument {
        stub.setConnected(false)
        onComplete(nil)
      }
    }
  }

  private func delayAsync(seconds: Int = 1, _ block: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(seconds), execute: block)
  }
}

class StubInstrument: PhyterInstrument {
  private(set) var id:   UUID   = UUID(uuidString: "01365e28-dffc-4732-8efe-12ebc0eab862")!
  private(set) var name: String = "DemoInstrument"
  private(set) var rssi: Int    = -50
  var connected: Bool = false
  var salinity:  Observable<Float32> {
    get {
      return salinitySource
    }
  }

  var salinitySource: BehaviorSubject<Float32> = BehaviorSubject(value: 35)

  func setSalinity(_ salinity: Float32) {
    delayAsync { self.salinitySource.onNext(salinity) }
  }

  func background(onComplete: @escaping () -> Void) {
    delayAsync { onComplete() }
  }

  func measure(onComplete: @escaping (MeasurementData) -> Void) {
    delayAsync {
        let data = MeasurementData(pH: 7.9, temp: 74, s578: 1, s434: 1, a578: 1, a434: 1, dark: 1)
      onComplete(data)
    }
  }

  func setConnected(_ conn: Bool) {
    connected = conn
  }

  private func delayAsync(_ block: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: block)
  }
}

