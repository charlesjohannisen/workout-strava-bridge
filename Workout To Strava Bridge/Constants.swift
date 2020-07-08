//
//  Constants.swift
//  Workout To Strava Bridge
//
//  Created by Charles Johannisen on 2020/02/28.
//  Copyright © 2020 Charles Johannisen. All rights reserved.
//

import Foundation
import HealthKit

public let otherActivity:[String:Any] = [
"label":"Other",
"icon":"other",
"dropdown":["Workout": "Workout"]]

public let activities:[UInt:[String:Any]] = [
  HKWorkoutActivityType.cycling.rawValue: [
    "label":"Cycling",
    "icon":"cycling",
    "dropdownLabel":["Ride", "E-Bike Ride", "Virtual Ride"],
    "dropdown":["Ride", "EBikeRide", "VirtualRide"]],
  HKWorkoutActivityType.running.rawValue: [
    "label":"Running",
    "icon":"running",
    "dropdownLabel":["Run", "Virtual Run"],
    "dropdown":["Run", "VirtualRun"]],
  HKWorkoutActivityType.yoga.rawValue: [
    "label":"Yoga",
    "icon":"yoga",
    "dropdownLabel":["Yoga"],
    "dropdown":["Yoga"]],
  HKWorkoutActivityType.swimming.rawValue: [
    "label":"swimming",
    "icon":"swimming",
    "dropdownLabel":["Swim"],
    "dropdown":["Swim"]],
  HKWorkoutActivityType.hiking.rawValue: [
    "label":"hiking",
    "icon":"hiking",
    "dropdownLabel":["Hike"],
    "dropdown":["Hike"]],
  HKWorkoutActivityType.walking.rawValue: [
    "label":"walking",
    "icon":"walking",
    "dropdownLabel":["Walk"],
    "dropdown":["Walk"]],
  HKWorkoutActivityType.crossCountrySkiing.rawValue: [
    "label":"skiing",
    "icon":"skiing",
    "dropdownLabel":["Alpine Ski", "Backcountry Ski", "Nordic Ski", "Roller Ski"],
    "dropdown":["AlpineSki", "BackcountrySki", "NordicSki", "RollerSki"]],
  HKWorkoutActivityType.paddleSports.rawValue: [
    "label":"Paddle Sports",
    "icon":"paddleSports",
    "dropdownLabel":["Canoeing", "Kayaking", "Stand Up Paddling"],
    "dropdown":["Canoeing", "Kayaking", "StandUpPaddling"]],
  HKWorkoutActivityType.crossTraining.rawValue: [
    "label":"Cross Training",
    "icon":"crosstraining",
    "dropdownLabel":["Crossfit"],
    "dropdown":["Crossfit"]],
  HKWorkoutActivityType.elliptical.rawValue: [
    "label":"Elliptical",
    "icon":"elliptical",
    "dropdownLabel":["Elliptical"],
    "dropdown":["Elliptical"]],
  HKWorkoutActivityType.handCycling.rawValue: [
    "label":"Handcycling",
    "icon":"handcycle",
    "dropdownLabel":["Handcycle"],
    "dropdown":["Handcycle"]],
  HKWorkoutActivityType.skatingSports.rawValue: [
    "label":"Skating",
    "icon":"skatingsports",
    "dropdownLabel":["Ice Skate", "Inline Skate"],
    "dropdown":["IceSkate", "InlineSkate"]],
  HKWorkoutActivityType.surfingSports.rawValue: [
    "label":"Surfing",
    "icon":"surfing",
    "dropdownLabel":["Surfing", "Kitesurf", "Windsurf"],
    "dropdown":["Surfing", "Kitesurf", "Windsurf"]],
  HKWorkoutActivityType.rowing.rawValue: [
    "label":"Rowing",
    "icon":"rowing",
    "dropdownLabel":["Rowing"],
    "dropdown":["Rowing"]],
  HKWorkoutActivityType.snowboarding.rawValue: [
    "label":"Snowboarding",
    "icon":"snowboarding",
    "dropdownLabel":["Snowboard"],
    "dropdown":["Snowboard"]],
  HKWorkoutActivityType.stairClimbing.rawValue: [
    "label":"Stair Climbing",
    "icon":"stairclimbing",
    "dropdownLabel":["Stair-Stepper"],
    "dropdown":["StairStepper"]],
  HKWorkoutActivityType.functionalStrengthTraining.rawValue: [
    "label":"Weight Training",
    "icon":"weights",
    "dropdownLabel":["Weight Training"],
    "dropdown":["WeightTraining"]],
  HKWorkoutActivityType.wheelchairWalkPace.rawValue: [
    "label":"Wheelchair",
    "icon":"wheelchair",
    "dropdownLabel":["Wheelchair"],
    "dropdown":["Wheelchair"]],
  HKWorkoutActivityType.wheelchairRunPace.rawValue: [
    "label":"Wheelchair",
    "icon":"wheelchair",
    "dropdownLabel":["Wheelchair"],
    "dropdown":["Wheelchair"]],
  HKWorkoutActivityType.other.rawValue: otherActivity
]

public func getActivity(type:UInt) -> [String:Any] {
  return activities[type] ?? otherActivity
}

public func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
}
