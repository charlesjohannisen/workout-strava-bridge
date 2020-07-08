//
//  WorkoutDataStore.swift
//  Workout To Strava Bridge
//
//  Created by Charles Johannisen on 2020/02/18.
//  Copyright © 2020 Charles Johannisen. All rights reserved.
//

import UIKit
import HealthKit
import CoreLocation
import CoreGPX

class WorkoutDataStore {

  func getWorkouts() -> Result<[HKWorkout],Error> {
    var result:Result<[HKWorkout],Error>!
    let semaphore = DispatchSemaphore(value: 0)
    
    let predicate = HKQuery.predicateForWorkouts(with: .greaterThanOrEqualTo, duration: 60 * 5)
    let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate,
    ascending: false)
    let query = HKSampleQuery(
      sampleType: .workoutType(),
      predicate: predicate,
      limit: 0,
      sortDescriptors: [sortDescriptor]) { (query, samples, error) in
        guard
          let samples = samples as? [HKWorkout],
          error == nil
          else {
            result = Result.failure(error!)
            fatalError("The query failed.")
        }
        var workouts:[HKWorkout] = [HKWorkout]()
        samples.forEach { workout in
          let isApple: Bool = workout.sourceRevision.source.bundleIdentifier.starts(with: "com.apple.health")
          if(isApple) {
            workouts.append(workout)
          }
        }
        result = Result.success(workouts)
        semaphore.signal()
    }
    
