//
//  HealthKitTests.swift
//  Walk!
//
//  Created by jrp on 2/11/17.
//  Copyright © 2017 jrp. All rights reserved.
//

import XCTest
import HealthKit

struct MockHealthKitManager:HealthKitMgr {
    // retrieve accumulated meters distance or step countsin HealthKit.
    func retrieveHealthKitValue(startDate:Date,
                                endDate:Date,
                                quantityFor:HKUnit,
                                quantityTypeIdentifier:HKQuantityTypeIdentifier,
                                completion: @escaping (_ quantityValue: Double) -> Void) {
                let quantityValue = 0.0
                completion(quantityValue)
    }
}

class RetrieveHealthKitValueTests: XCTestCase {
    func testCheckHealthKitForStepCount() {
        let interfaceControllerHelper = InterfaceControllerHelper()
        let mockHealthKitManager = MockHealthKitManager()
        
        var expectedstepCount = 0.0
        mockHealthKitManager.retrieveHealthKitValue(
            startDate: Date(),
            endDate: Date(),
            quantityFor: HKUnit.count(),
            quantityTypeIdentifier:HKQuantityTypeIdentifier.stepCount) { (quantityValue) -> Void in
                expectedstepCount = quantityValue
        }
        
        interfaceControllerHelper.checkHealthKitForStepCount(healthKitManager: mockHealthKitManager) { (stepCount) -> Void in
            XCTAssertEqual(stepCount, expectedstepCount, "checkHealthKitForStepCount specified quantityTypeIdentifier of HKUnit.count, stepCount should be 2478.4")
        }
    }
    
    func testCheckHealthKitForDistance() {
        let interfaceControllerHelper = InterfaceControllerHelper()
        let mockHealthKitManager = MockHealthKitManager()
        
        var expectedDistance = 0.0
        mockHealthKitManager.retrieveHealthKitValue(
            startDate: Date(),
            endDate: Date(),
            quantityFor: HKUnit.meter(),
            quantityTypeIdentifier:HKQuantityTypeIdentifier.distanceWalkingRunning) { (quantityValue) -> Void in
                expectedDistance = quantityValue
        }
        
        interfaceControllerHelper.checkHealthKitForDistance(healthKitManager: mockHealthKitManager) { (distance) -> Void in
            XCTAssertEqual(distance, expectedDistance, "checkHealthKitForDistance specified quantityTypeIdentifier of HKUnit.meter, distance should be 2340.54")
        }
    }

    func testCheckDistance() {
        let distanceModelHelper = DistanceModelHelper()
        let mockHealthKitManager = MockHealthKitManager()
        let weeklyDistance: [Double] = [7.0, 7.0, 7.0, 0.0, 7.0, 7.0, 7.0]

        var expectedDistance = 0.0
        mockHealthKitManager.retrieveHealthKitValue(
            startDate: Date(),
            endDate: Date(),
            quantityFor: HKUnit.mile(),
            quantityTypeIdentifier:HKQuantityTypeIdentifier.distanceWalkingRunning) { (quantityValue) -> Void in
                expectedDistance = quantityValue
        }
        
        distanceModelHelper.checkDistance (healthKitManager: mockHealthKitManager, weeklyDistance:weeklyDistance) { (index, distance) -> Void in
            // the only zero value in weeklyDistance was the fourth value, index should be 3
            XCTAssertEqual(index, 3, "the only zero value in weeklyDistance was the fourth value, index should be 3")
            XCTAssertEqual(distance, expectedDistance, "checkDistance specified quantityTypeIdentifier of HKUnit.mile, distance should be 2.54")
        }
    }
    
    func testCheckStepCounts() {
        let stepCountModelHelper = StepCountModelHelper()
        let mockHealthKitManager = MockHealthKitManager()
        let weeklyStepCounts: [Double] = [7.0, 7.0, 7.0, 7.0, 7.0, 0.0, 7.0]

        var expectedstepCount = 0.0
        mockHealthKitManager.retrieveHealthKitValue(
            startDate: Date(),
            endDate: Date(),
            quantityFor: HKUnit.count(),
            quantityTypeIdentifier:HKQuantityTypeIdentifier.stepCount) { (quantityValue) -> Void in
                expectedstepCount = quantityValue
        }
        
        stepCountModelHelper.checkStepCounts (healthKitManager: mockHealthKitManager, weeklyStepCounts:weeklyStepCounts) { (index, stepCount) -> Void in
            XCTAssertEqual(index, 5, "the only zero value in weeklyStepCounts was the sixth value, index should be 5")
            XCTAssertEqual(stepCount, expectedstepCount, "checkStepCounts specified quantityTypeIdentifier of HKUnit.count, stepCount should be 2478.4")
        }
    }
    
    struct MockHealthKitManager:HealthKitMgr {
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        
        // retrieve accumulated meters distance or step countsin HealthKit.
        // called by retrieveStepCount(), retrieveMeterDistance(), DistanceModel and StepCountModel classes
        func retrieveHealthKitValue(startDate:Date, endDate:Date, quantityFor:HKUnit, quantityTypeIdentifier:HKQuantityTypeIdentifier, completion: @escaping (_ quantityValue: Double) -> Void) {
            
            switch quantityFor {
            case HKUnit.meter():
                completion(2340.54)
            case HKUnit.mile():
                completion(2.54)
            case HKUnit.count():
                completion(2478.4)
            default: break
            }
        }
    }
}
