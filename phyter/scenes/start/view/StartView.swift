//
// Created by Jefferson Jones on 5/28/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation

enum StartViewAction {
  case refresh
  case instrumentSelect(PhyterInstrument)
}

enum StartViewSegue {
  case measure(PhyterInstrument)
}

protocol StartView {
  func startView(setRefreshing refreshing: Bool)
  func startView(addInstrument: PhyterInstrument)
  func startView(showConnectingAlert instrument: PhyterInstrument)
  func startView(showConnectionErrorAlert instrument: PhyterInstrument)
  func startView(performSegue segue: StartViewSegue)
}
