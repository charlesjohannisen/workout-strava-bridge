//
//  HealthKitSetup.swift
//  Workout To Strava Bridge
//
//  Created by Charles Johannisen on 2020/02/18.
//  Copyright © 2020 Charles Johannisen. All rights reserved.
//

import HealthKit

class HealthKitSetup {
  
  private enum HealthkitSetupError: Error {
    case notAvailableOnDevice
    case dataTypeNotAvailable
  }
  
  func authorizeHealthKit() -> Result<Bool,Error> {
    
    var result:Result<Bool,Error>!
    let semaphore = DispatchSemaphore(value: 0)
    
    guard HKHealthStore.isHealthDataAvailable() else {
      result = Result.failure(HealthkitSetupError.notAvailableOnDevice)
      return result
    }
    
    guard let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate),
        let distanceWalkingRunning = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning),
        let workoutRoute = HKObjectType.seriesType(forIdentifier: HKSeriesType.workoutRoute().identifier)
        else {
            result = Result.failure(HealthkitSetupError.dataTypeNotAvailable)
            return result
    }
    
    let healthKitTypesToWrite: Set<HKSampleType> = []
    
    let healthKitTypesToRead: Set<HKObjectType> = [
        HKObjectType.workoutType(),
        heartRate,
        distanceWalkingRunning,
        workoutRoute
    ]
    
    HKHealthStore().requestAuthorization(toShare: healthKitTypesToWrite, read: healthKitTypesToRead) { (success, error) in
      result = Result.success(success)
      semaphore.signal()
    }
    
    _ = semaphore.wait(wallTimeout: .distantFuture)
    return result
  }

  func authorize() -> Bool {
    let result = self.authorizeHealthKit()
    do {
      try result.get()
      return true
    } catch {
      return false
    }
  }
}

