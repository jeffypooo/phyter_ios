//
// Created by Jefferson Jones on 5/29/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation

struct MeasureUseCases {
  let setSalinity:                   SetSalinity
  let observeSalinity:               ObserveSalinity
  let background:                    Background
  let measure:                       Measure
  let createMeasurement:             CreateMeasurement
  let observeInstrumentMeasurements: ObserveInstrumentMeasurements
}

class MeasurePresenter {
  
  private let useCases:           MeasureUseCases
  private var currentActionStyle: MeasureViewActionButtonStyle = .background
  private var view:               MeasureView?
  private var instrument:         PhyterInstrument?
  private var currentSalinity:    Float32                      = 35.0
  
  init(withUseCases useCases: MeasureUseCases) {
    self.useCases = useCases
  }
  
  func viewDidLoad(_ view: MeasureView) {
    self.view = view
  }
  
  func viewDidAppear(_ instrument: PhyterInstrument) {
    self.instrument = instrument
    defaultConfigureView()
    observeSalinity()
    observeInstrumentMeasurements()
  }
  
  func viewDidDisappear() {
  
  }
  
  func didPerform(action: MeasureViewAction) {
    switch action {
    case .salinityChange(let sal):
      setSalinity(sal)
      break
    case .actionButtonPress:
      actionButtonPressed()
      break
    }
  }
  
  private func setSalinity(_ sal: Float32) {
    let args = SetSalinityArgs(salinity: sal)
    viewShowSalinityActivity(true)
    useCases.setSalinity.execute(
        args,
        onSuccess: {
          _ in
          print("salinity set")
        },
        onError: {
          error in
          print("error setting salinity: \(error)")
        })
  }
  
  private func observeSalinity() {
    useCases.observeSalinity.execute(
        nil,
        onUpdate: {
          update in
          self.currentSalinity = update.salinity
          self.viewShowSalinityActivity(false)
          self.viewSetSalinityText(String(format: "%.2f", arguments: [update.salinity]))
        },
        onSuccess: { result in },
        onError: { error in }
    )
  }
  
  private func actionButtonPressed() {
    switch currentActionStyle {
    case .background:
      background()
      break
    case .measure:
      measure()
      break
    }
  }
  
  private func background() {
    viewEnableActionButton(false)
    viewShowActionButtonActivity(true)
    useCases.background.execute(nil, onSuccess: {
      _ in
      self.viewEnableActionButton(true)
      self.viewShowActionButtonActivity(false)
      self.viewSetActionButtonStyle(.measure)
    }, onError: { _ in })
  }
  
  private func measure() {
    viewEnableActionButton(false)
    viewShowActionButtonActivity(true)
    useCases.measure.execute(
        nil,
        onSuccess: {
          result in
          print("pH = \(result.pH), temp = \(result.temp)")
          self.viewEnableActionButton(true)
          self.viewShowActionButtonActivity(false)
          self.viewSetActionButtonStyle(.background)
          self.createMeasurement(pH: result.pH, temp: result.temp)
        },
        onError: { _ in }
    )
  }
  
  private func createMeasurement(pH: Float32, temp: Float32) {
    guard let instrumentId = instrument?.id else { return }
    let args = CreateMeasurementArgs(instrumentId: instrumentId, salinity: currentSalinity, pH: pH, temp: temp)
    useCases.createMeasurement.execute(
        args,
        onSuccess: {
          result in
          print("created new measurement")
        },
        onError: {
          error in
          print("error creating new measurement: \(error)")
        }
    )
  }
  
  private func observeInstrumentMeasurements() {
    guard let instrumentId = self.instrument?.id else { return }
    let args = ObserveInstrumentMeasurementsArgs(instrumentId: instrumentId)
    useCases.observeInstrumentMeasurements.execute(
        args,
        onUpdate: {
          update in
          self.viewUpdateMeasurementHistory(update.liveQuery)
        },
        onSuccess: { _ in },
        onError: { _ in }
    )
  }
  
  private func defaultConfigureView() {
    viewSetInstrumentName(instrument?.name)
    viewSetSalinityText("35.0")
    viewSetActionButtonStyle(.background)
  }
  
  private func viewSetInstrumentName(_ name: String?) {
    view?.measureView(setInstrumentName: name)
  }
  
  private func viewSetSalinityText(_ text: String?) {
    view?.measureView(setSalinityFieldText: text)
  }
  
  private func viewShowSalinityActivity(_ show: Bool) {
    view?.measureView(showSalinityActivity: show)
  }
  
  private func viewSetActionButtonStyle(_ style: MeasureViewActionButtonStyle) {
    currentActionStyle = style
    view?.measureView(setActionButtonStyle: style)
  }
  
  private func viewEnableActionButton(_ enable: Bool) {
    view?.measureView(enableActionButton: enable)
  }
  
  private func viewShowActionButtonActivity(_ show: Bool) {
    view?.measureView(showActionButtonActivity: show)
  }
  
  private func viewUpdateMeasurementHistory(_ query: MeasurementLiveQuery) {
    view?.measureView(updateMeasurementHistory: query)
  }
  
}
