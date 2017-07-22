//
// Created by Jefferson Jones on 7/22/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation

protocol Location {
  var latitude:           Double { get }
  var longitude:          Double { get }
  var altitude:           Double { get }
  var horizontalAccuracy: Double { get }
  var verticalAccuracy:   Double { get }
  var timestamp:          Date { get }
}
