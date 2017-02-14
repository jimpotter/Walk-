//
//  BarChart.swift
//  Walk WatchKit Extension
//
//  Created by jrp on 2/6/17.
//  Copyright © 2017 jrp. All rights reserved.
//

import Foundation
import CoreGraphics
import UIKit

struct BarChart {
    // MARK: - Constants & parameters
    internal var chartMargin:CGFloat = 12.0
    internal var kXLabelHeight:CGFloat = 8.0
    internal let firstBarEdge:CGFloat = 16.7     // observed edge of first bar
    internal let daysInWeek = 7
    internal let xLabels = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
    internal let xLabelFont   = UIFont.systemFont(ofSize: 8, weight: UIFontWeightLight)
    internal let labelMarginTop:CGFloat = 5.0
    internal var chartBorderColor = UIColor.white
    
    mutating func drawImage(frame:CGRect, yLabelText:String, yValues:[Double], useIntValues:Bool = true) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(frame.size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil}

        drawImageIntoContext(context:context, frame:frame, yLabelText:yLabelText, yValues:yValues, useIntValues:useIntValues)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    mutating func drawImageIntoContext(context:CGContext, frame:CGRect, yLabelText:String, yValues:[Double], useIntValues:Bool) {
        let xLabelWidth = (frame.size.width - (chartMargin * 2)) / CGFloat(daysInWeek)
        let barWidth:CGFloat = xLabelWidth * 0.6
        let barHeight = frame.size.height - chartMargin * 2 - kXLabelHeight
        let barRadius:CGFloat = 2.0    // Corner radius for all bars in the chart.
        let barYPosition = frame.size.height - barHeight - kXLabelHeight - chartMargin
        let yValueMax = getMaxYValue(yValues: yValues)
        let barLabelFont = UIFont.systemFont(ofSize: 12, weight: UIFontWeightLight)
        
        let frameBackgroundClipPath = UIBezierPath(rect: frame).cgPath    // mark the background color of the frame
        
        // draw the frame background
        drawObject(context:context, clipPath:frameBackgroundClipPath, fillColor:UIColor.gray)
        drawXLabels(labelWidth: xLabelWidth, frame: frame)
        drawYLabels(context:context, yLabelText: yLabelText, barHeight: barHeight, font:barLabelFont, size: frame.size)
        drawBottonLine(bottomLine: UIBezierPath(), chartBorderColor: chartBorderColor, frame: frame)
        
        // draw bars
        for (index, yValue) in yValues.enumerated() {
            let grade = getGrade(yValue:yValue, yValueMax:yValueMax)
            let barColor = getBarColor(grade:grade)
            let barXPosition = (CGFloat(index) *  xLabelWidth) + chartMargin + (xLabelWidth * 0.25)
            let barBackgroundRect = CGRect(x:barXPosition,
                                           y:barYPosition,
                                           width:barWidth,
                                           height:barHeight)

            let barRect = CGRect(x:barXPosition,
                                 y:barYPosition + (1 - CGFloat(grade)) * barHeight,
                                 width:barWidth,
                                 height:CGFloat(grade) * barHeight)
            
            let backgroundClipPath: CGPath = UIBezierPath(roundedRect: barBackgroundRect,
                                                          cornerRadius: barRadius).cgPath
            
            let barClipPath: CGPath = UIBezierPath(roundedRect: barRect, cornerRadius: 2).cgPath

            // draw the bar background
            drawObject(context:context, clipPath:backgroundClipPath, fillColor:UIColor.lightGray)
            
            // draw the bar
            drawObject(context:context, clipPath:barClipPath, fillColor:barColor)
            
            // draw the value marking the height of the bar
            drawYValue(context:context, yValue:yValue, barLabelFont:barLabelFont, barRect:barRect, grade:grade, size:frame.size, useIntValues:useIntValues)
        }
    }
}

extension BarChart {
    // MARK: - drawing things
    internal mutating func drawYValue (context: CGContext, yValue:Double, barLabelFont:UIFont, barRect:CGRect, grade:Float, size: CGSize, useIntValues:Bool) {
        var yValueString = String(Int(yValue))  // prepare to mark the bar label
        if useIntValues == false {
            yValueString = String(format:"%.2f", yValue)
        }
        
        let yValueRect = evaluateStringTextSize(textToEvaluate: yValueString, font:barLabelFont, size: size)
        var labelPoint = CGPoint(x:barRect.origin.x + (yValueRect.height / 3),
                                 y:(barRect.origin.y + (yValueRect.width / 2)) + (yValueRect.height / 3))
        if (0.0..<0.5).contains(grade) {
            labelPoint.y = (barRect.origin.y - (yValueRect.width / 2)) - (yValueRect.height / 2)
        }
        
        let barLabelColor = getBarLabelColor(grade:grade, labelPoint:labelPoint, barRect: barRect, yValueRect: yValueRect)
        
        // mark the bar label
        yValueString.drawWithBasePoint(context: context, basePoint:labelPoint, angle:CGFloat(-M_PI_2), font:barLabelFont, color:barLabelColor)
    }
    
    internal mutating func drawObject(context:CGContext, clipPath:CGPath, fillColor:UIColor) {
        context.addPath(clipPath)
        context.setFillColor(fillColor.cgColor)
        context.closePath()
        context.fillPath()
    }
    
    internal mutating func drawYLabels(context: CGContext, yLabelText:String, barHeight:CGFloat, font:UIFont, size:CGSize) {
        let yValueRect = evaluateStringTextSize(textToEvaluate: yLabelText, font:font, size:size)
        let labelY = (barHeight / 2) + (yValueRect.width / 2)   // half of the barHeight, plus half of the label width
        
        let labelX = (firstBarEdge / 2)     // half of the space up to the first bar
        let labelPoint = CGPoint(x: labelX, y: labelY)
        
        // mark the Y label
        yLabelText.drawWithBasePoint(context: context, basePoint:labelPoint, angle:CGFloat(-M_PI_2), font:font, color:UIColor.white)
    }
    
