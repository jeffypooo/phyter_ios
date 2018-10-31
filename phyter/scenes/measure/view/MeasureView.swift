//
// Created by Jefferson Jones on 5/29/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation

enum ExportFormat {
  case csv
}

enum MeasureViewAction {
  case salinityChange(Float32)
  case actionButtonPress
  case measurementClick(SampleMeasurement)
  case measurementDelete(SampleMeasurement)
  case share
  case export(ExportFormat)
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
  func measureView(showMeasurementDetails measurement: SampleMeasurement)
  func measureViewShowExportOptions()
  func measureView(showSharingOptionsForFile: URL)
  func measureView(showErrorAlert message: String)
  
}
