//
// Created by Jefferson Jones on 5/29/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation
import UIKit

class SampleMeasurementCell: UITableViewCell {
  
  @IBOutlet weak var timestampLabel: UILabel!
  @IBOutlet weak var infoLabel:      UILabel!
  
  private var dateFormatter: DateFormatter!
  
  public override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    configure()
  }
  
  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configure()
  }
  
  
  open override func awakeFromNib() {
    super.awakeFromNib()
    configure()
  }
  
  private func configure() {
    dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .short
    dateFormatter.timeStyle = .short
    let selectedView = UIView()
    selectedView.backgroundColor = UIColor.white.withAlphaComponent(0.3)
    self.selectedBackgroundView = selectedView
  }
  
  func bind(toMeasurement measurement: SampleMeasurement) {
    timestampLabel.text = dateFormatter.string(from: measurement.timestamp)
    infoLabel.text = String(
        format: "pH: %.3f\nTemp: %.2f\nSalinity: %.2f",
        arguments: [measurement.pH, measurement.temperature, measurement.salinity]
    )
  }
  
  
}
