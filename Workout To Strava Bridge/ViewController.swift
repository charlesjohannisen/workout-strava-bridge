//
//  ViewController.swift
//  Workout To Strava Bridge
//
//  Created by Charles Johannisen on 2020/02/18.
//  Copyright © 2020 Charles Johannisen. All rights reserved.
//

import UIKit
import HealthKit

class WorkoutTableViewCell: UITableViewCell {
  @IBOutlet weak var workoutIcon: UIImageView!
  @IBOutlet weak var workoutName: UILabel!
  @IBOutlet weak var workoutDate: UILabel!
  @IBOutlet weak var workoutStatus: UIImageView!
  var index:Int!
}

class ViewController: UITableViewController {
  
  var hkAuth:Bool = false
  var workoutList:[HKWorkout] = [HKWorkout]()
  var activityStartList:[String] = [String]()
  
  let appOAuthUrlStravaScheme = URL(string: "strava://oauth/mobile/authorize?client_id=43705&redirect_uri=spctrworkoutstravabridge%3A%2F%2Fspctr.in%2Fen-US&response_type=code&approval_prompt=auto&scope=activity%3Awrite%2Cactivity%3Aread_all")!
    
  func onStravaAuth() {
    if UIApplication.shared.canOpenURL(appOAuthUrlStravaScheme) {
        UIApplication.shared.open(appOAuthUrlStravaScheme, options: [:])
    } else {
        // redirect to Notice
    }
  }
    
    func sameDay(date1: Date, date2: Date) -> Bool {
        let calendar = Calendar.current

        // Extract the components of the dates
        let date1Components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date1)
        let date2Components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date2)

        // Check if the dates are in the same month and day
        let isSameMonth = date1Components.month == date2Components.month
        let isSameDay = date1Components.day == date2Components.day
        let isSameYear = date1Components.year == date2Components.year

        return isSameMonth && isSameDay && isSameYear
    }
  
  func formattedDate(date: Date, format:String="d MMM y HH:mm") -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = format
    return dateFormatter.string(from: date)
  }
  
  func getWorkouts() {
    workoutList = [HKWorkout]()
    let defaults = UserDefaults.standard
    let stravaRefreshToken:Int = defaults.integer(forKey: "stravaSessionStart")
    if(Int(modf(Date().timeIntervalSince1970).0) > stravaRefreshToken){
      _ = Http().getAllActivities()
    }
    activityStartList = defaults.array(forKey: "stravaActivities") as! [String]
    let result = WorkoutDataStore().getWorkouts()
    do {
      try workoutList = result.get()
      self.tableView.reloadData()
    } catch {}
  }
  
  override func viewDidLoad() {
      super.viewDidLoad()
    hkAuth = HealthKitSetup().authorize()
    if(hkAuth){
      let defaults = UserDefaults.standard
      let stravaRefreshToken:String = defaults.string(forKey: "stravaRefreshToken") ?? "stravaRefreshToken"
      if(stravaRefreshToken == "stravaRefreshToken"){
        self.onStravaAuth()
      } else {
        self.getWorkouts()
      }
    }
    
  }
  
  override func numberOfSections(in tableView: UITableView) -> Int {
      return 1
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return workoutList.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "WorkoutCell", for: indexPath) as! WorkoutTableViewCell
    let activityType:[String:Any] = getActivity(type: workoutList[indexPath.row].workoutActivityType.rawValue)
    let label:String = activityType["label"] as! String
    let icon:String = activityType["icon"] as! String
    cell.workoutName.text = label
    cell.workoutDate.text = self.formattedDate(date: workoutList[indexPath.row].startDate)
    cell.workoutIcon.image = UIImage(named: "\(icon)-icon")
    
    let date:Date = workoutList[indexPath.row].startDate
    let secondUp:Date = date.addingTimeInterval(1)
    let secondDown:Date = date.addingTimeInterval(-1)
    let dateTime:String = self.formattedDate(date: date, format: "yyyy-MM-dd'T'HH:mm:ss'Z'")
    let secondUpTime:String = self.formattedDate(date: secondUp, format: "yyyy-MM-dd'T'HH:mm:ss'Z'")
    let secondDownTime:String = self.formattedDate(date: secondDown, format: "yyyy-MM-dd'T'HH:mm:ss'Z'")
    let uploaded:Bool = activityStartList.contains(dateTime) || activityStartList.contains(secondUpTime) || activityStartList.contains(secondDownTime)
    
    cell.workoutStatus.image = uploaded ? UIImage(named: "strava-done") : UIImage(named: "strava-pending")
    cell.index = indexPath.row
    return cell
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    // self.performSegue(withIdentifier: "showUploadActivity", sender: indexPath);
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    let activityUploadController : ActivityUploadController = segue.destination as! ActivityUploadController
    let cell = sender as! WorkoutTableViewCell
    activityUploadController.workout = workoutList[cell.index]
    let activityType:[String:Any] = getActivity(type: workoutList[cell.index].workoutActivityType.rawValue)
    activityUploadController.activityType = activityType
    activityUploadController.viewController = self
  }

}

