//
// Created by Jeff Jones on 7/4/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation

class DocumentsFileExporter: FileExporter {
  func export(measurements: [SampleMeasurement], fileName: String, format: FileExportFormat) -> URL? {
    guard let exportsDir = getExportsDirectory() else { return nil }
    createDirectory(exportsDir)
    switch format {
      case .csv:
        return exportToCSV(dir: exportsDir, name: fileName, data: measurements)
    }
  }

  private func exportToCSV(dir: URL, name: String, data: [SampleMeasurement]) -> URL? {
    let fileName   = dir.appendingPathComponent(name + ".csv")
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MM/dd/yyyy h:mm:ss"
    let rowFormat  = "%@,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f\n"
    var fileOutput = "Date,Salinity,pH,Temperature,Dark,A578,A434\n"

    for sample in data {
      let dateStr = dateFormatter.string(from: sample.timestamp)
      fileOutput += String(
          format: rowFormat,
          arguments: [dateStr, sample.salinity, sample.pH, sample.temperature, sample.dark, sample.a578, sample.a434]
      )
    }
    do {
      try fileOutput.write(to: fileName, atomically: false, encoding: .utf8)
      return fileName
    } catch let e {
      print("error occurred writing CSV file to '\(fileName)': \(e.localizedDescription)")
      return nil
    }
  }

  private func createDirectory(_ dir: URL) {
    do {
      try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    } catch let e {
      print("error occurred creating directory at path '\(dir)': \(e.localizedDescription)")
    }
  }

  private func getExportsDirectory() -> URL? {
    guard let docsPath = getDocumentsPath() else { return nil }
    return URL(fileURLWithPath: docsPath).appendingPathComponent("PhyterDataLogger")
  }

  private func getDocumentsPath() -> String? {
    return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
  }
}
