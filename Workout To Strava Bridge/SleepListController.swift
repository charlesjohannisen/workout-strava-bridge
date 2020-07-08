//
//  SleepListController.swift
//  Workout To Strava Bridge
//
//  Created by Charles Johannisen on 2020/04/01.
//  Copyright © 2020 Charles Johannisen. All rights reserved.
//

import UIKit
import HealthKit

class SleepTableViewCell: UITableViewCell {
  @IBOutlet weak var sleepIcon: UIImageView!
  @IBOutlet weak var sleepDate: UILabel!
  @IBOutlet weak var sleepTime: UILabel!
}

class HeartRate {
  var date:Int
  var sleepType:Int
  init(date:Date, heartRate:Double){
    self.date = Int(modf(date.timeIntervalSince1970).0)
    self.sleepType = Int(heartRate) - 45
  }
}

class SleepListController: UITableViewController {
  
  var hkAuth:Bool = false
  var sleepCycleList:[HeartRate] = [HeartRate]()
  
  override func viewDidLoad() {
      super.viewDidLoad()
    hkAuth = HealthKitSetup().authorize()
    if(hkAuth){
      
    }
    
  }
  
  func getToday() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    let date:String = formatter.string(from: Date())
    return date
  }
  
  func getDates(date:String, daySleeper:Bool) -> [Date] {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    var day:String = date
    if(daySleeper){
      day = "\(day) 23:59:59"
    } else {
      day = "\(day) 11:59:59"
    }
    
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let time = formatter.date(from: day) ?? Date()
    let lastDay = time.addingTimeInterval(-(59 * 60 * 24))
    
    return [lastDay, time]
  }
  
  func getHeartRateList(date:String, daySleeper:Bool=false) -> [HKQuantitySample] {
    let dateRange:[Date] = self.getDates(date: date, daySleeper: daySleeper)
    var result = getHeartRates(startDate: dateRange[0], endDate: dateRange[1])
    var heartRates:[HKQuantitySample] = [HKQuantitySample]()
    do {
      try heartRates = result.get()
    } catch {
      return heartRates
    }
    return heartRates
  }
  
  func formSleepSections(heartRates:[HKQuantitySample]) {
    heartRates.forEach { hr in
      let heartRate:HeartRate = HeartRate(date: hr.startDate, heartRate: hr.quantity.doubleValue(for: HKUnit(from:"count/min")))
    }
  }
  
  func makeSleepCycles() {
    let date:String = self.getToday()
    let defaults = UserDefaults.standard
    var sleepIndexList:[String] = defaults.array(forKey: "sleepIndex") as! [String]
    if(sleepIndexList.count > 0){
      if(sleepIndexList.contains(date)){
        sleepIndexList.reversed().forEach { sleepDate in
          let heartRates:[HKQuantitySample] = self.getHeartRateList(date: sleepDate)
          
        }
      } else {
        sleepIndexList.append(date)
        defaults.set(sleepIndexList, forKey: "sleepIndex")
        self.makeSleepCycles()
      }
    } else {
      defaults.set([date], forKey: "sleepIndex")
      self.makeSleepCycles()
    }
  }
  
  override func numberOfSections(in tableView: UITableView) -> Int {
      return 1
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return sleepCycleList.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "SleepCell", for: indexPath) as! SleepTableViewCell
    
    return cell
  }
}
