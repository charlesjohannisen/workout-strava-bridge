//
//  Http.swift
//  Workout To Strava Bridge
//
//  Created by Charles Johannisen on 2020/02/26.
//  Copyright © 2020 Charles Johannisen. All rights reserved.
//

import Foundation

class Http {
  var configuration = URLSessionConfiguration.default
  var session:URLSession
  init(){
    session = URLSession(configuration: configuration)
  }
  
  func get(apiEndpoint:String, async:Bool=false) -> Result<Any,Error> {
    var result:Result<Any,Error>!
    let semaphore = DispatchSemaphore(value: 0)
    
    let url = URL(string: "https://www.strava.com/api/v3/\(apiEndpoint)")
    guard let requestUrl = url else { fatalError() }
    var request = URLRequest(url: requestUrl)
    request.httpMethod = "GET"
    
    let defaults = UserDefaults.standard
    let stravaExpiresAt:Int = defaults.integer(forKey: "stravaExpiresAt")
    if(Int(modf(Date().timeIntervalSince1970).0) > stravaExpiresAt){
      let refreshed:Bool = self.refreshToken()
      if(!refreshed){
        fatalError("Token Could Not Be Refreshed.")
      }
    }
    let stravaAccessToken:String = defaults.string(forKey: "stravaAccessToken") ?? "stravaAccessToken"
    request.setValue("Bearer \(stravaAccessToken)", forHTTPHeaderField: "Authorization")
    
    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
      
      if let error = error {
          print("Error took place \(error)")
          result = Result.failure(error)
      }
      
      if let data = data, let dataString = String(data: data, encoding: .utf8) {
        print("Response data string:\n \(dataString)")
        result = Result.success(self.json(str: dataString))
        semaphore.signal()
      }
    }
    
