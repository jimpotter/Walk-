//
//  DistanceModel.swift
//  Walk WatchKit Extension
//
//  Created by jrp on 2/6/17.
//  Copyright © 2017 jrp. All rights reserved.
//

import HealthKit

class DistanceModel: NSObject {
    fileprivate var distanceBarChartController: DistanceBarChartController
    internal var distanceModelHelper = DistanceModelHelper()

    var weeklyDistance: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0] {
        didSet {
            UserDefaults.standard.set(weeklyDistance, forKey: Constant.WeeklyDistance.rawValue)
        }
    }
    
    init(controller:DistanceBarChartController) {
        distanceBarChartController = controller
        super.init()
        weeklyDistance = UserDefaults.standard.array(forKey: Constant.WeeklyDistance.rawValue)  as? [Double] ?? [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        print("distanceModel: init: weeklyDistance \(weeklyDistance)")
        
        // Watch for new day
        NotificationCenter.default.addObserver(self, selector: #selector(handleNewDay(_:)), name: .dayOfWeekUpdated, object: nil)
        
        // Watch for updated Distance
        NotificationCenter.default.addObserver(self, selector: #selector(handleUpdatedDistance(_:)), name: .distanceUpdated, object: nil)
        
        self.weeklyDistance[6] = 0.0
        distanceModelHelper.checkDistance (healthKitManager: HealthKitManager(), weeklyDistance:weeklyDistance) { (index, distance) -> Void in
            self.weeklyDistance[index] = distance
            self.distanceBarChartController.redrawTheBarChartDisplay(weeklyDistance: self.weeklyDistance)
        }
    }
    
    func handleUpdatedDistance(_ notification: Notification) {
        guard let userInfo = notification.userInfo, let distance  = userInfo[Constant.Distance.rawValue] as? Double else { return }
        let localWeeklyDistance = weeklyDistance
        self.weeklyDistance[6] = distance
        distanceBarChartController.redrawTheBarChartDisplay(weeklyDistance: weeklyDistance)
        print("\ndistanceModel: handleUpdatedStepCount weeklyDistance was \(localWeeklyDistance), \nnow \(weeklyDistance)\n")
    }
    
    func handleNewDay(_ notification: Notification) {        // it's a new day, move the weeklyDistance values over
        let localWeeklyDistance = weeklyDistance
        for index in 0...weeklyDistance.count - 2 {
            weeklyDistance[index] = weeklyDistance[index + 1]
        }
        weeklyDistance[6] = 0.0
        print("distanceModel: handleNewDay weeklyDistance was \(localWeeklyDistance), \nnow \(weeklyDistance)")
    }
    
}

struct DistanceModelHelper {
    internal func checkDistance(healthKitManager:HealthKitMgr, weeklyDistance: [Double], completion: @escaping (_ index:Int, _ quantityValue: Double) -> Void) {
        let todaysDate = Date()
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        print("distanceModel: checkDistance: calendar \(calendar)")
        
        
        for (index, distance) in weeklyDistance.enumerated() {
            if distance == 0.0 {
                let previousCount = index - (weeklyDistance.count - 1)
                if let date = calendar.date(byAdding: .day, value: previousCount, to: todaysDate) {
                    let startOfToday = calendar.startOfDay(for: date)
                    let endOfToday   = calendar.date(byAdding: .day, value: 1, to: startOfToday)
                    healthKitManager.retrieveHealthKitValue(
                        startDate: startOfToday,
                        endDate: endOfToday!,
                        quantityFor: HKUnit.mile(),
                        quantityTypeIdentifier:HKQuantityTypeIdentifier.distanceWalkingRunning) { (quantityValue) -> Void in
                            
                            print("checkDistance for \(index): \(quantityValue) for \(date): \(startOfToday) - \(endOfToday)")
                            completion(index, quantityValue)
                    }
                }
            }
            else {
                print("checkDistance: distance for \(index) was \(distance)")
            }
        }
    }
}
