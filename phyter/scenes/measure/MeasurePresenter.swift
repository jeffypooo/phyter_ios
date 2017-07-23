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
  let disconnectInstrument:          DisconnectInstrument
}

class MeasurePresenter {

  private let useCases:              MeasureUseCases
  private var currentActionStyle:    MeasureViewActionButtonStyle = .background
  private var view:                  MeasureView?
  private var instrument:            PhyterInstrument?
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
    logMsg("view disappeared")
    view = nil
    disconnect()
    stopLocationUpdates()
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
        self?.logMsg("starting location updates")
        self?.useCases.locationUpdates.execute(
            nil,
            onUpdate: { update in self?.locationUpdated(update: update.location) },
            onSuccess: { _ in },
            onError: { error in self?.logMsg("error during location updates: \(error)") }
        )
      } else {
        self?.logMsg("location access denied")
      }
    }
  }

  private func checkLocationAccess(_ cb: @escaping (Bool) -> Void) {
    logMsg("checking location access")
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
    logMsg("location updated")
    self.currentLocation = update
  }

  private func stopLocationUpdates() {
    logMsg("terminating location updates")
    useCases.locationUpdates.terminate()
  }

  private func setSalinity(_ sal: Float32) {
    logMsg("setting salinity to \(sal)")
    let args = SetSalinityArgs(salinity: sal)
    viewShowSalinityActivity(true)
    useCases.setSalinity.execute(
        args,
        onSuccess: {
          _ in
          self.logMsg("salinity set")
        },
        onError: {
          error in
          self.logMsg("error setting salinity: \(error)")
        })
  }

  private func observeSalinity() {
    logMsg("observing salinity")
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
    logMsg("performing background")
    viewEnableActionButton(false)
    viewShowActionButtonActivity(true)
    useCases.background.execute(nil, onSuccess: {
      _ in
      self.logMsg("background complete")
      self.viewEnableActionButton(true)
      self.viewShowActionButtonActivity(false)
      self.viewSetActionButtonStyle(.measure)
    }, onError: { _ in self.logMsg("error during background") })
  }

  private func measure() {
    logMsg("measuring...")
    viewEnableActionButton(false)
    viewShowActionButtonActivity(true)
    useCases.measure.execute(
        nil,
        onSuccess: {
          result in
          self.logMsg("pH = \(result.data.pH), temp = \(result.data.temp)")
          self.viewEnableActionButton(true)
          self.viewShowActionButtonActivity(false)
          self.viewSetActionButtonStyle(.background)
          self.createMeasurement(fromResult: result)
        },
        onError: { _ in self.logMsg("error during measurement") }
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
        a434: data.a434,
        location: currentLocation
    )
    useCases.createMeasurement.execute(
        args,
        onSuccess: {
          result in
          self.logMsg("created new measurement")
        },
        onError: {
          error in
          self.logMsg("error creating new measurement: \(error)")
        }
    )
  }

  private func deleteMeasurement(_ measurement: SampleMeasurement) {
    let args = DeleteMeasurementArgs(measurement: measurement)
    useCases.deleteMeasurement.execute(
        args,
        onSuccess: {
          result in
          self.logMsg("measurement deleted")
        },
        onError: {
          error in
          self.logMsg("error deleting measurement: \(error)")
        }
    )
  }

  private func observeInstrumentMeasurements() {
    logMsg("observing measurements")
    guard let instrumentId = self.instrument?.id else { return }
    let args = ObserveInstrumentMeasurementsArgs(instrumentId: instrumentId)
    useCases.observeInstrumentMeasurements.execute(
        args,
        onUpdate: {
          update in
          self.lastMeasurementsQuery = update.liveQuery
          self.viewUpdateMeasurementHistory(update.liveQuery)
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
    print("exporting to CSV file")
    guard let instName = instrument?.name, let data = lastMeasurementsQuery?.results else {
      print("missing required fields for export!")
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
          print("file exported to \(res.fileURL)")
          self.viewShowSharingOptions(file: res.fileURL)
        },
        onError: { error in print("error exporting \(error.localizedDescription)") }
    )
  }

  private func disconnect() {
    guard let inst = instrument else { return }
    useCases.disconnectInstrument.execute(
        DisconnectInstrumentArgs(inst),
        onSuccess: {
          result in
          self.logMsg("instrument disconnected")
          self.instrument = nil
        },
        onError: {
          error in
          self.logMsg("error disconnecting instrument")
          self.instrument = nil
        }
    )
  }

  private func defaultConfigureView() {
    logMsg("configuring default view values")
    viewSetInstrumentName(instrument?.name)
    viewSetSalinityText("35.0")
    viewSetActionButtonStyle(.background)
  }

  private func viewSetInstrumentName(_ name: String?) {
    logMsg("setting instrument name '\(String(describing: name))'")
    view?.measureView(setInstrumentName: name)
  }

  private func viewSetSalinityText(_ text: String?) {
    logMsg("setting salinity text '\(text ?? " ")'")
    view?.measureView(setSalinityFieldText: text)
  }

  private func viewShowSalinityActivity(_ show: Bool) {
    view?.measureView(showSalinityActivity: show)
  }

  private func viewSetActionButtonStyle(_ style: MeasureViewActionButtonStyle) {
    logMsg("setting action button style: \(style)")
    currentActionStyle = style
    view?.measureView(setActionButtonStyle: style)
  }

  private func viewEnableActionButton(_ enable: Bool) {
    logMsg("enabling action button: \(enable)")
    view?.measureView(enableActionButton: enable)
  }

  private func viewShowActionButtonActivity(_ show: Bool) {
    logMsg("showing action button activity: \(show)")
    view?.measureView(showActionButtonActivity: show)
  }

  private func viewUpdateMeasurementHistory(_ query: MeasurementLiveQuery) {
    logMsg("updating measurement history (\(query.results.count) items)")
    view?.measureView(updateMeasurementHistory: query)
  }

  private func viewShowMeasurementDetails(_ measurement: SampleMeasurement) {
    logMsg("showing measurement details for \(measurement)")
    view?.measureView(showMeasurementDetails: measurement)
  }

  private func viewShowExportOptions() {
    print("showing sharing options")
    view?.measureViewShowExportOptions()
  }

  private func viewShowSharingOptions(file: URL) {
    print("showing sharing options for file '\(file.lastPathComponent)'")
    view?.measureView(showSharingOptionsForFile: file)
  }

}

extension MeasurePresenter {
  fileprivate func logMsg(_ msg: String) {
    print("MeasurePresenter - \(msg)")
  }
}
