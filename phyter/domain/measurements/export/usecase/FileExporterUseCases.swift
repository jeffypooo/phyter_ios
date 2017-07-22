//
// Created by Jeff Jones on 7/4/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation

class FileExportUseCase<A:UseCaseArgs, R:UseCaseResult>: OneShotUseCase<A, R> {

  let exporter: FileExporter

  init(_ exporter: FileExporter) {
    self.exporter = exporter
  }

}

class ExportToCSVArgs: UseCaseArgs {
  let data:     [SampleMeasurement]
  let fileName: String

  init(data: [SampleMeasurement], fileName: String) {
    self.data = data
    self.fileName = fileName
  }
}

class ExportToCSVResult: UseCaseResult {
  let fileURL: URL
  init(_ url: URL) {
    self.fileURL = url
  }
}

enum ExportToCSVError: Error {
  case exportFailed
}

class ExportToCSV: FileExportUseCase<ExportToCSVArgs, ExportToCSVResult> {
  open override func execute(
      _ args: ExportToCSVArgs?,
      onSuccess: @escaping (ExportToCSVResult) -> Void,
      onError: @escaping (Error) -> Void) {
    guard let data = args?.data, let fName = args?.fileName else {
      onError(UseCaseError.argsRequired)
      return
    }
    if let file = exporter.export(measurements: data, fileName: fName, format: .csv) {
      onSuccess(ExportToCSVResult(file))
    } else {
      onError(ExportToCSVError.exportFailed)
    }
  }
}
