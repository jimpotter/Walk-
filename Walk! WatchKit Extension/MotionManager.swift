//
//  MotionManager.swift
//  Walk WatchKit Extension
//
//  Created by jrp on 2/6/17.
//  Copyright © 2017 jrp. All rights reserved.
//

import CoreMotion

protocol MotionContextDelegate: class {
    func didEncounterAuthorizationError(_ manager: MotionManager, error:NSError)
    func notifyDelegate(_ manager: MotionManager)
}

struct MotionManager {
    fileprivate let pedometer = CMPedometer()
    weak var delegate: MotionContextDelegate?
    var recentPedometerData = CMPedometerData()
    
    // query the devices pedometer for any accumulated values
    func queryPedometer(from:Date, to:Date) {
        pedometer.queryPedometerData(from: from, to: to) { pedometerData, error in
            if let error = error {
                self.delegate?.didEncounterAuthorizationError(self, error: error as NSError)
            }
        }
    }
    
    // start monitoring the pedometer for values
    mutating func startMonitoring() {
        // If step counting is available, start pedometer updates from now forward.
        if CMPedometer.isStepCountingAvailable() {
            let now = Date()

            //This creates a concurrent Queue.  Required to write to struct vars is Swift 3.  
            // see http://stackoverflow.com/questions/38058280/modifying-struct-instance-variables-within-a-dispatch-closure-in-swift
            let connectQueue = DispatchQueue(label: "connectQueue", attributes: .concurrent)
            pedometer.startUpdates(from: now) { pedometerData, error in
                connectQueue.sync {
                    if let localPedometerData = pedometerData {
                        self.recentPedometerData = localPedometerData
                        self.delegate?.notifyDelegate(self)
                    }
                    else if let error = error {
                        self.delegate?.didEncounterAuthorizationError(self, error: error as NSError)
                    }
                }
            }
        }
        else {
            print("Step counting is not available.")
        }
    }
}