    HKHealthStore().execute(query)
    _ = semaphore.wait(wallTimeout: .distantFuture)
    return result
  }

  func getWorkout(workout:HKWorkout) -> String {
    var result = getHeartRates(startDate: workout.startDate, endDate: workout.endDate)
    var heartRates:[HKQuantitySample] = [HKQuantitySample]()
    var gpxString = ""
    do {
      try heartRates = result.get()
      let routes = self.getWorkoutRoutes(workout: workout, heartRates: heartRates)
      do {
        try gpxString = routes.get()
      } catch {
        return ""
      }
    } catch {
      return ""
    }
    return gpxString
  }
    
  func getWorkoutRoutes(workout: HKWorkout, heartRates: [HKQuantitySample]?) -> Result<String,Error> {
    var result:Result<String,Error>!
    let semaphore = DispatchSemaphore(value: 0)
    
    let runningObjectQuery = HKQuery.predicateForObjects(from: workout)

    let routeQuery = HKAnchoredObjectQuery(type: HKSeriesType.workoutRoute(), predicate: runningObjectQuery, anchor: nil, limit: HKObjectQueryNoLimit) { (query, samples, deletedObjects, anchor, error) in
        
      guard error == nil else {
          // Handle any errors here.
          print(error as Any)
          result = Result.failure(error!)
          fatalError("The initial query failed.")
      }

      let root = GPXRoot(withExtensionAttributes: ["creator":"SPCTR", "xmlns:gpxtpx":"http://www.garmin.com/xmlschemas/TrackPointExtension/v1", "xmlns:gpxx":"http://www.garmin.com/xmlschemas/GpxExtensions/v3"], schemaLocation: "http://www.garmin.com/xmlschemas/TrackPointExtension/v1 http://www.garmin.com/xmlschemas/TrackPointExtensionv1.xsd http://www.garmin.com/xmlschemas/GpxExtensions/v3 http://www.garmin.com/xmlschemas/GpxExtensionsv3.xsd")
      let track = GPXTrack()                          // inits a track
      let tracksegment = GPXTrackSegment()
      var trackpoints = [GPXTrackPoint]()
      
      if(samples?.count ?? 0 > 0){
        (samples)?.forEach { sample in
          let route:HKWorkoutRoute = sample as! HKWorkoutRoute
          let result = self.getWorkoutRouteData(workoutRoute:route, heartRates: heartRates, trackpoints: trackpoints)
          do {
            try trackpoints = result.get()
          } catch {}
        }
      } else {
        trackpoints = self.setWorkoutRouteData(heartRates: heartRates)
      }
      
      tracksegment.add(trackpoints: trackpoints)
      track.add(trackSegment: tracksegment)
      root.add(track: track)
      result = Result.success(root.gpx())
      semaphore.signal()
    }
    
    HKHealthStore().execute(routeQuery)
    _ = semaphore.wait(wallTimeout: .distantFuture)
    return result
  }
  
  func getHeartRate(time:Date, heartRates: [HKQuantitySample]?, lastHeartRate: Double = 0) -> Double {
    var hr:Double = lastHeartRate
    heartRates?.forEach { heartRate in
      let over = time.addingTimeInterval(5)
      let under = time.addingTimeInterval(-5)
      if(heartRate.startDate >= under && heartRate.startDate < over){
        hr = heartRate.quantity.doubleValue(for: HKUnit(from:"count/min"))
      }
    }
    return hr
  }
  
  func setWorkoutRouteData(heartRates: [HKQuantitySample]?) -> [GPXTrackPoint] {
    var trackpoints = [GPXTrackPoint]()
    heartRates?.forEach { heartRate in
      let hr:Double = heartRate.quantity.doubleValue(for: HKUnit(from:"count/min"))
      let cllocation:CLLocation = CLLocation(coordinate: CLLocationCoordinate2DMake(0, 0), altitude: 0, horizontalAccuracy: 0, verticalAccuracy: 0, timestamp: heartRate.startDate)
      let trackpoint:GPXTrackPoint = self.gpxTRKPT(location: cllocation, heartRate: String(hr))
      trackpoints.append(trackpoint)
    }
    return trackpoints
  }

  func getWorkoutRouteData(workoutRoute: HKWorkoutRoute, heartRates: [HKQuantitySample]?, trackpoints: [GPXTrackPoint]) -> Result<[GPXTrackPoint],Error> {
    var result:Result<[GPXTrackPoint],Error>!
    let semaphore = DispatchSemaphore(value: 0)
    var cllocations = [CLLocation]()
    let query = HKWorkoutRouteQuery(route: workoutRoute) {
      (query, locationsOrNill, done, errorOrNil) in
          
      if let error = errorOrNil {
        print(error)
        result = Result.failure(error)
        return
      }

      guard let locations = locationsOrNill else {
        fatalError("*** Invalid State: This can only fail if there was an error. ***")
      }

      var gpxtrackpoints = trackpoints
      var heartRate:Double = 0

      if done {
        locations.forEach { location in
          cllocations.append(location)
        }
        
        for x in 0..<cllocations.count {
          heartRate = self.getHeartRate(time: cllocations[x].timestamp, heartRates: heartRates, lastHeartRate: heartRate)
          let trackpoint:GPXTrackPoint = self.gpxTRKPT(location: cllocations[x], heartRate: String(heartRate))
          gpxtrackpoints.append(trackpoint)
        }
        result = Result.success(gpxtrackpoints)
        semaphore.signal()
      } else {
        locations.forEach { location in
          cllocations.append(location)
        }
      }

    }
    
    
    HKHealthStore().execute(query)
    _ = semaphore.wait(wallTimeout: .distantFuture)
    return result
  }
  
  func gpxTRKPT(location: CLLocation, heartRate: String) -> GPXTrackPoint {
    let lat:Double = location.coordinate.latitude
    let lon:Double = location.coordinate.longitude
    let alt:Double = location.altitude
    let time:Date = location.timestamp
    let trackpoint:GPXTrackPoint = GPXTrackPoint(latitude: lat, longitude: lon)
    trackpoint.time = time
    trackpoint.elevation = alt
    
    let gxptpxs:GPXExtensions = GPXExtensions()
    gxptpxs.append(at: "gpxtpx:TrackPointExtension", contents: ["gpxtpx:hr" : heartRate])
    
    trackpoint.extensions = gxptpxs
    
    return trackpoint
  }
  
}
