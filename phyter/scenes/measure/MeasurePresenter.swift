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
  let deleteMeasurement:             DeleteMeasurement
  let observeInstrumentMeasurements: ObserveInstrumentMeasurements
  let disconnectInstrument:          DisconnectInstrument
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
    print("view disappeared")
    view = nil
    disconnect()
  }
  
  func didPerform(action: MeasureViewAction) {
    switch action {
    case .salinityChange(let sal):
      setSalinity(sal)
      break
    case .actionButtonPress:
      actionButtonPressed()
      break
    case .measurementClick(let measurement):
      viewShowMeasurementDetails(measurement)
      break
    case .measurementDelete(let measurement):
      deleteMeasurement(measurement)
      break
    }
  }
  
  private func setSalinity(_ sal: Float32) {
    print("setting salinity to \(sal)")
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
    print("observing salinity")
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
    print("performing background")
    viewEnableActionButton(false)
    viewShowActionButtonActivity(true)
    useCases.background.execute(nil, onSuccess: {
      _ in
      print("background complete")
      self.viewEnableActionButton(true)
      self.viewShowActionButtonActivity(false)
      self.viewSetActionButtonStyle(.measure)
    }, onError: { _ in print("error during background") })
  }
  
  private func measure() {
    print("measuring...")
    viewEnableActionButton(false)
    viewShowActionButtonActivity(true)
    useCases.measure.execute(
        nil,
        onSuccess: {
          result in
          print("pH = \(result.data.pH), temp = \(result.data.temp)")
          self.viewEnableActionButton(true)
          self.viewShowActionButtonActivity(false)
          self.viewSetActionButtonStyle(.background)
          self.createMeasurement(fromResult: result)
        },
        onError: { _ in print("error during measurement") }
    )
  }
  
  private func createMeasurement(fromResult result: MeasureResult) {
    guard let instrumentId = instrument?.id else { return }
    let data = result.data
    let args = CreateMeasurementArgs(
        instrumentId: instrumentId,
        salinity: currentSalinity,
        pH: data.pH,
        temp: data.temp,
        dark: data.dark,
        a578: data.a578,
        a434: data.a434
    )
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
  
  private func deleteMeasurement(_ measurement: SampleMeasurement) {
    let args = DeleteMeasurementArgs(measurement: measurement)
    useCases.deleteMeasurement.execute(
        args,
        onSuccess: {
          result in
          print("measurement deleted")
        },
        onError: {
          error in
          print("error deleting measurement: \(error)")
        }
    )
  }
  
  private func observeInstrumentMeasurements() {
    print("observing measurements")
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
  
  private func disconnect() {
    guard let inst = instrument else { return }
    useCases.disconnectInstrument.execute(
        DisconnectInstrumentArgs(inst),
        onSuccess: {
          result in
          print("instrument disconnected")
          self.instrument = nil
        },
        onError: {
          error in
          print("error disconnecting instrument")
          self.instrument = nil
        }
    )
  }
  
  private func defaultConfigureView() {
    print("configuring default view values")
    viewSetInstrumentName(instrument?.name)
    viewSetSalinityText("35.0")
    viewSetActionButtonStyle(.background)
  }
  
  private func viewSetInstrumentName(_ name: String?) {
    print("setting instrument name '\(String(describing: name))'")
    view?.measureView(setInstrumentName: name)
  }
  
  private func viewSetSalinityText(_ text: String?) {
    print("setting salinity text '\(text ?? " ")'")
    view?.measureView(setSalinityFieldText: text)
  }
  
  private func viewShowSalinityActivity(_ show: Bool) {
    view?.measureView(showSalinityActivity: show)
  }
  
  private func viewSetActionButtonStyle(_ style: MeasureViewActionButtonStyle) {
    print("setting action button style: \(style)")
    currentActionStyle = style
    view?.measureView(setActionButtonStyle: style)
  }
  
  private func viewEnableActionButton(_ enable: Bool) {
    print("enabling action button: \(enable)")
    view?.measureView(enableActionButton: enable)
  }
  
  private func viewShowActionButtonActivity(_ show: Bool) {
    print("showing action button activity: \(show)")
    view?.measureView(showActionButtonActivity: show)
  }
  
  private func viewUpdateMeasurementHistory(_ query: MeasurementLiveQuery) {
    print("updating measurement history (\(query.results.count) items)")
    view?.measureView(updateMeasurementHistory: query)
  }
  
  private func viewShowMeasurementDetails(_ measurement: SampleMeasurement) {
    print("showing measurement details for \(measurement)")
    view?.measureView(showMeasurementDetails: measurement)
  }
  
}
