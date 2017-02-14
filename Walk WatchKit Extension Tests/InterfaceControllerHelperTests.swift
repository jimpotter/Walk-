//
//  InterfaceControllerHelperTests.swift
//  Walk!
//
//  Created by jrp on 2/9/17.
//  Copyright © 2017 jrp. All rights reserved.
//

import XCTest

class InterfaceControllerHelperTests: XCTestCase {
    let interfaceControllerHelper = InterfaceControllerHelper()
    let shortFormatter = DateFormatter()
    
    func testUpdateTheWatchDisplay_stepCount() {
        let motionSteps        = 500
        let healthKitStepCount = 1000.5
        
        let motionDistance     = 600.6
        let healthKitDistance  = 1200.8
        
        let weeklyStepCountMax = 4000.0
        
        let expectedSteps    = motionSteps + Int(healthKitStepCount)
        
        interfaceControllerHelper.updateTheWatchDisplay(
            steps: motionSteps, initialHealthKitStepCount: healthKitStepCount,
            distance: motionDistance, initialHealthKitDistance: healthKitDistance,
            weeklyStepCountMax:weeklyStepCountMax) { (stepCount, stepCountColor, feet, meters, miles) -> Void in
                XCTAssertEqual(expectedSteps, stepCount)
        }
    }
    
    func testUpdateTheWatchDisplay_feet() {
        let motionSteps        = 500
        let healthKitStepCount = 1000.5
        
        let motionDistance     = 600.6
        let healthKitDistance  = 1200.8
        
        let weeklyStepCountMax = 4000.0
        
        let expectedFeetString  = "5910 FT"
        
        interfaceControllerHelper.updateTheWatchDisplay(
            steps: motionSteps, initialHealthKitStepCount: healthKitStepCount,
            distance: motionDistance, initialHealthKitDistance: healthKitDistance,
            weeklyStepCountMax:weeklyStepCountMax) { (stepCount, stepCountColor, feet, meters, miles) -> Void in
                XCTAssertEqual(feet, expectedFeetString)
        }
    }
    
    func testUpdateTheWatchDisplay_meters() {
        let motionSteps        = 500
        let healthKitStepCount = 1000.5
        
        let motionDistance     = 600.6
        let healthKitDistance  = 1200.8
        
        let weeklyStepCountMax = 4000.0
        
        let expectedMeterString = "1.80 KM"
        interfaceControllerHelper.updateTheWatchDisplay(
            steps: motionSteps, initialHealthKitStepCount: healthKitStepCount,
            distance: motionDistance, initialHealthKitDistance: healthKitDistance,
            weeklyStepCountMax:weeklyStepCountMax) { (stepCount, stepCountColor, feet, meters, miles) -> Void in
                XCTAssertEqual(meters, expectedMeterString)
        }
    }
    
    func testUpdateTheWatchDisplay_miles() {
        let motionSteps        = 500
        let healthKitStepCount = 1000.5
        
        let motionDistance     = 600.6
        let healthKitDistance  = 1200.8
        
        let weeklyStepCountMax = 4000.0
        
        let expectedMilesString = "1.12 Mi"
        
        interfaceControllerHelper.updateTheWatchDisplay(
            steps: motionSteps, initialHealthKitStepCount: healthKitStepCount,
            distance: motionDistance, initialHealthKitDistance: healthKitDistance,
            weeklyStepCountMax:weeklyStepCountMax) { (stepCount, stepCountColor, feet, meters, miles) -> Void in
                XCTAssertEqual(miles, expectedMilesString)
        }
    }
    
    func testUpdateTheWatchDisplay_darkRedColor() {
        let motionSteps        = 500
        let healthKitStepCount = 1000.5
        
        let motionDistance     = 600.6
        let healthKitDistance  = 1200.8
        
        let weeklyStepCountMax = 4000.0
        
        interfaceControllerHelper.updateTheWatchDisplay(
            steps: motionSteps, initialHealthKitStepCount: healthKitStepCount,
            distance: motionDistance, initialHealthKitDistance: healthKitDistance,
            weeklyStepCountMax:weeklyStepCountMax) { (stepCount, stepCountColor, feet, meters, miles) -> Void in
                XCTAssertEqual(stepCountColor, UIColor.darkRedColor)
        }
    }
    
    func testUpdateTheWatchDisplay_middleColor() {
        let motionSteps        = 1000
        let healthKitStepCount = 1500.5
        
        let motionDistance     = 600.6
        let healthKitDistance  = 1200.8
        
        let weeklyStepCountMax = 4000.0
        
        interfaceControllerHelper.updateTheWatchDisplay(
            steps: motionSteps, initialHealthKitStepCount: healthKitStepCount,
            distance: motionDistance, initialHealthKitDistance: healthKitDistance,
            weeklyStepCountMax:weeklyStepCountMax) { (stepCount, stepCountColor, feet, meters, miles) -> Void in
                XCTAssertEqual(stepCountColor, UIColor.middleColor)
        }
    }
    
    func testUpdateTheWatchDisplay_topColor() {
        let motionSteps        = 1500
        let healthKitStepCount = 1700.5
        
        let motionDistance     = 600.6
        let healthKitDistance  = 1200.8
        
        let weeklyStepCountMax = 4000.0
        
        interfaceControllerHelper.updateTheWatchDisplay(
            steps: motionSteps, initialHealthKitStepCount: healthKitStepCount,
            distance: motionDistance, initialHealthKitDistance: healthKitDistance,
            weeklyStepCountMax:weeklyStepCountMax) { (stepCount, stepCountColor, feet, meters, miles) -> Void in
                XCTAssertEqual(stepCountColor, UIColor.topColor)
        }
    }
    
    func testGetCurrentDateStamp_Today() {
        shortFormatter.setLocalizedDateFormatFromTemplate("yyMMdd")
        let date = Date()
        let expectedDateStamp = shortFormatter.string(from: date)
        let returnedDateStamp = interfaceControllerHelper.getCurrentDateStamp(date: date)
        
        XCTAssertEqual(returnedDateStamp, expectedDateStamp)
    }

    func testGetCurrentDateStamp_Yesterday() {
        shortFormatter.setLocalizedDateFormatFromTemplate("yyMMdd")
        let date = Date().yesterday
        let expectedDateStamp = shortFormatter.string(from: date)
        let returnedDateStamp = interfaceControllerHelper.getCurrentDateStamp(date: date)
        
        XCTAssertEqual(returnedDateStamp, expectedDateStamp)
    }

    func testGetCurrentDateStamp_Tomorrow() {
        shortFormatter.setLocalizedDateFormatFromTemplate("yyMMdd")
        let date = Date().tomorrow
        let expectedDateStamp = shortFormatter.string(from: date)
        let returnedDateStamp = interfaceControllerHelper.getCurrentDateStamp(date: date)
        
        XCTAssertEqual(returnedDateStamp, expectedDateStamp)
    }
}
extension Date {
    var yesterday:Date {
        let calendar = NSCalendar.current
        return calendar.date(byAdding: .day, value: -1, to: Date())!
    }
    
    var tomorrow:Date {
        let calendar = NSCalendar.current
        return calendar.date(byAdding: .day, value: 1, to: Date())!
    }
}
