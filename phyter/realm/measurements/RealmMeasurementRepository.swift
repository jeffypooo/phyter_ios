//
// Created by Jefferson Jones on 5/29/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation
import RxSwift
import RealmSwift

class RealmMeasurementRepository: RealmHelper, MeasurementRepository {
  func createMeasurement(
      instrumentId: UUID,
      salinity: Float32,
      pH: Float32,
      temp: Float32,
      dark: Float32,
      a578: Float32,
      a434: Float32,
      location: Location?) -> SampleMeasurement {
    var measurement: RealmSampleMeasurement!
    onRealm {
      realm in
      measurement = RealmSampleMeasurement()
      measurement.instrumentId = instrumentId
      measurement.salinity = salinity
      measurement.pH = pH
      measurement.temperature = temp
      measurement.dark = dark
      measurement.a578 = a578
      measurement.a434 = a434
      measurement.location = location
      try! realm.write {
        realm.add(measurement, update: false)
      }
    }
    return measurement
  }

  func measurements(forInstrumentId id: UUID) -> Observable<MeasurementLiveQuery> {
    var obsv: Observable<MeasurementLiveQuery>!
    onRealm {
      realm in
      obsv = Observable.create {
        observer in
        let idPred  = NSPredicate(format: "_instIdStr == %@", argumentArray: [id.uuidString])
        let results = realm.objects(RealmSampleMeasurement.self).filter(idPred).sorted(
            byKeyPath: "_timestamp",
            ascending: false
        )
        let token   = self.addObservableNotificationBlock(forResults: results, observer: observer)
        return Disposables.create {
          token.invalidate()
        }
      }
    }
    return obsv
  }

  func delete(measurement: SampleMeasurement) -> Bool {
    if let realmMeasurement = measurement as? RealmSampleMeasurement {
      onRealm {
        realm in
        try! realm.write {
          realm.delete(realmMeasurement)
        }
      }
      return true
    }
    let timePred = NSPredicate(format: "_timestamp", argumentArray: [measurement.timestamp])
    var success  = false
    onRealm {
      realm in
      if let matching = realm.objects(RealmSampleMeasurement.self).filter(timePred).first {
        try! realm.write {
          realm.delete(matching)
        }
        success = true
      }
    }
    return success
  }

  func addObservableNotificationBlock(
      forResults res: Results<RealmSampleMeasurement>,
      observer: AnyObserver<MeasurementLiveQuery>) -> NotificationToken {
    let token = res.observe {
      collectionChange in
      switch collectionChange {
        case .initial(let res):
          let query = MeasurementLiveQuery(
              results: self.toSampleMeasurements(res),
              insertions: [],
              deletions: [],
              modifications: []
          )
          observer.onNext(query)
          break
        case .update(let res, let dels, let ins, let mods):
          let query = MeasurementLiveQuery(
              results: self.toSampleMeasurements(res),
              insertions: ins,
              deletions: dels,
              modifications: mods
          )
          observer.onNext(query)
          break
        case .error(let err):
          print("error in notification block for measurement results: \(err)")
          observer.onError(err)
          break
      }
    }
    return token
  }

  private func toSampleMeasurements(_ results: Results<RealmSampleMeasurement>) -> [SampleMeasurement] {
    var measurements: [SampleMeasurement] = []
    for realmObj in results {
      measurements.append(realmObj)
    }
    return measurements
  }
}
