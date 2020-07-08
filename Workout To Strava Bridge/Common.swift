//
//  Common.swift
//  Workout To Strava Bridge
//
//  Created by Charles Johannisen on 2020/04/02.
//  Copyright © 2020 Charles Johannisen. All rights reserved.
//

import Foundation
import HealthKit

public func getHeartRates(startDate: Date, endDate: Date) -> Result<[HKQuantitySample],Error> {
  var result:Result<[HKQuantitySample],Error>!
  let semaphore = DispatchSemaphore(value: 0)
  
  let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
  
  let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate,
  ascending: true)
  let heartRateType:HKQuantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
  
  let query = HKSampleQuery(
    sampleType: heartRateType,
    predicate: predicate,
    limit: 0,
    sortDescriptors: [sortDescriptor]) { (query, samples, error) in
      guard
        let samples = samples as? [HKQuantitySample] ,
        error == nil
        else {
          result = Result.failure(error!)
          fatalError("The query failed.")
      }
                              
      result = Result.success(samples)
      semaphore.signal()
  }
  
  HKHealthStore().execute(query)
  _ = semaphore.wait(wallTimeout: .distantFuture)
  return result
}
