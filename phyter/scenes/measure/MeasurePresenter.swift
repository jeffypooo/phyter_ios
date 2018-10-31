//
// Created by Jefferson Jones on 5/29/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation

struct MeasureUseCases {
  let requestLocationAccess:         RequestLocationAccess
  let locationUpdates:               LocationUpdates
  let setSalinity:                   SetSalinity
  let observeSalinity:               ObserveSalinity
  let background:                    Background
  let measure:                       Measure
  let createMeasurement:             CreateMeasurement
  let deleteMeasurement:             DeleteMeasurement
  let observeInstrumentMeasurements: ObserveInstrumentMeasurements
  let exportToCSV:                   ExportToCSV
  let connectInstrument:             ConnectInstrument
  let disconnectInstrument:          DisconnectInstrument
}

fileprivate let TAG = "MeasurePresenter"

class MeasurePresenter {
  
  private let useCases:              MeasureUseCases
  private var currentActionStyle:    MeasureViewActionButtonStyle = .background
  private var view:                  MeasureView?
  private var instrument:            PhyterInstrument!
  private var lastMeasurementsQuery: MeasurementLiveQuery?
  private var currentLocation:       Location?
  private var currentSalinity:       Float32                      = 35.0
  
  init(withUseCases useCases: MeasureUseCases) {
    self.useCases = useCases
  }
  
  func viewDidLoad(_ view: MeasureView) {
    self.view = view
  }
  
  func viewDidAppear(_ instrument: PhyterInstrument) {
    self.instrument = instrument
    startLocationUpdates()
    defaultConfigureView()
    observeSalinity()
    observeInstrumentMeasurements()
  }
  
