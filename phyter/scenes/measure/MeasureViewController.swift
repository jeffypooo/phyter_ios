//
// Created by Jefferson Jones on 5/29/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation
import UIKit
import Dispatch

class MeasureViewController: UIViewController {

  @IBOutlet weak var instrumentNameLabel:           UILabel!
  @IBOutlet weak var salinityField:                 UITextField!
  @IBOutlet weak var salinityActivityIndicator:     UIActivityIndicatorView!
  @IBOutlet weak var actionButton:                  UIButton!
  @IBOutlet weak var actionButtonActivityIndicator: UIActivityIndicatorView!
  @IBOutlet weak var measurementHistoryTable:       UITableView!

  lazy var presenter: MeasurePresenter = {
    let repo               = RealmMeasurementRepository()
    let exporter           = DocumentsFileExporter()
    let locationController = CLLocationController()
    let useCases = MeasureUseCases(
        requestLocationAccess: RequestLocationAccess(controller: locationController),
        locationUpdates: LocationUpdates(controller: locationController),
        setSalinity: SetSalinity { self.instrument },
        observeSalinity: ObserveSalinity { self.instrument },
        background: Background { self.instrument },
        measure: Measure { self.instrument },
        createMeasurement: CreateMeasurement(repo),
        deleteMeasurement: DeleteMeasurement(repo),
        observeInstrumentMeasurements: ObserveInstrumentMeasurements(repo),
        exportToCSV: ExportToCSV(exporter),
        disconnectInstrument: DisconnectInstrument(CBInstrumentManager.shared)
    )
    return MeasurePresenter(withUseCases: useCases)
  }()

  var instrument:   PhyterInstrument!
  var measurements: [SampleMeasurement]?

  open override func viewDidLoad() {
    super.viewDidLoad()
    print("CURRENT DIR: \(FileManager.default.currentDirectoryPath)")
    configureViews()
    presenter.viewDidLoad(self)
  }

  open override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    presenter.viewDidAppear(instrument)
  }

  open override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    presenter.viewDidDisappear()
  }

  open override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }

  @IBAction func didPressActionButton(_ sender: Any) {
    presenter.didPerform(action: .actionButtonPress)
  }

  func didPressShareButton(_ sender: Any) {
    presenter.didPerform(action: .share)
  }

  func cancelSalinityInput() {
    salinityField.resignFirstResponder()
  }

  func confirmSalinityInput() {
    salinityField.resignFirstResponder()
    let salinity = Float32(salinityField.text ?? "") ?? 35.0
    presenter.didPerform(action: .salinityChange(salinity))
  }

  private func configureViews() {
    configureShareButton()
    configureSalinityField()
  }

  private func configureShareButton() {
    navigationItem.rightBarButtonItem = UIBarButtonItem(
        barButtonSystemItem: .action,
        target: self,
        action: #selector(didPressShareButton(_:))
    )
  }

  private func configureSalinityField() {
    let toolBar    = UIToolbar()
    let cancelItem = UIBarButtonItem(
        title: "Cancel",
        style: .plain,
        target: self,
        action: #selector(cancelSalinityInput)
    )
    let middleItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    let doneItem   = UIBarButtonItem(
        title: "Done",
        style: .done,
        target: self,
        action: #selector(confirmSalinityInput)
    )
    toolBar.items = [cancelItem, middleItem, doneItem]
    toolBar.sizeToFit()
    salinityField.inputAccessoryView = toolBar
  }

}

extension MeasureViewController: MeasureView {

  func measureView(setInstrumentName name: String?) {
    DispatchQueue.main.async {
      self.instrumentNameLabel.text = name
    }
  }

  func measureView(setSalinityFieldText text: String?) {
    DispatchQueue.main.async {
      self.salinityField.text = text
    }
  }

  func measureView(showSalinityActivity show: Bool) {
    DispatchQueue.main.async {
      if show {
        self.salinityActivityIndicator.startAnimating()
      } else {
        self.salinityActivityIndicator.stopAnimating()
      }
    }
  }

  func measureView(setActionButtonStyle style: MeasureViewActionButtonStyle) {
    DispatchQueue.main.async {
      switch style {
        case .background:
          self.actionButton.setTitle("Background", for: .normal)
          break
        case .measure:
          self.actionButton.setTitle("Measure", for: .normal)
          break
      }
    }
  }

