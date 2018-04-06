//
//  StartViewController.swift
//  phyter
//
//  Created by Jefferson Jones on 5/28/17.
//  Copyright © 2017 Jefferson Jones. All rights reserved.
//

import UIKit
import CoreBluetooth
import Dispatch
import Crashlytics

extension UIRefreshControl {
  
  func beginRefreshingWithAnimation() {
    guard let tableView = getParentTableView() else { return }
    let offsetPoint = CGPoint(x: 0, y: tableView.contentOffset.y - self.frame.height)
    tableView.setContentOffset(offsetPoint, animated: true)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      self.beginRefreshing()
    }
  }
  
  private func getParentTableView() -> UITableView? {
    return superview as? UITableView
  }
  
}

class StartViewController: UIViewController {
  
  @IBOutlet weak var instrumentsTable: UITableView!
  
  lazy var refreshControl: UIRefreshControl = {
    let refreshControl = UIRefreshControl()
    refreshControl.tintColor = .white
    refreshControl.addTarget(self, action: #selector(didPullToRefresh(_:)), for: .valueChanged)
    return refreshControl
  }()
  
  lazy var presenter: StartPresenter = {
    let manager  = CBWrapper.shared.instrumentManager()
    let useCases = StartUseCases(
        scanForInstruments: ScanForInstruments(manager),
        connectInstrument: ConnectInstrument(manager)
    )
    return StartPresenter(withUseCases: useCases)
  }()
  
  var instruments: [PhyterInstrument] = []
  
  override func viewDidLoad() {
    super.viewDidLoad()
    configureTableView()
    presenter.viewDidLoad(self)
  }
  
  open override func viewDidAppear(_ animated: Bool) {
    refreshControl.beginRefreshingWithAnimation()
    refreshControl.endRefreshing()
    super.viewDidAppear(animated)
    presenter.viewDidAppear()
  }
  
  open override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    instruments.removeAll()
    instrumentsTable.reloadData()
    presenter.viewDidDisappear()
  }
  
  open override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    super.prepare(for: segue, sender: sender)
    if let senderSegue = sender as? StartViewSegue {
      switch senderSegue {
      case .measure(let instrument):
        (segue.destination as! MeasureViewController).instrument = instrument
        break
      }
    }
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  @objc func didPullToRefresh(_ sender: Any) {
    Answers.logCustomEvent(withName: "Pull to Refresh")
    presenter.didPerform(action: .refresh)
  }
  
  private func configureTableView() {
    instrumentsTable.refreshControl = refreshControl
    instrumentsTable.reloadData()
  }
  
}

extension StartViewController: StartView {
  
  func startView(setRefreshing refreshing: Bool) {
    DispatchQueue.main.async {
      if refreshing {
        self.refreshControl.layoutIfNeeded()
        self.refreshControl.beginRefreshingWithAnimation()
      } else {
        self.refreshControl.endRefreshing()
      }
    }
  }
  
  func startView(addInstrument instrument: PhyterInstrument) {
    DispatchQueue.main.async {
      let path = IndexPath(row: self.instruments.count, section: 0)
      self.instruments.append(instrument)
      self.instrumentsTable.insertRows(at: [path], with: .left)
    }
  }
  
  func startView(showConnectingAlert instrument: PhyterInstrument) {
  
  }
  
  func startView(showConnectionErrorAlert instrument: PhyterInstrument) {
  }
  
  func startView(performSegue segue: StartViewSegue) {
    DispatchQueue.main.async {
      self.performSegue(withIdentifier: segue.stringIdentifier(), sender: segue)
    }
  }
  
}

extension StartViewController: UITableViewDelegate {
  
  public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let instrument = instruments[indexPath.row]
    Answers.logCustomEvent(
        withName: "Instrument Selected",
        customAttributes: ["Name": instrument.name, "RSSI": NSNumber(value: instrument.rssi)]
    )
    presenter.didPerform(action: .instrumentSelect(instruments[indexPath.row]))
  }
}

extension StartViewController: UITableViewDataSource {
  
  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return instruments.count
  }
  
  public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(
        withIdentifier: "nearby_instrument_cell"
    ) as? NearbyInstrumentCell else {
      return UITableViewCell()
    }
    cell.bind(to: instruments[indexPath.row])
    return cell
  }
  
}

fileprivate extension StartViewSegue {
  
  func stringIdentifier() -> String {
    switch self {
    case .measure: return "show_measure_view"
    }
  }
  
}