    task.resume()
    _ = async ? semaphore.wait(timeout: .now()) : semaphore.wait(wallTimeout: .distantFuture)
    return async ? Result.success(["async":true]) : result
  }
  
  func post(urlString:Any, apiEndpoint:String, auth:Bool=false, upload:Bool=false, put:Bool=false, async:Bool=false) -> Result<Any,Error> {
    var result:Result<Any,Error>!
    let semaphore = DispatchSemaphore(value: 0)
    
    let boundary = UUID().uuidString
    
    let client_id:String = "client_id"
    let client_secret:String = "client_secret"
    
    let url = URL(string: "https://www.strava.com/api/v3/\(apiEndpoint)")
    guard let requestUrl = url else { fatalError() }
    var request = URLRequest(url: requestUrl)
    request.httpMethod = put ? "PUT" : "POST"
    
    var postString = upload ? "" : "\(urlString)&client_id=\(client_id)&client_secret=\(client_secret)"
    
    if(!auth){
      let defaults = UserDefaults.standard
      let stravaExpiresAt:Int = defaults.integer(forKey: "stravaExpiresAt")
      if(Int(modf(Date().timeIntervalSince1970).0) > stravaExpiresAt){
        let refreshed:Bool = self.refreshToken()
        if(!refreshed){
          fatalError("Token Could Not Be Refreshed.")
        }
      }
      let stravaAccessToken:String = defaults.string(forKey: "stravaAccessToken") ?? "stravaAccessToken"
      request.setValue("Bearer \(stravaAccessToken)", forHTTPHeaderField: "Authorization")
      if(!upload && !put){
        postString = urlString as! String
      }
    }
    
    if(upload){
      let gpxFile = getDocumentsDirectory().appendingPathComponent("temp.gpx")
      request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
      
      let postData:[String:String] = urlString as! [String:String]
      var data = Data()
      
      var gpxData:String = ""
      do {
        try gpxData = String(contentsOf: gpxFile)
      } catch {
        fatalError("Can't Open Gpx File")
      }
      data.append(self.dataLine(boundary, name: "file", value: gpxData, file: true, filename: gpxFile.lastPathComponent).data(using: .utf8)!)
      data.append(self.dataLine(boundary, name: "name", value: postData["name"]!).data(using: .utf8)!)
      data.append(self.dataLine(boundary, name: "description", value: postData["description"]!).data(using: .utf8)!)
      data.append(self.dataLine(boundary, name: "data_type", value: "gpx").data(using: .utf8)!)

      data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
      request.httpBody = data
    } else if(put) {
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      
      let postData:[String:String] = urlString as! [String:String]
      var data = Data()
      data.append(self.jsonString(json: postData))
      
      request.httpBody = data
    } else {
      request.httpBody = postString.data(using: String.Encoding.utf8);
    }
    
    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
      
      if let error = error {
          print("Error took place \(error)")
          result = Result.failure(error)
      }
      
      if let data = data, let dataString = String(data: data, encoding: .utf8) {
        print("Response data string:\n \(dataString)")
        result = Result.success(self.json(str: dataString))
        semaphore.signal()
      }
    }
    
    task.resume()
    _ = async ? semaphore.wait(timeout: .now()) : semaphore.wait(wallTimeout: .distantFuture)
    return async ? Result.success(["async":true]) : result
  }
  
  func dataLine(_ boundary:String, name:String, value:String, file:Bool=false, filename:String="") -> String {
    let filepart:String = file ? "; filename=\"\(filename)\"" : ""
    return "\r\n--\(boundary)\r\nContent-Disposition: form-data; name=\"\(name)\"\(filepart)\r\n\r\n\(value)"
  }
  
  func refreshToken() -> Bool {
    let defaults = UserDefaults.standard
    let stravaRefreshToken:String = defaults.string(forKey: "stravaRefreshToken") ?? "stravaRefreshToken"
    let result = self.post(urlString: "grant_type=refresh_token&refresh_token=\(stravaRefreshToken)", apiEndpoint: "oauth/token", auth: true)

    var json:[String:Any] = [String:Any]()
    do {
      try json = result.get() as! [String : Any]
      self.setStoreTokens(json: json)
      return true
    } catch {
      return false
    }
  }
  
  func uploadActivity(name:String, description:String, type:String) -> Bool {
    let result = self.post(urlString: ["name":name, "description": description], apiEndpoint: "uploads", upload: true)

    var json:[String:Any] = [String:Any]()
    do {
      try json = result.get() as! [String : Any]
      
      if let _ = json["errors"] as? [Any] {
        return false
      } else {
        let id:String = json["id_str"] as! String
        self.tryUpdate(id: id, type: type)
        return true
      }
    } catch {
      return false
    }
  }
  
  func tryUpdate(id:String, type:String) {
    self.wait(5)
    let uploadJson:[String:Any] = self.getUpload(id: id)
    if let activityId:Int = uploadJson["activity_id"] as? Int {
      _ = self.updateActivity(id: activityId, urlString: ["type":type], store: true)
    } else {
      self.tryUpdate(id: id, type: type)
    }
  }
  
  func getUpload(id:String) -> [String:Any] {
     let result = self.get(apiEndpoint: "uploads/\(id)")

     var json:[String:Any] = [String:Any]()
     do {
      try json = result.get() as! [String : Any]
       return json
     } catch {
      return ["activity_id": id]
     }
   }
   
  func getActivities(_ page:Int=1) -> [[String:Any]] {
    let result = self.get(apiEndpoint: "athlete/activities?page=\(page)")

    var json:[[String:Any]] = [[String:Any]]()
    do {
      try json = result.get() as! [[String : Any]]
      return json
    } catch {
     return [["activity_id": ""]]
    }
  }
  
  func getAllActivities() -> [String] {
    var get:Bool = true
    var activityList:[[String:Any]] = [[String:Any]]()
    var page:Int = 1
    
    while(get){
      let activities:[[String:Any]] = self.getActivities(page)
      activityList.append(contentsOf: activities)
      page += 1
      if(activities.count < 30){
        get = false
      }
    }
    
    var activityDates:[String] = [String]()
    activityList.forEach { activity in
      let act:String = activity["start_date_local"] as! String
      activityDates.append(act)
    }
    
    let defaults = UserDefaults.standard
    defaults.set(Int(modf(Date().timeIntervalSince1970).0) + (60 * 60 * 24), forKey: "stravaSessionStart")
    defaults.set(activityDates, forKey: "stravaActivities")
    
    return activityDates
  }
  
  func updateActivity(id:Int, urlString:[String:String], store:Bool=false, async:Bool=false) -> Bool {
    let result = self.post(urlString: urlString, apiEndpoint: "activities/\(id)", put: true, async: async)

    var json:[String:Any] = [String:Any]()
    do {
      try json = result.get() as! [String : Any]
      if(store){
        let defaults = UserDefaults.standard
        var activityStartList:[String] = defaults.array(forKey: "stravaActivities") as! [String]
        activityStartList.append(json["start_date_local"] as! String)
        defaults.set(activityStartList, forKey: "stravaActivities")
      }
      return true
    } catch {
      return false
    }
  }
  
  func getRefreshToken(code:String) {
    let result = self.post(urlString: "grant_type=authorization_code&code=\(code)", apiEndpoint: "oauth/token", auth: true)

    var json:[String:Any] = [String:Any]()
    do {
      try json = result.get() as! [String : Any]
      self.setStoreTokens(json: json)
    } catch {}
  }
  
  func setStoreTokens(json:[String:Any]) {
    let defaults = UserDefaults.standard
    defaults.set(json["refresh_token"] as! String, forKey: "stravaRefreshToken")
    defaults.set(json["access_token"] as! String, forKey: "stravaAccessToken")
    defaults.set(json["expires_at"] as! Int, forKey: "stravaExpiresAt")
  }
  
  func json(str:String) -> Any {
    let data = Data(str.utf8)
    let jsonEmpty:Any = []
    do {
        // make sure this JSON is in the format we expect
      if let json = try JSONSerialization.jsonObject(with: data, options: []) as? Any {
        return json
      }
      return jsonEmpty
    } catch let error as NSError {
        print("Failed to load: \(error.localizedDescription)")
      return jsonEmpty
    }
  }
  
  func jsonString(json:[String: Any]) -> Data {
    do {
      let jsonData = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
      return jsonData
    } catch let error as NSError {
      print("Failed to load: \(error.localizedDescription)")
      return Data()
    }
  }
  
  func wait(_ seconds:Int) {
    let semaphore = DispatchSemaphore(value: 0)
    let timeout = DispatchTime.now() + .seconds(seconds)
    _ = semaphore.wait(timeout: timeout)
  }
}
