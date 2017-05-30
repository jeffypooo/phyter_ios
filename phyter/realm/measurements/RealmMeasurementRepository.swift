//
// Created by Jefferson Jones on 5/29/17.
// Copyright (c) 2017 Jefferson Jones. All rights reserved.
//

import Foundation
import RxSwift
import RealmSwift

class RealmMeasurementRepository: RealmHelper, MeasurementRepository {
  func createMeasurement(instrumentId: UUID, salinity: Float32, pH: Float32, temp: Float32) -> SampleMeasurement {
    var measurement: RealmSampleMeasurement!
    onRealm {
      realm in
      measurement = RealmSampleMeasurement()
      measurement.instrumentId = instrumentId
      measurement.salinity = salinity
      measurement.pH = pH
      measurement.temperature = temp
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
          token.stop()
        }
      }
    }
    return obsv
  }
  
  func addObservableNotificationBlock(
      forResults res: Results<RealmSampleMeasurement>,
      observer: AnyObserver<MeasurementLiveQuery>) -> NotificationToken {
    let token = res.addNotificationBlock {
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
