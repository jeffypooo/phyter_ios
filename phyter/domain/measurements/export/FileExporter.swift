//
// Created by Jeff Jones on 7/4/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation

enum FileExportFormat {
  case csv
}

protocol FileExporter {

  func export(measurements: [SampleMeasurement], fileName: String, format: FileExportFormat) -> URL?

}
