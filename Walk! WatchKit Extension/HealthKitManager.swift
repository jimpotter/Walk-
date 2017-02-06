//
//  HealthKitManager.swift
//  Walk WatchKit Extension
//
//  Created by jrp on 2/6/17.
//  Copyright © 2017 jrp. All rights reserved.
//

import HealthKit

struct HealthKitManager {
    var healthKitStepCount = 0.0
    var healthKitDistance = 0.0
    fileprivate let healthStore = HKHealthStore()
    fileprivate let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
    
    // retrieve accumulated step counts in HealthKit.  
    // called from the main InterfaceController, Convenience accessor for retrieveHealthKitValue()
    mutating func retrieveStepCount(completion: @escaping (_ quantityValue: Double) -> Void) {
        let startOfToday = calendar.startOfDay(for: Date())
        
        retrieveHealthKitValue(
            startDate: startOfToday,
            endDate: Date(),
            quantityFor: HKUnit.count(),
            quantityTypeIdentifier:HKQuantityTypeIdentifier.stepCount) { (quantityValue) -> Void in
                completion(quantityValue)
        }
    }
    
    // retrieve accumulated meters distance in HealthKit.
    // called from the main InterfaceController, Convenience accessor for retrieveHealthKitValue()
    mutating func retrieveMeterDistance(completion: @escaping (_ quantityValue: Double) -> Void) {
        let startOfToday = calendar.startOfDay(for: Date())
        
        retrieveHealthKitValue(
            startDate: startOfToday,
            endDate: Date(),
            quantityFor: HKUnit.meter(),
            quantityTypeIdentifier:HKQuantityTypeIdentifier.distanceWalkingRunning) { (quantityValue) -> Void in
                completion(quantityValue)
        }
    }
    
    // retrieve accumulated meters distance or step countsin HealthKit.
    // called by retrieveStepCount(), retrieveMeterDistance(), DistanceModel and StepCountModel classes
    func retrieveHealthKitValue(startDate:Date, endDate:Date, quantityFor:HKUnit, quantityTypeIdentifier:HKQuantityTypeIdentifier, completion: @escaping (_ quantityValue: Double) -> Void) {

        //   Setup the Quantity Type
        if let quantityType = HKQuantityType.quantityType(forIdentifier: quantityTypeIdentifier) {
            //  Set the Predicates & Interval
            let predicate = HKQuery.predicateForSamples(withStart: startDate as Date, end: endDate, options: .strictStartDate)
            let interval: NSDateComponents = NSDateComponents()
            interval.day = 1
            
            //  Perform the Query
            let query = HKStatisticsCollectionQuery(quantityType: quantityType,
                                                    quantitySamplePredicate: predicate,
                                                    options: [.cumulativeSum],
                                                    anchorDate: startDate as Date,
                                                    intervalComponents:interval as DateComponents)
            
            query.initialResultsHandler = { query, results, error in
                if error != nil {
                    return          //  Something went Wrong
                }
                if let myResults = results {
                    myResults.enumerateStatistics(from: startDate as Date, to: endDate as Date) {
                        statistics, stop in
                        if let quantity = statistics.sumQuantity() {
                            let quantityValue = quantity.doubleValue(for: quantityFor)
                            completion(quantityValue)
                        }
                    }
                }
            }
            healthStore.execute(query)
        }
    }
}

