//
//  StepCountModel.swift
//  Walk WatchKit Extension
//
//  Created by jrp on 2/6/17.
//  Copyright © 2017 jrp. All rights reserved.
//

import HealthKit

class StepCountModel: NSObject {
    fileprivate let healthKitManager = HealthKitManager()
    fileprivate var stepCountBarChartController: StepCountBarChartController
    var weeklyStepCountMax:Double = 0.0
    var weeklyStepCounts: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0] {
        didSet {
            UserDefaults.standard.set(weeklyStepCounts, forKey: Constant.WeeklyStepCounts.rawValue)
            
            let sorted = weeklyStepCounts.sorted(by: { $0 > $1 })
            if weeklyStepCountMax != sorted[0] {
                weeklyStepCountMax = sorted[0]
                
// fake fake fake
//                print("weeklyStepCountMax: \(weeklyStepCountMax)")
//                weeklyStepCountMax = 2500.0
// fake fake fake

                NotificationCenter.default.post(name: .weeklyStepCountMaxUpdated,
                                            object: self,
                                            userInfo: [Constant.WeeklyStepCountMax.rawValue:weeklyStepCountMax])
            }
        }
    }
    
    init(controller:StepCountBarChartController) {
        stepCountBarChartController = controller
        super.init()
        weeklyStepCounts = UserDefaults.standard.array(forKey: Constant.WeeklyStepCounts.rawValue)  as? [Double] ?? [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        print("stepCountModel: init: weeklyStepCounts \(weeklyStepCounts)")
        
        // Watch for new day
        NotificationCenter.default.addObserver(self, selector: #selector(handleNewDay(_:)), name: .dayOfWeekUpdated, object: nil)
        // Watch for updated Distance
        NotificationCenter.default.addObserver(self, selector: #selector(handleUpdatedStepCount(_:)), name: .stepCountUpdated, object: nil)
        
        initialBarChartStepCount()  // get the initial step count (etc)
    }
    
    func handleUpdatedStepCount(_ notification: Notification) {
        guard let userInfo = notification.userInfo, let stepCount  = userInfo[Constant.StepCount.rawValue] as? Double else { return }
        let localWeeklyStepCount = weeklyStepCounts
        self.weeklyStepCounts[6] = stepCount
        stepCountBarChartController.redrawTheBarChartDisplay(weeklyStepCounts: weeklyStepCounts)
        print("stepCountModel: handleUpdatedStepCount weeklyStepCounts was \(localWeeklyStepCount), now \(weeklyStepCounts)")
    }
    
    func handleNewDay(_ notification: Notification) {        // it's a new day, move the weeklyDistance values over
        let localWeeklyStepCount = weeklyStepCounts
        for index in 0...weeklyStepCounts.count - 2 {
            weeklyStepCounts[index] = weeklyStepCounts[index + 1]
        }
        weeklyStepCounts[6] = 0
        print("stepCountModel: handleNewDay weeklyStepCounts was \(localWeeklyStepCount), \nnow \(weeklyStepCounts)")
    }
    
    fileprivate func initialBarChartStepCount() {
        print("stepCountModel: initialBarChartStepCount:")
        
        self.weeklyStepCounts[6] = 0
        checkStepCounts { (index, stepCount) -> Void in
            self.weeklyStepCounts[index] = stepCount
            self.stepCountBarChartController.redrawTheBarChartDisplay(weeklyStepCounts: self.weeklyStepCounts)
        }
    }
    
    fileprivate func checkStepCounts(completion: @escaping (_ index:Int, _ quantityValue: Double) -> Void) {
        let todaysDate = Date()
        self.weeklyStepCounts[6] = 0
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        
        for (index, stepCount) in self.weeklyStepCounts.enumerated() {
            if stepCount == 0 {
                let previousCount = index - (self.weeklyStepCounts.count - 1)
                if let date = calendar.date(byAdding: .day, value: previousCount, to: todaysDate) {
                    let startOfToday = calendar.startOfDay(for: date)
                    let endOfToday   = calendar.date(byAdding: .day, value: 1, to: startOfToday)
                    healthKitManager.retrieveHealthKitValue(
                        startDate: startOfToday,
                        endDate: endOfToday!,
                        quantityFor: HKUnit.count(),
                        quantityTypeIdentifier:HKQuantityTypeIdentifier.stepCount) { (quantityValue) -> Void in
                            
                            print("checkStepCounts for \(index): \(quantityValue) for \(date): \(startOfToday) - \(endOfToday)")
                            completion(index, quantityValue)
                    }
                }
            }
            else {
                print("checkStepCounts: stepCount for \(index) was \(stepCount)")
            }
        }
    }
}
