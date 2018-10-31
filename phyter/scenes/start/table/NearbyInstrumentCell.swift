//
// Created by Jefferson Jones on 5/28/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation
import UIKit

class NearbyInstrumentCell: UITableViewCell {
  
  lazy var imgOneBar:    UIImage = UIImage(imageLiteralResourceName: "ic_signal_cellular_1_bar_48pt")
  lazy var imgTwoBars:   UIImage = UIImage(imageLiteralResourceName: "ic_signal_cellular_2_bar_48pt")
  lazy var imgThreeBars: UIImage = UIImage(imageLiteralResourceName: "ic_signal_cellular_3_bar_48pt")
  lazy var imgFourBars:  UIImage = UIImage(imageLiteralResourceName: "ic_signal_cellular_4_bar_48pt")
  
  @IBOutlet weak var signalImageView: UIImageView!
  @IBOutlet weak var instrumentLabel: UILabel!
  
  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
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
  
  func bind(to instrument: PhyterInstrument) {
    signalImageView.tintColor = .white
    if instrument.rssi > -45 {
      signalImageView.image = imgFourBars
    } else if instrument.rssi > -55 {
      signalImageView.image = imgThreeBars
    } else if instrument.rssi > -65 {
      signalImageView.image = imgTwoBars
    } else {
      signalImageView.image = imgOneBar
    }
    instrumentLabel.text = instrument.name
  }
  
  private func configure() {
    let selectedView = UIView()
    selectedView.backgroundColor = UIColor.white.withAlphaComponent(0.3)
    self.selectedBackgroundView = selectedView
  }
  
}
