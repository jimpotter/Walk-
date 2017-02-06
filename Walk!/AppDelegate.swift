//
//  AppDelegate.swift
//  Walk!
//
//  Created by jrp on 2/6/17.
//  Copyright © 2017 jrp. All rights reserved.
//

import UIKit
import CoreMotion
import HealthKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    let healthStore = HKHealthStore()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        requestMotion()
        requestHealhKit()
        return true
    }
    
    fileprivate func requestHealhKit() {
        self.authorizeHealthKit { (authorized) -> Void in
            if authorized {
                print("HealthKit authorization received.")
            }
            else {
                print("HealthKit authorization denied!")
            }
        }
    }
    
    fileprivate func authorizeHealthKit(completion: @escaping ((_ success:Bool) -> Swift.Void)) {
        let writableTypes: Set<HKSampleType> = []
        let readableTypes: Set<HKSampleType> = [HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning)!,
                                                HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!]
        
        if !HKHealthStore.isHealthDataAvailable(){
            completion(false)
            return;
        }
        
        healthStore.requestAuthorization(toShare: writableTypes, read: readableTypes) { (success, error) -> Void in
            completion(success)
        }
    }
    
    fileprivate func requestMotion () {
        let motionQueue: OperationQueue = {
            let motionQueue = OperationQueue()
            motionQueue.name = "motionQueue"
            return motionQueue
        }()
        let motionManager = CMMotionActivityManager()
        if CMMotionActivityManager.isActivityAvailable() {
            motionManager.startActivityUpdates(to: motionQueue) { activity in
                motionManager.stopActivityUpdates()
            }
        }
        else {
            print("Activity updates are not available.")
        }
    }
}

