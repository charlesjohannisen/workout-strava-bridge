//
//  ActivityUploadController.swift
//  Workout To Strava Bridge
//
//  Created by Charles Johannisen on 2020/02/24.
//  Copyright © 2020 Charles Johannisen. All rights reserved.
//

import UIKit
import HealthKit

class ActivityUploadController: UIViewController, UITextViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
  
  @IBOutlet weak var picker: UIPickerView!
  @IBOutlet weak var textviewDescription: UITextView!
  @IBOutlet weak var textfieldName: UITextField!
  
  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 1
  }
  
  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    return dropdown.count
  }
  
  func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
      self.view.endEditing(true)
      return dropdownLabel[row]
  }

  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
      activityTypeSelected = dropdown[row]
  }
  
  var workout:HKWorkout!
  var activityType:[String:Any] = [String:Any]()
  var activityTypeSelected:String = ""
  var viewController:ViewController!
  
  var dropdownLabel:[String] = [String]()
  var dropdown:[String] = [String]()
  
  let gpxFile = getDocumentsDirectory().appendingPathComponent("temp.gpx")
  
//  func toggleAction(_ start:Bool){
//    if(start){
//      activityIndicator.startAnimating()
//    } else {
//      activityIndicator.stopAnimating()
//    }
//    uploadButton.isHidden = start
//    cancelButton.isHidden = start
//  }
  
  @IBAction func onUploadClick(_ sender: Any) {
    //self.toggleAction(true)
    let name:String = self.textfieldName.text!
    let description:String = self.textviewDescription.text
    let type:String = activityTypeSelected == "" ? dropdown[0] : activityTypeSelected
    
    let workoutGPX:String = WorkoutDataStore().getWorkout(workout: workout)
    if(!workoutGPX.isEmpty){
      let savedFile:Bool = self.saveData(data: workoutGPX)
      if(savedFile){
        let uploadedFile:Bool = Http().uploadActivity(name: name, description: description, type: type)
        if(uploadedFile){
//          //self.toggleAction(false)
          dismiss(animated: true, completion: {
            self.viewController.getWorkouts()
          })
        }
      }
    }
    //self.toggleAction(false)
  }
  
  func saveData(data:String) -> Bool {
    do {
      try data.write(to: gpxFile, atomically: true, encoding: String.Encoding.utf8)
      return true
    } catch {
      return false
    }
  }
  
  @IBAction func onCancelClick(_ sender: Any) {
    dismiss(animated: true, completion: nil)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.picker.delegate = self
    self.textviewDescription.delegate = self
    self.textviewDescription.layer.borderWidth = 1.0
    let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing))
    view.addGestureRecognizer(tap)
    dropdown = activityType["dropdown"] as! [String]
    dropdownLabel = activityType["dropdownLabel"] as! [String]
  }
}
