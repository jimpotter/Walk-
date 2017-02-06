//
//  InterfaceController.swift
//  Walk! WatchKit Extension
//
//  Created by jrp on 2/6/17.
//  Copyright © 2017 jrp. All rights reserved.
//

import WatchKit
import UserNotifications

class InterfaceController: WKInterfaceController, MotionContextDelegate, UNUserNotificationCenterDelegate {
    @IBOutlet var stepsLabel: WKInterfaceLabel!
    @IBOutlet var feetLabel: WKInterfaceLabel!
    @IBOutlet var metersLabel: WKInterfaceLabel!
    @IBOutlet var milesLabel: WKInterfaceLabel!
    
    fileprivate var healthKitManager = HealthKitManager()
    fileprivate var motionManager = MotionManager()
    fileprivate let calendar = NSCalendar.autoupdatingCurrent
    fileprivate var currentMotionSteps = 0
    fileprivate var currentMotionDistance = 0.0
    fileprivate var didDeactivateDate = Date()
    fileprivate var willActivateDateStamp  = ""
    fileprivate var didDeactivateDateStamp = ""
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        motionManager.delegate = self
        self.motionManager.startMonitoring()
        checkHealthKit()
    }
    
    // view has activated.
    // save the current dateStamp (we use that to tell when we cross a date boundary)
    // if the dateStamp is empty, then this is our first ctivate call.  Reset the counts with resetCounts == false
    // if we are still within the same date as when we de-activated, query the pedometer
    // if we happen to have crossed a date boundary just now, call resetCounts()
    override func willActivate() {
        super.willActivate()
        willActivateDateStamp = getCurrentDateStamp()
        if didDeactivateDateStamp == getCurrentDateStamp() {
            print("====>  willActivate: didDeactivateDateStamp \(didDeactivateDateStamp) == currentDateStamp \(getCurrentDateStamp())")
            self.motionManager.queryPedometer(from:didDeactivateDate, to:Date())
        }
        else {
            if didDeactivateDateStamp == "" {
                print("====>   willActivate: didDeactivateDateStamp blank,      currentDateStamp \(getCurrentDateStamp()): Zeroing out the currentSteps, checking HealthKit:")
                resetCounts(sendNotification:false)
            }
            else {
                print("====>   willActivate: didDeactivateDateStamp \(didDeactivateDateStamp) != currentDateStamp \(getCurrentDateStamp()): Zeroing out the currentSteps, checking HealthKit:")
                resetCounts()
            }
        }
    }
    
    // view has de-activated.
    // save the date (we use that to grab data from HealthKit)
    // save the current dateStamp (we use that to tell when we cross a date boundary)
    // if we happen to have crossed a date boundary just now, call resetCounts()
    override func didDeactivate() {
        super.didDeactivate()
        didDeactivateDate = Date()
        didDeactivateDateStamp = getCurrentDateStamp()
        if didDeactivateDateStamp != willActivateDateStamp {
            print("====>   didDeactivate: willActivateDateStamp \(willActivateDateStamp) != currentDateStamp \(getCurrentDateStamp()): Zeroing out the currentSteps, checking HealthKit:")
            resetCounts()
        }
        print("====> didDeactivate: didDeactivateDateStamp \(didDeactivateDateStamp).")
    }
    
    //  we are in a new day.
    // zero out today's current value
    // move over stored values in previous days
    // if this is our initial call on launch, sendNotification == false, don't send notification
    // if sendNotification == true, send a local notification to the DistanceModel & StepCountModel
    //    so that they can update their internal counts
    internal func resetCounts(sendNotification:Bool = true) {
        if sendNotification == true {
            NotificationCenter.default.post(name: .dayOfWeekUpdated, object: self, userInfo: nil)
        }
        didDeactivateDate = Date()
        didDeactivateDateStamp = getCurrentDateStamp()
        currentMotionSteps = 0
        currentMotionDistance = 0.0
        healthKitManager.healthKitStepCount = 0.0
        healthKitManager.healthKitDistance  = 0.0
        updateTheWatchDisplay(steps: currentMotionSteps, distance: currentMotionDistance)
        checkHealthKit()
    }
    
    // new Motion data has been received.  Update the view
    func notifyDelegate(_ manager: MotionManager) {
        let currentMotionSteps    = manager.recentPedometerData.numberOfSteps.intValue
        if let currentMotionDistance = manager.recentPedometerData.distance?.doubleValue {
            updateTheWatchDisplay(steps: currentMotionSteps, distance: currentMotionDistance)
        }
        else {
            WKInterfaceDevice.current().play(.failure)
        }
    }
    
    // we have encountered an authorization error.  Present an alert to the user
    func didEncounterAuthorizationError(_ manager: MotionManager, error:NSError) {
        presentAlert("ERROR", message:error.localizedDescription)
    }
}

extension InterfaceController {
    // get the current date stamp
    fileprivate func getCurrentDateStamp (date:Date = Date()) -> String {
        let shortFormatter = DateFormatter()
        shortFormatter.setLocalizedDateFormatFromTemplate("yyMMdd")
        let currentDateStamp = shortFormatter.string(from: date)
        return currentDateStamp
    }
    
    // update the watch display
    fileprivate func updateTheWatchDisplay (steps:Int, distance:Double) {
        let combinedStepCount = Int(steps + Int(healthKitManager.healthKitStepCount))
        let combinedDistance  = Double(distance + healthKitManager.healthKitDistance)
        
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
        DispatchQueue.main.async {
            self.stepsLabel.setText("\(combinedStepCount)")
            self.feetLabel.setText(feetString)
            self.metersLabel.setText(meterString)
            self.milesLabel.setText(milesString)
        }
    }
    
    // query HealthKit for updated values
    fileprivate func checkHealthKit () {
        healthKitManager.retrieveStepCount { (stepCount) -> Void in
            self.healthKitManager.healthKitStepCount = stepCount
            self.updateTheWatchDisplay(steps: self.currentMotionSteps, distance: self.currentMotionDistance)
        }
        healthKitManager.retrieveMeterDistance { (distance) -> Void in
            self.healthKitManager.healthKitDistance = distance
            self.updateTheWatchDisplay(steps: self.currentMotionSteps, distance: self.currentMotionDistance)
        }
    }
    
    // we have encountered an authorization error.  Present an alert to the user
    fileprivate func presentAlert(_ title:String, message:String) {
        let okAction = WKAlertAction(title: "OK", style: WKAlertActionStyle.default) { () -> Void in
            self.performAction(actionStyle: WKAlertActionStyle.default)
        }
        
        let cancelAction = WKAlertAction(title: "Cancel", style: WKAlertActionStyle.cancel) { () -> Void in
            self.performAction(actionStyle: WKAlertActionStyle.cancel)
        }
        
        let abortAction = WKAlertAction(title: "Abort", style: WKAlertActionStyle.destructive) { () -> Void in
            self.performAction(actionStyle: WKAlertActionStyle.destructive)
        }
        
        presentAlert(withTitle: title, message: message,
                     preferredStyle: WKAlertControllerStyle.alert,
                     actions: [okAction, cancelAction, abortAction])
    }
    
    // internal to presentAlert()
    fileprivate func performAction(actionStyle: WKAlertActionStyle) {
        switch actionStyle {
        case .default:
            print("OK")
        case .cancel:
            print("Cancel")
        case .destructive:
            print("Destructive")
        }
    }
}

