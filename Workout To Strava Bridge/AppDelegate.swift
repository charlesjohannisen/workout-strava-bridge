//
//  AppDelegate.swift
//  Workout To Strava Bridge
//
//  Created by Charles Johannisen on 2020/02/18.
//  Copyright © 2020 Charles Johannisen. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
      // Override point for customization after application launch.
    return true
  }
  
  func application(_ application: UIApplication,
                   open url: URL,
                   options: [UIApplication.OpenURLOptionsKey : Any] = [:] ) -> Bool {
      
    // Determine who sent the URL.
    let sendingAppID = options[.sourceApplication]
    let appId:String = "\(sendingAppID ?? "Unknown")"
    
    if (appId.starts(with: "com.strava")) {
      // Process the URL.
      guard let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true),
        let params = components.queryItems else {
          print("Invalid URL or path missing")
          return false
        }
      
      if let code = params.first(where: { $0.name == "code" })?.value {
        print("code = \(code)")
        Http().getRefreshToken(code: "\(code)")
        return true
      }
    }
    return true
  }

  // MARK: UISceneSession Lifecycle

  @available(iOS 13.0, *)
  func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
  }

  @available(iOS 13.0, *)
  func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
  }


}

