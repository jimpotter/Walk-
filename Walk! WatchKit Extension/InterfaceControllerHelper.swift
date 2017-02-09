//
//  InterfaceControllerHelper.swift
//  Walk!
//
//  Created by jrp on 2/9/17.
//  Copyright © 2017 jrp. All rights reserved.
//

import WatchKit

struct InterfaceControllerHelper {
    internal func getCurrentDateStamp (date:Date = Date()) -> String {
        let shortFormatter = DateFormatter()
        shortFormatter.setLocalizedDateFormatFromTemplate("yyMMdd")
        let currentDateStamp = shortFormatter.string(from: date)
        return currentDateStamp
    }

    internal func updateTheWatchDisplay (steps:Int, healthKitStepCount:Double, distance:Double, healthKitDistance:Double, weeklyStepCountMax:Double, completion: @escaping (Int, _ stepCountColor:UIColor, _ feet:String, _ meters:String, _ miles:String) -> Void) {
        
        let combinedStepCount = Int(steps + Int(healthKitStepCount))
        let combinedDistance  = Double(distance + healthKitDistance)
        
        NotificationCenter.default.post(name: .stepCountUpdated, object: self, userInfo: [Constant.StepCount.rawValue:Double(combinedStepCount)])
        NotificationCenter.default.post(name: .distanceUpdated, object: self, userInfo: [Constant.Distance.rawValue:(combinedDistance / 1609.344)])
        
        let feetTraveled = combinedDistance * 3.28084
        var feetString = String(format:"%.2f FT", feetTraveled)
        if feetTraveled >= 100.0 {
            feetString = String(format:"%i FT",  Int(feetTraveled))
        }
        
        var meterString = "meters"
        switch combinedDistance {
        case 0..<100:
            meterString = String(format:"%.2f M", combinedDistance)
        case 100..<1000:
            meterString = String(format:"%i M", Int(combinedDistance))
        default:
            meterString = String(format:"%.2f KM", combinedDistance / 1000.0)
        }
        
        let milesString = String(format:"%.2f Mi", combinedDistance / 1609.344)
        
        var grade = fabsf(Float(combinedStepCount) / Float(weeklyStepCountMax))
        if grade.isNaN {
            grade = 0
        }
        
        var stepCountColor = UIColor.topColor
        switch grade {
        case 0.0..<0.5:
            stepCountColor = UIColor.darkRedColor
        case 0.5..<0.75:
            stepCountColor = UIColor.middleColor
        default:
            stepCountColor = UIColor.topColor
        }
        completion(combinedStepCount, stepCountColor, feetString, meterString, milesString)
    }
}
