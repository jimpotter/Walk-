//
//  InterfaceController.swift
//  Walk! WatchKit Extension
//
//  Created by jrp on 2/6/17.
//  Copyright © 2017 jrp. All rights reserved.
//

import WatchKit
import UserNotifications

class InterfaceController: WKInterfaceController {
    
    @IBOutlet var stepsLabel: WKInterfaceLabel!
    @IBOutlet var feetLabel: WKInterfaceLabel!
    @IBOutlet var metersLabel: WKInterfaceLabel!
    @IBOutlet var milesLabel: WKInterfaceLabel!
    
    fileprivate var healthKitManager = HealthKitManager()
    fileprivate var motionManager = MotionManager()
    fileprivate let interfaceControllerHelper = InterfaceControllerHelper()
    fileprivate var didDeactivateDate = Date()
    fileprivate var willActivateDateStamp  = ""
    fileprivate var didDeactivateDateStamp = ""
    fileprivate var weeklyStepCountMax:Double = 0.0
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        motionManager.delegate = self
        self.motionManager.startMonitoring()
        checkHealthKit()

        NotificationCenter.default.addObserver(self, selector: #selector(AppBecomeActive(_:)), name: .becomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleUpdatedWeeklyStepCountMax(_:)), name: .weeklyStepCountMaxUpdated, object: nil)
    }
    
    // view has activated.
    // save the current dateStamp (we use that to tell when we cross a date boundary)
    // if the dateStamp is empty, then this is our first ctivate call.  Reset the counts with resetCounts == false
    // if we are still within the same date as when we de-activated, query the pedometer
    // if we happen to have crossed a date boundary just now, call resetCounts()
    override func willActivate() {
        super.willActivate()
        willActivateDateStamp = interfaceControllerHelper.getCurrentDateStamp()
        if didDeactivateDateStamp == interfaceControllerHelper.getCurrentDateStamp() {
            print("====>  willActivate: didDeactivateDateStamp \(didDeactivateDateStamp) == currentDateStamp \(interfaceControllerHelper.getCurrentDateStamp())")
            self.motionManager.queryPedometer(from:didDeactivateDate, to:Date())
        }
        else {
            if didDeactivateDateStamp == "" {
                print("====>   willActivate: didDeactivateDateStamp blank,      currentDateStamp \(interfaceControllerHelper.getCurrentDateStamp()): Zeroing out the currentSteps, checking HealthKit:")
                resetCounts(sendNotification:false)
            }
            else {
                print("====>   willActivate: didDeactivateDateStamp \(didDeactivateDateStamp) != currentDateStamp \(interfaceControllerHelper.getCurrentDateStamp()): Zeroing out the currentSteps, checking HealthKit:")
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
        didDeactivateDateStamp = interfaceControllerHelper.getCurrentDateStamp()
        if didDeactivateDateStamp != willActivateDateStamp {
            print("====>   didDeactivate: willActivateDateStamp \(willActivateDateStamp) != currentDateStamp \(interfaceControllerHelper.getCurrentDateStamp()): Zeroing out the currentSteps, checking HealthKit:")
            resetCounts()
        }
        print("====> didDeactivate: didDeactivateDateStamp \(didDeactivateDateStamp).")
    }
}

extension InterfaceController:UNUserNotificationCenterDelegate {
    func handleUpdatedWeeklyStepCountMax(_ notification: Notification) {
        guard let userInfo = notification.userInfo, let weeklyStepCountMax  = userInfo[Constant.WeeklyStepCountMax.rawValue] as? Double else { return }
        
        print("handleUpdatedWeeklyStepCountMax: weeklyStepCountMax now \(weeklyStepCountMax)")
        self.weeklyStepCountMax = weeklyStepCountMax
    }

    internal func AppBecomeActive(_ notification: Notification) {
        DispatchQueue.main.async {
            self.becomeCurrentPage()        // return to this view when app becomes active
        }
    }
}

extension InterfaceController:MotionContextDelegate {
    func didEncounterAuthorizationError(_ manager: MotionManager, error:NSError) {  // we have encountered an authorization error
        presentAlert("ERROR", message:error.localizedDescription)                   // Present an alert to the user
    }
}

extension InterfaceController {
    func notifyDelegate(_ manager: MotionManager) {    // new Motion data has been received.  Update the view
        let motionSteps    = manager.recentPedometerData.numberOfSteps.intValue
        if let motionDistance = manager.recentPedometerData.distance?.doubleValue {
            updateTheWatchDisplay(motionSteps:motionSteps,
                                  motionDistance:motionDistance)
        }
        else {
            WKInterfaceDevice.current().play(.failure)
        }
    }

    //  we are in a new day.
    // zero out today's current value
    // move over stored values in previous days
    // if this is our initial call on launch, sendNotification == false, don't send notification
    // if sendNotification == true, send a local notification to the DistanceModel & StepCountModel
    //    so that they can update their internal counts
    fileprivate func resetCounts(sendNotification:Bool = true) {
        if sendNotification == true {
            NotificationCenter.default.post(name: .dayOfWeekUpdated, object: self, userInfo: nil)
        }
        didDeactivateDate = Date()
        didDeactivateDateStamp = interfaceControllerHelper.getCurrentDateStamp()
        healthKitManager.healthKitStepCount = 0.0
        healthKitManager.healthKitDistance  = 0.0
        
        updateTheWatchDisplay(motionSteps:0, motionDistance:0.0)
        checkHealthKit()
    }
    
    fileprivate func updateTheWatchDisplay(motionSteps:Int, motionDistance:Double) {
        interfaceControllerHelper.updateTheWatchDisplay(
            steps: motionSteps, healthKitStepCount: healthKitManager.healthKitStepCount,
            distance: motionDistance, healthKitDistance: healthKitManager.healthKitDistance,
            weeklyStepCountMax:self.weeklyStepCountMax) { (stepCount, stepCountColor, feet, meters, miles) -> Void in
                DispatchQueue.main.async {
                    self.setStepsLabel(string:String(stepCount), color:stepCountColor)
                    self.feetLabel.setText(feet)
                    self.metersLabel.setText(meters)
                    self.milesLabel.setText(miles)
                }
        }
    }
    
    fileprivate func setStepsLabel(string:String, color:UIColor) {
        let attributes = [NSForegroundColorAttributeName : color]
        let stepsLabelAttributedString = NSAttributedString(string: string, attributes: attributes)
        self.stepsLabel.setAttributedText(stepsLabelAttributedString)
    }
    
    // query HealthKit for updated values
    fileprivate func checkHealthKit () {
        healthKitManager.retrieveStepCount { (stepCount) -> Void in
            self.healthKitManager.healthKitStepCount = stepCount
            self.updateTheWatchDisplay(motionSteps:0, motionDistance:0.0)
        }
        healthKitManager.retrieveMeterDistance { (distance) -> Void in
            self.healthKitManager.healthKitDistance = distance
            self.updateTheWatchDisplay(motionSteps:0, motionDistance:0.0)
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

