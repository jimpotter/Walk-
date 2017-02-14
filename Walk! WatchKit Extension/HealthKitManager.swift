//
//  HealthKitManager.swift
//  Walk WatchKit Extension
//
//  Created by jrp on 2/6/17.
//  Copyright © 2017 jrp. All rights reserved.
//

import HealthKit

protocol HealthKitMgr {
    func retrieveHealthKitValue(startDate:Date, endDate:Date, quantityFor:HKUnit, quantityTypeIdentifier:HKQuantityTypeIdentifier, completion: @escaping (_ quantityValue: Double) -> Void)
}

struct HealthKitManager:HealthKitMgr {
    fileprivate let healthStore = HKHealthStore()
    fileprivate let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
    
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
                    print("retrieveHealthKitValue error: \(error?.localizedDescription)")
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
                else {
                    print("Could not recognise HKStatisticsCollectionQuery results \(results)!")
                }
            }
            healthStore.execute(query)
        }
    }
}