    internal mutating func drawXLabels(labelWidth:CGFloat, frame:CGRect) {
        for index in 0..<daysInWeek {
            let weekdayNumber = Calendar.current.component(.weekday, from: Date())
            let style = NSMutableParagraphStyle()
            style.alignment = .left
            style.lineBreakMode = .byTruncatingTail
            
            var attributesDictionary = [String:Any]()
            attributesDictionary[NSFontAttributeName] = xLabelFont
            attributesDictionary[NSForegroundColorAttributeName] = UIColor.white
            attributesDictionary[NSParagraphStyleAttributeName] = style
            
            let labelXPosition = ((CGFloat(index) *  labelWidth) + chartMargin  + labelWidth / 4.0 )
            let labelRect = CGRect(x:labelXPosition,
                                   y:frame.size.height - kXLabelHeight - chartMargin + labelMarginTop,
                                   width:labelWidth,
                                   height:kXLabelHeight)
            
            let dayName = xLabels[(weekdayNumber + index) % daysInWeek]
            dayName.draw(in: labelRect, withAttributes: attributesDictionary)
        }
    }
    
    internal func drawBottonLine(bottomLine:UIBezierPath, chartBorderColor:UIColor, frame:CGRect) {
        let bottomMoveToPoint = CGPoint(x:chartMargin, y:frame.size.height - kXLabelHeight - chartMargin)
        let bottomLineToPoint = CGPoint(x:frame.size.width - chartMargin,  y:frame.size.height - kXLabelHeight - chartMargin)
        bottomLine.move(to: bottomMoveToPoint)
        bottomLine.addLine(to: bottomLineToPoint)
        bottomLine.lineWidth = 1.0
        bottomLine.lineCapStyle = .square
        chartBorderColor.setStroke()
        bottomLine.stroke()
    }
    
    // MARK: - computing parameters
    internal func getGrade(yValue:Double, yValueMax:Double) -> Float {
        var grade = fabsf(Float(yValue) / Float(yValueMax))
        if grade.isNaN {
            grade = 0
        }
        return grade
    }
    
    internal mutating func getBarLabelColor(grade:Float, labelPoint:CGPoint, barRect:CGRect, yValueRect:CGRect) -> UIColor {
        var barLabelColor = UIColor.black
        if (0.0..<0.5).contains(grade) {
            barLabelColor = UIColor.darkRedColor
        }
        return barLabelColor
    }
    
    internal func getBarColor(grade:Float) -> UIColor {
        switch grade {
        case 0.0..<0.5:
            return UIColor.darkRedColor
        case 0.5..<0.75:
            return UIColor.middleColor
        default:
            return UIColor.topColor
        }
    }
    
    internal func getMaxYValue (yValues:[Double]) -> Double {
        let sorted = yValues.sorted(by: { $0 > $1 })
        return sorted[0]
    }
    
    internal func evaluateStringTextSize (textToEvaluate: String, font:UIFont, size:CGSize) -> (CGRect) {
        let attributesDictionary = [NSFontAttributeName: font]
        let textSize = NSString(string: textToEvaluate).boundingRect(with: size,
                                                                     options: .usesLineFragmentOrigin,
                                                                     attributes: attributesDictionary,
                                                                     context: nil)
        return (textSize)
    }
}

extension NSString {
    func drawWithBasePoint(context:CGContext, basePoint:CGPoint, angle:CGFloat, font:UIFont, color:UIColor = UIColor.black) {
        
        var attributesDictionary = [String:Any]()
        attributesDictionary[NSFontAttributeName] = font
        attributesDictionary[NSForegroundColorAttributeName] = color
        
        let textSize:CGSize   = self.size(attributes: attributesDictionary)
        let t:CGAffineTransform = CGAffineTransform(translationX: basePoint.x, y: basePoint.y)
        let r:CGAffineTransform = CGAffineTransform(rotationAngle: angle)
        context.concatenate(t)
        context.concatenate(r)
        self.draw(at: CGPoint(x:-1 * textSize.width / 2, y:-1 * textSize.height / 2), withAttributes: attributesDictionary)
        context.concatenate(r.inverted())
        context.concatenate(t.inverted())
    }
}

enum Constant: String{
    case WeeklyStepCountMax = "weeklyStepCountMax"
    case StepCount          = "stepCount"
    case Distance           = "distance"
    case WeeklyStepCounts   = "weeklyStepCounts"
    case WeeklyDistance     = "weeklyDistance"
    case Steps              = "STEPS"
    case Miles              = "MILES"
}

extension Notification.Name {
    static let weeklyStepCountMaxUpdated = Notification.Name(rawValue: "WeeklyStepCountMaxUpdated")
    static let stepCountUpdated          = Notification.Name(rawValue: "StepCountUpdatedNotification")
    static let distanceUpdated           = Notification.Name(rawValue: "DistanceUpdatedNotification")
    static let dayOfWeekUpdated          = Notification.Name(rawValue: "DayOfWeekUpdatedNotification")
    static let becomeActive              = Notification.Name(rawValue: "ApplicationDidBecomeActive")    
}

extension UIColor {
    static let topColor     = UIColor(red:  99/255, green: 255/255, blue:  28/255, alpha: 1)
    static let middleColor  = UIColor(red: 255/255, green: 167/255, blue:   5/255, alpha: 1)
    static let darkRedColor = UIColor(red: 171/255, green:   4/255, blue:   5/255, alpha: 1)
}
