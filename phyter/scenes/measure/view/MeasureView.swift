//
// Created by Jefferson Jones on 5/29/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation

enum MeasureViewAction {
  case salinityChange(Float32)
  case actionButtonPress
}

enum MeasureViewActionButtonStyle {
  case background
  case measure
}

protocol MeasureView {
  
  func measureView(setInstrumentName name: String?)
  func measureView(setSalinityFieldText text: String?)
  func measureView(showSalinityActivity show: Bool)
  func measureView(setActionButtonStyle style: MeasureViewActionButtonStyle)
  func measureView(enableActionButton enable: Bool)
  func measureView(showActionButtonActivity show: Bool)
  func measureView(updateMeasurementHistory query: MeasurementLiveQuery)
  
}
