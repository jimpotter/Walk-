//
//  StepCountBarChartController.swift
//  Walk WatchKit Extension
//
//  Created by jrp on 2/6/17.
//  Copyright © 2017 jrp. All rights reserved.
//

import WatchKit

class StepCountBarChartController: WKInterfaceController {
    @IBOutlet var chartImage: WKInterfaceImage!
    fileprivate var chart = BarChart()
    fileprivate var model:StepCountModel?
    
    override init() {
        super.init()
        model = StepCountModel(controller: self)
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
    }
    
    // redraw the step count bar chart view
    func redrawTheBarChartDisplay(weeklyStepCounts: [Double]) {
        let frame = CGRect(x: 0, y: 0, width: self.contentFrame.size.width, height: self.contentFrame.size.height)
        let image = self.chart.drawImage(frame: frame, yLabelText: Constant.Steps.rawValue, yValues:weeklyStepCounts)
        DispatchQueue.main.async {
            self.chartImage.setImage(image)
        }
    }
}
