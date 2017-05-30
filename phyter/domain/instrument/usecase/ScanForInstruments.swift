//
// Created by Jefferson Jones on 5/28/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation
import Dispatch

class ScanForInstrumentsArgs: UseCaseArgs {
  let duration: TimeInterval
  
  init(duration: TimeInterval = 10.0) {
    self.duration = duration
  }
}

class ScanForInstrumentsUpdate: UseCaseUpdate {
  let instrument: PhyterInstrument
  
  init(_ instrument: PhyterInstrument) {
    self.instrument = instrument
  }
}

enum ScanForInstrumentsError: Error {
  case alreadyScanning
}

class ScanForInstruments: OngoingUseCase<ScanForInstrumentsArgs, ScanForInstrumentsUpdate, UseCaseResult>, InstrumentManagerDelegate {
  
  var manager: InstrumentManager
  var isExecuting = false;
  var updateCallback:  ((ScanForInstrumentsUpdate) -> Void)?
  var successCallback: ((UseCaseResult) -> Void)?
  
  init(_ manager: InstrumentManager) {
    self.manager = manager
  }
  
  open override func execute(
      _ args: ScanForInstrumentsArgs?,
      onUpdate: @escaping (ScanForInstrumentsUpdate) -> Void,
      onSuccess: @escaping (UseCaseResult) -> Void = { _ in },
      onError: @escaping (Error) -> Void = { _ in }) {
    guard !isExecuting else {
      onError(ScanForInstrumentsError.alreadyScanning)
      return
    }
    guard let duration = args?.duration else {
      onError(UseCaseError.argsRequired)
      return
    }
    updateCallback = onUpdate
    successCallback = onSuccess
    manager.delegate = self
    manager.scanForInstruments()
    let ms = Int(round(duration * 1000.0))
    DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(ms)) {
      onSuccess(UseCaseResult())
      self.terminate()
    }
  }
  
  open override func terminate() {
    guard isExecuting else { return }
    manager.stopScanForInstruments()
    successCallback = nil
    updateCallback = nil
    manager.delegate = nil
    isExecuting = false
  }
  
  func instrumentManager(didDiscoverInstrument instrument: PhyterInstrument) {
    updateCallback?(ScanForInstrumentsUpdate(instrument))
  }
}
