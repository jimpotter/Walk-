//
//  ComplicationController.swift
//  Walk! WatchKit Extension
//
//  Created by jrp on 2/6/17.
//  Copyright © 2017 jrp. All rights reserved.
//

import ClockKit

class ComplicationController: NSObject, CLKComplicationDataSource {
    func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Swift.Void) {
        handler([])
    }
    
    func getTimelineStartDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Swift.Void) {
        handler(nil)
    }
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Swift.Void) {
        handler(nil)
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Swift.Void) {
        handler(.showOnLockScreen)
    }
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Swift.Void) {
        guard let template = self.complicationTemplateForData(complication: complication) else {
            handler(nil)
            return;
        }
        let entry: CLKComplicationTimelineEntry = CLKComplicationTimelineEntry.init(date: Date(), complicationTemplate: template)
        handler(entry)
    }
    
    func getTimelineEntries(for complication: CLKComplication, before date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Swift.Void) {
        handler(nil)
    }
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Swift.Void) {
        handler(nil)
    }
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Swift.Void) {
        handler(self.complicationTemplateForData(complication: complication))
    }
    
    func complicationTemplateForData(complication: CLKComplication) -> CLKComplicationTemplate? {
        var final_template: CLKComplicationTemplate? = nil
        switch complication.family {
        case .modularSmall:
            let modularSmall = CLKComplicationTemplateModularSmallRingImage()
            modularSmall.imageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication/Modular")!)
            modularSmall.tintColor = .white
            final_template = modularSmall
            
        case .utilitarianSmall:
            let utilitarianSmall = CLKComplicationTemplateUtilitarianSmallRingImage()
            utilitarianSmall.imageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication/Utilitarian")!)
            utilitarianSmall.tintColor = .white
            final_template = utilitarianSmall
            
        case .circularSmall:
            let circularSmall = CLKComplicationTemplateCircularSmallRingImage()
            circularSmall.imageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication/Circular")!)
            circularSmall.tintColor = .white
            final_template = circularSmall
            
        case .modularLarge:          break
        case .utilitarianSmallFlat:   break
        case .utilitarianLarge:      break
        case .extraLarge:           break
        }
        return final_template
    }
}
