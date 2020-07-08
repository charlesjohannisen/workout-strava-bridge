//
//  MainViewController.swift
//  Workout To Strava Bridge
//
//  Created by Charles Johannisen on 2020/03/16.
//  Copyright © 2020 Charles Johannisen. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {

  @IBAction func toWorkout(_ sender: Any) {
    self.performSegue(withIdentifier: "showWorkouts", sender: nil);
  }
  @IBAction func toSleep(_ sender: Any) {
  }
}
