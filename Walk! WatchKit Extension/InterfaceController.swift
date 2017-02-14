//
//  InterfaceController.swift
//  Walk! WatchKit Extension
//
//  Created by jrp on 2/6/17.
//  Copyright © 2017 jrp. All rights reserved.
//

import WatchKit
import WatchConnectivity
import UserNotifications
import HealthKit

class InterfaceController: WKInterfaceController, WCSessionDelegate {
    
    // set to true to copy messages to the iPhone.
    // companion iPhone app sends them to NSLogger on the Mac & a file in the Documents Directory, where you can grab it usint iTunes
    let sendMessagesToParentPhone = false
    
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
    
    var initialHealthKitStepCount = 0.0
    var initialHealthKitDistance = 0.0

    // MARK: - Properties
    var session : WCSession!

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        if WCSession.isSupported() {        // configure and activate the session
            session = WCSession.default()
            session.delegate = self
            session.activate()
        }

        motionManager.delegate = self
        self.motionManager.startMonitoring()
        checkHealthKit(healthKitManager: healthKitManager)

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
            
//            print("====>  willActivate: didDeactivateDateStamp \(didDeactivateDateStamp) == currentDateStamp \(interfaceControllerHelper.getCurrentDateStamp())")
            sendMessage(messageToSend:"====>  willActivate: didDeactivateDateStamp \(didDeactivateDateStamp) == currentDateStamp \(interfaceControllerHelper.getCurrentDateStamp())")
            
            self.motionManager.queryPedometer(from:didDeactivateDate, to:Date())
        }
        else {
            if didDeactivateDateStamp == "" {
                
//                print("====>   willActivate: didDeactivateDateStamp blank,      currentDateStamp \(interfaceControllerHelper.getCurrentDateStamp()): Zeroing out the currentSteps, checking HealthKit:")
                sendMessage(messageToSend:"====>   willActivate: didDeactivateDateStamp blank,      currentDateStamp \(interfaceControllerHelper.getCurrentDateStamp()): Zeroing out the currentSteps, checking HealthKit:")
                
                resetCounts(sendNotification:false)
            }
            else {
                
//                print("====>   willActivate: didDeactivateDateStamp \(didDeactivateDateStamp) != currentDateStamp \(interfaceControllerHelper.getCurrentDateStamp()): Zeroing out the currentSteps, checking HealthKit:")
                sendMessage(messageToSend:"====>   willActivate: didDeactivateDateStamp \(didDeactivateDateStamp) != currentDateStamp \(interfaceControllerHelper.getCurrentDateStamp()): Zeroing out the currentSteps, checking HealthKit:")
                
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
            
//            print("====>   didDeactivate: willActivateDateStamp \(willActivateDateStamp) != currentDateStamp \(interfaceControllerHelper.getCurrentDateStamp()): Zeroing out the currentSteps, checking HealthKit:")
            sendMessage(messageToSend:"====>   didDeactivate: willActivateDateStamp \(willActivateDateStamp) != currentDateStamp \(interfaceControllerHelper.getCurrentDateStamp()): Zeroing out the currentSteps, checking HealthKit:")
            
            resetCounts()
        }
        
//        print("====> didDeactivate: didDeactivateDateStamp \(didDeactivateDateStamp).")
        sendMessage(messageToSend:"====> didDeactivate: didDeactivateDateStamp \(didDeactivateDateStamp).")
        
    }
    
    // Called when the session has completed activation. If session state is WCSessionActivationStateNotActivated there will be an error with more details.
    @available(watchOS 2.2, *)
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        //..code
    }
}

extension InterfaceController:UNUserNotificationCenterDelegate {
    func handleUpdatedWeeklyStepCountMax(_ notification: Notification) {
        guard let userInfo = notification.userInfo, let weeklyStepCountMax  = userInfo[Constant.WeeklyStepCountMax.rawValue] as? Double else { return }
        
//        print("handleUpdatedWeeklyStepCountMax: weeklyStepCountMax now \(weeklyStepCountMax)")
        sendMessage(messageToSend:"handleUpdatedWeeklyStepCountMax: weeklyStepCountMax now \(weeklyStepCountMax)")
        
        self.weeklyStepCountMax = weeklyStepCountMax
        updateTheWatchDisplay(motionSteps:0, motionDistance:0.0)
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
}

extension InterfaceController {
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
        
        updateTheWatchDisplay(motionSteps:0, motionDistance:0.0)
        checkHealthKit(healthKitManager: healthKitManager)
    }
    
    fileprivate func updateTheWatchDisplay(motionSteps:Int, motionDistance:Double) {
        interfaceControllerHelper.updateTheWatchDisplay(
            steps: motionSteps, initialHealthKitStepCount: self.initialHealthKitStepCount,
            distance: motionDistance, initialHealthKitDistance: self.initialHealthKitDistance,
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
    fileprivate func checkHealthKit (healthKitManager:HealthKitMgr) {
        
//        print("checkHealthKit:")
        sendMessage(messageToSend:"checkHealthKit:")
        
        interfaceControllerHelper.checkHealthKitForStepCount(healthKitManager: healthKitManager) { (stepCount) -> Void in

            self.sendMessage(messageToSend:"checkHealthKitForStepCount: \(stepCount) steps.")

            self.initialHealthKitStepCount = stepCount
            self.updateTheWatchDisplay(motionSteps:0, motionDistance:0.0)
        }
        
        interfaceControllerHelper.checkHealthKitForDistance(healthKitManager: healthKitManager) { (distance) -> Void in
            
            self.sendMessage(messageToSend:"checkHealthKitForDistance: \(distance) meters.")
            
            self.initialHealthKitDistance = distance
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

//MARK: - WatchActions -> InterfaceController
//typealias WatchActions = InterfaceController
//extension WatchActions {
//    @IBAction func sendToParent() {    // Send message to paired iOS App (Parent)
//        sendMessage()
//    }
//}

//MARK: - WatchSessionProtocol -> InterfaceController
typealias WatchSessionProtocol = InterfaceController
extension WatchSessionProtocol {
    
    // WCSession Delegate protocol
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
//        let value = message["Message"] as? String        // Reply handler, received message
        
        // do something with the received message...?
        
        // Send a reply
        replyHandler(["Message":"Yes!\niOS 9.0 + WatchOS2 ..AAAAAAmazing!"])
        
    }
}


//MARK: - WatchSessionTasks -> InterfaceController
typealias WatchSessionTasks = InterfaceController
extension WatchSessionTasks {
    
    // Method to send message to paired iOS App (Parent)
    func sendMessage(messageToSend:String) {
        
        print(messageToSend)    // print message to the console
        
        if sendMessagesToParentPhone == true {

            // set to true to copy messages to the iPhone.
            // companion iPhone app sends them to NSLogger on the Mac & a file in the Documents Directory, where you can grab it usint iTunes

            let messageDict = ["Message":messageToSend]
            
            // Task : Sends a message immediately to the counterpart and optionally delivers a response
            session.sendMessage(messageDict, replyHandler: { (replyMessage) in
                
                // Reply handler - present the reply message on screen
                // let value = replyMessage["Message"] as? String
                // do something with the received message...?

            }) { (error) in
                // Catch any error Handler
                print("error: \(error.localizedDescription)")
            }
        }
    }
}
