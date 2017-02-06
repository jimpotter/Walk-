//
//  DistanceBarChartController.swift
//  Walk WatchKit Extension
//
//  Created by jrp on 2/6/17.
//  Copyright © 2017 jrp. All rights reserved.
//

import WatchKit

class DistanceBarChartController: WKInterfaceController {
    @IBOutlet var chartImage: WKInterfaceImage!
    fileprivate var chart = BarChart()
    fileprivate var model:DistanceModel?
    
    override init() {
        super.init()
        model = DistanceModel(controller: self)
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
    }
    
    // redraw the distance bar chart view
    func redrawTheBarChartDisplay (weeklyDistance: [Double]) {
        let frame = CGRect(x: 0, y: 0, width: self.contentFrame.size.width, height: self.contentFrame.size.height)
        let image = self.chart.drawImage(frame: frame, yLabelText: Constant.Miles.rawValue, yValues:weeklyDistance,  useIntValues:false)
        DispatchQueue.main.async {
            self.chartImage.setImage(image)
        }
    }
}

