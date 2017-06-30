//
// Created by Jefferson Jones on 5/28/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation

struct StartUseCases {
  let scanForInstruments: ScanForInstruments
  let connectInstrument:  ConnectInstrument
}

class StartPresenter {
  
  private let useCases:              StartUseCases
  private var view:                  StartView?
  private var discoveredInstruments: [PhyterInstrument] = []
  
  init(withUseCases useCases: StartUseCases) {
    self.useCases = useCases
  }
  
  func viewDidLoad(_ view: StartView) {
    self.view = view
  }
  
  func viewDidAppear() {
    scanForInstruments()
  }
  
  func viewDidDisappear() {
    discoveredInstruments.removeAll()
    useCases.scanForInstruments.terminate()
  }
  
  func didPerform(action: StartViewAction) {
    switch action {
    case .refresh:
      scanForInstruments()
      break
    case .instrumentSelect(let instrument):
      connectInstrument(instrument)
      break
    }
  }
  
  private func scanForInstruments() {
    viewSetRefreshing(true)
    useCases.scanForInstruments.execute(
        ScanForInstrumentsArgs(),
        onUpdate: {
          update in
          self.instrumentDiscovered(update.instrument)
        },
        onSuccess: {
          result in
          self.viewSetRefreshing(false)
        }
    )
  }
  
  private func instrumentDiscovered(_ inst: PhyterInstrument) {
    guard !discoveredInstruments.contains(where: { elem in inst.id == elem.id }) else { return }
    discoveredInstruments.append(inst)
    viewAddInstrument(inst)
  }
  
  private func connectInstrument(_ instrument: PhyterInstrument) {
    let args = ConnectInstrumentArgs(toConnect: instrument)
    useCases.connectInstrument.execute(
        args,
        onSuccess: {
          _ in
          print("connected to \(instrument.name)")
          self.viewPerformSegue(.measure(instrument))
        },
        onError: {
          error in
          print("error connecting to \(instrument.name): \(error)")
        }
    )
  }
  
  private func viewSetRefreshing(_ refreshing: Bool) {
    view?.startView(setRefreshing: refreshing)
  }
  
  private func viewAddInstrument(_ instrument: PhyterInstrument) {
    view?.startView(addInstrument: instrument)
  }
  
  private func viewPerformSegue(_ segue: StartViewSegue) {
    view?.startView(performSegue: segue)
  }
  
}