  func measureView(enableActionButton enable: Bool) {
    DispatchQueue.main.async {
      self.actionButton.isEnabled = enable
      UIView.animate(withDuration: 0.2) {
        self.actionButton.alpha = enable ? 1.0 : 0.5
      }
    }
  }

  func measureView(showActionButtonActivity show: Bool) {
    DispatchQueue.main.async {
      if show {
        self.actionButtonActivityIndicator.startAnimating()
      } else {
        self.actionButtonActivityIndicator.stopAnimating()
      }
    }
  }

  func measureView(updateMeasurementHistory query: MeasurementLiveQuery) {
    DispatchQueue.main.async {
      if self.measurements == nil {
        self.measurements = query.results
        self.measurementHistoryTable.reloadData()
        return
      }
      self.measurementHistoryTable.beginUpdates()
      self.measurements = query.results
      let delPaths = query.deletions.map { i -> IndexPath in IndexPath(row: i, section: 0) }
      let insPaths = query.insertions.map { i -> IndexPath in IndexPath(row: i, section: 0) }
      let modsPaths = query.modifications.map { i -> IndexPath in IndexPath(row: i, section: 0) }
      self.measurementHistoryTable.deleteRows(at: delPaths, with: .left)
      self.measurementHistoryTable.insertRows(at: insPaths, with: .left)
      self.measurementHistoryTable.reloadRows(at: modsPaths, with: .none)
      self.measurementHistoryTable.endUpdates()
    }
  }

  func measureView(showMeasurementDetails measurement: SampleMeasurement) {
    DispatchQueue.main.async {
      let dateFormatter = DateFormatter()
      dateFormatter.dateStyle = .short
      dateFormatter.timeStyle = .short
      let dataStr = String(
          format: "Created: %@\npH: %.3f\nTemp: %.2f\nSalinity: %.2f",
          arguments: [
            dateFormatter.string(from: measurement.timestamp),
            measurement.pH,
            measurement.temperature,
            measurement.salinity
          ]
      )
      var locStr: String!
      if let location = measurement.location {
        locStr = String(
            format: "Lat/Long: %.5f/%.5f\nAltitude: %.1fm",
            arguments: [location.latitude, location.longitude, location.altitude]
        )
      } else {
        locStr = "N/A"
      }
      let diagStr = String(
          format: "A578: %.4f\nA434: %.4f\nDark: %.4f",
          arguments: [measurement.a578, measurement.a434, measurement.dark]
      )
      let message = String(format: "%@\n\nLocation:\n\n%@\n\nDiagnostic:\n\n%@", arguments: [dataStr, locStr, diagStr])
      let alert   = UIAlertController(title: "Measurement Details", message: message, preferredStyle: .alert)
      let ok      = UIAlertAction(title: "OK", style: .default, handler: nil)
      alert.addAction(ok)
      self.present(alert, animated: true)
    }
  }

  func measureViewShowExportOptions() {
    DispatchQueue.main.async {
      let alert = UIAlertController(
          title: "Export Measurements",
          message: "Choose an export format",
          preferredStyle: .actionSheet
      )
      let csv = UIAlertAction(title: "CSV", style: .default) {
        [weak self] action in
        self?.presenter.didPerform(action: .export(.csv))
      }
      let cancel = UIAlertAction(title: "Cancel", style: .cancel)
      alert.addAction(csv)
      alert.addAction(cancel)
      self.present(alert, animated: true)
    }
  }

  func measureView(showSharingOptionsForFile file: URL) {
    DispatchQueue.main.async {
      let shareController = UIActivityViewController(activityItems: [file], applicationActivities: nil)
      self.present(shareController, animated: true)
    }
  }
}

extension MeasureViewController: UITableViewDataSource {
  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return measurements?.count ?? 0
  }

  public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: "measurement_cell") as? SampleMeasurementCell else {
      return UITableViewCell()
    }
    cell.bind(toMeasurement: measurements![indexPath.row])
    return cell
  }

  public func tableView(
      _ tableView: UITableView,
      commit editingStyle: UITableViewCellEditingStyle,
      forRowAt indexPath: IndexPath) {
    guard let sample = measurements?[indexPath.row] else {
      print("error - no measurements")
      return
    }
    presenter.didPerform(action: .measurementDelete(sample))
  }
}

extension MeasureViewController: UITableViewDelegate {
  public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    guard let sample = measurements?[indexPath.row] else { return }
    presenter.didPerform(action: .measurementClick(sample))
  }
}