  func viewDidDisappear() {
    consoleLog(TAG, "view disappeared")
    view = nil
    disconnect()
    stopLocationUpdates()
    useCases.observeSalinity.terminate()
    useCases.observeInstrumentMeasurements.terminate()
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
      case .share:
        viewShowExportOptions()
        break
      case .export(let format):
        exportMeasurements(format)
        break
    }
  }
  
  private func startLocationUpdates() {
    checkLocationAccess {
      [weak self] auth in
      if auth {
        consoleLog(TAG, "starting location updates")
        self?.useCases.locationUpdates.execute(
            nil,
            onUpdate: { update in self?.locationUpdated(update: update.location) },
            onSuccess: { _ in },
            onError: { consoleLog(TAG, "error during location updates: \($0)") }
        )
      } else {
        consoleLog(TAG, "location access denied")
      }
    }
  }
  
  private func checkLocationAccess(_ cb: @escaping (Bool) -> Void) {
    consoleLog(TAG, "checking location access")
    useCases.requestLocationAccess.execute(
        nil,
        onUpdate: {
          update in
          cb(update.authorized)
        },
        onSuccess: { _ in },
        onError: {
          error in
          cb(false)
        }
    )
  }
  
  private func locationUpdated(update: Location) {
    consoleLog(TAG, "location updated")
    self.currentLocation = update
  }
  
  private func stopLocationUpdates() {
    consoleLog(TAG, "terminating location updates")
    useCases.locationUpdates.terminate()
  }
  
  private func setSalinity(_ sal: Float32) {
    consoleLog(TAG, "setting salinity to \(sal)")
    let args = SetSalinityArgs(salinity: sal)
    viewShowSalinityActivity(true)
    useCases.setSalinity.execute(
        args,
        onSuccess: {
          _ in
          consoleLog(TAG, "salinity set")
        },
        onError: {
          error in
          consoleLog(TAG, "error setting salinity: \(error)")
        })
  }
  
  private func observeSalinity() {
    consoleLog(TAG, "observing salinity")
    useCases.observeSalinity.execute(
        nil,
        onUpdate: {
          [weak self] update in
          self?.currentSalinity = update.salinity
          self?.viewShowSalinityActivity(false)
          self?.viewSetSalinityText(String(format: "%.2f", arguments: [update.salinity]))
        },
        onSuccess: { result in },
        onError: { error in }
    )
  }
  
  private func actionButtonPressed() {
    switch currentActionStyle {
      case .background:
        guard let instrument = self.instrument else { break }
        if !instrument.connected {
          reconnectAndPerformBackground()
        } else {
          background()
        }
        break
      case .measure:
        measure()
        break
    }
  }
  
  private func reconnectAndPerformBackground() {
    viewEnableActionButton(false)
    viewShowActionButtonActivity(true)
    let args = ConnectInstrumentArgs(toConnect: instrument)
    useCases.connectInstrument.execute(
        args,
        onSuccess: { [weak self] _ in self?.background() },
        onError: { consoleLog(TAG, "error re-connecting instrument: \($0)") }
    )
  }
  
  private func background() {
    consoleLog(TAG, "performing background")
    viewEnableActionButton(false)
    viewShowActionButtonActivity(true)
    useCases.background.execute(
        nil,
        onSuccess: { [weak self] _ in self?.backgroundCompleted() },
        onError: { [weak self] err in self?.backgroundFailed(err) }
    )
  }
  
  private func backgroundFailed(_ err: Error) {
    consoleLog(TAG, "error during background: \(err)")
    view?.measureView(showErrorAlert: "An error occurred during the background process. Please try again.")
    viewEnableActionButton(true)
    viewShowActionButtonActivity(false)
  }
  
  private func backgroundCompleted() {
    consoleLog(TAG, "background complete")
    self.viewEnableActionButton(true)
    self.viewShowActionButtonActivity(false)
    self.viewSetActionButtonStyle(.measure)
  }
  
  private func measure() {
    consoleLog(TAG, "measuring...")
    viewEnableActionButton(false)
    viewShowActionButtonActivity(true)
    useCases.measure.execute(
        nil,
        onSuccess: { [weak self] res in self?.measureSucceeded(res) },
        onError: { [weak self] err in self?.measureFailed(err) }
    )
  }
  
  private func measureFailed(_ err: Error) {
    consoleLog(TAG, "error during measurement: \(err)")
    viewEnableActionButton(true)
    viewShowActionButtonActivity(false)
    view?.measureView(showErrorAlert: "An error occurred during the measurement.")
  }
  
  private func measureSucceeded(_ result: MeasureResult) {
    consoleLog(TAG, "pH = \(result.data.pH), temp = \(result.data.temp)")
    viewEnableActionButton(true)
    viewShowActionButtonActivity(false)
    viewSetActionButtonStyle(.background)
    createMeasurement(fromResult: result)
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
        a434: data.a434,
        location: currentLocation
    )
    useCases.createMeasurement.execute(
        args,
        onSuccess: { _ in consoleLog(TAG, "created new measurement") },
        onError: { consoleLog(TAG, "error creating new measurement: \($0)") }
    )
  }
  
  private func deleteMeasurement(_ measurement: SampleMeasurement) {
    let args = DeleteMeasurementArgs(measurement: measurement)
    useCases.deleteMeasurement.execute(
        args,
        onSuccess: {
          result in
          consoleLog(TAG, "measurement deleted")
        },
        onError: {
          error in
          consoleLog(TAG, "error deleting measurement: \(error)")
        }
    )
  }
  
  private func observeInstrumentMeasurements() {
    consoleLog(TAG, "observing measurements")
    guard let instrumentId = self.instrument?.id else { return }
    let args = ObserveInstrumentMeasurementsArgs(instrumentId: instrumentId)
    useCases.observeInstrumentMeasurements.execute(
        args,
        onUpdate: { [weak self] update in
          self?.lastMeasurementsQuery = update.liveQuery
          self?.viewUpdateMeasurementHistory(update.liveQuery)
        },
        onSuccess: { _ in },
        onError: { _ in }
    )
  }
  
  private func exportMeasurements(_ format: ExportFormat) {
    switch format {
      case .csv:
        exportMeasurementsToCSV()
        break
    }
  }
  
  private func exportMeasurementsToCSV() {
    consoleLog(TAG, "exporting to CSV file")
    guard let instName = instrument?.name, let data = lastMeasurementsQuery?.results else {
      consoleLog(TAG, "missing required fields for export!")
      return
    }
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy_MM_dd_hh_mm_ss"
    let fileName = dateFormatter.string(from: Date()) + "-\(instName)"
    let args     = ExportToCSVArgs(data: data, fileName: fileName)
    useCases.exportToCSV.execute(
        args,
        onSuccess: {
          res in
          consoleLog(TAG, "file exported to \(res.fileURL)")
          self.viewShowSharingOptions(file: res.fileURL)
        },
        onError: { error in consoleLog(TAG, "error exporting \(error.localizedDescription)") }
    )
  }
  
  private func disconnect() {
    guard let inst = instrument else { return }
    useCases.disconnectInstrument.execute(
        DisconnectInstrumentArgs(inst),
        onSuccess: {
          result in
          consoleLog(TAG, "instrument disconnected")
          self.instrument = nil
        },
        onError: {
          error in
          consoleLog(TAG, "error disconnecting instrument")
          self.instrument = nil
        }
    )
  }
  
  private func defaultConfigureView() {
    consoleLog(TAG, "configuring default view values")
    viewSetInstrumentName(instrument?.name)
    viewSetSalinityText("35.0")
    viewSetActionButtonStyle(.background)
  }
  
  private func viewSetInstrumentName(_ name: String?) {
    consoleLog(TAG, "setting instrument name '\(String(describing: name))'")
    view?.measureView(setInstrumentName: name)
  }
  
  private func viewSetSalinityText(_ text: String?) {
    consoleLog(TAG, "setting salinity text '\(text ?? " ")'")
    view?.measureView(setSalinityFieldText: text)
  }
  
  private func viewShowSalinityActivity(_ show: Bool) {
    view?.measureView(showSalinityActivity: show)
  }
  
  private func viewSetActionButtonStyle(_ style: MeasureViewActionButtonStyle) {
    consoleLog(TAG, "setting action button style: \(style)")
    currentActionStyle = style
    view?.measureView(setActionButtonStyle: style)
  }
  
  private func viewEnableActionButton(_ enable: Bool) {
    consoleLog(TAG, "enabling action button: \(enable)")
    view?.measureView(enableActionButton: enable)
  }
  
  private func viewShowActionButtonActivity(_ show: Bool) {
    consoleLog(TAG, "showing action button activity: \(show)")
    view?.measureView(showActionButtonActivity: show)
  }
  
  private func viewUpdateMeasurementHistory(_ query: MeasurementLiveQuery) {
    consoleLog(TAG, "updating measurement history (\(query.results.count) items)")
    view?.measureView(updateMeasurementHistory: query)
  }
  
  private func viewShowMeasurementDetails(_ measurement: SampleMeasurement) {
    consoleLog(TAG, "showing measurement details for \(measurement)")
    view?.measureView(showMeasurementDetails: measurement)
  }
  
  private func viewShowExportOptions() {
    consoleLog(TAG, "showing sharing options")
    view?.measureViewShowExportOptions()
  }
  
  private func viewShowSharingOptions(file: URL) {
    consoleLog(TAG, "showing sharing options for file '\(file.lastPathComponent)'")
    view?.measureView(showSharingOptionsForFile: file)
  }
  
}


