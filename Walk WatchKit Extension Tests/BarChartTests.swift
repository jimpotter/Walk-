//
//  BarChartTests.swift
//  Walk WatchKit Extension Tests
//
//  Created by jrp on 2/6/17.
//  Copyright © 2017 jrp. All rights reserved.
//

import XCTest
import CoreGraphics
import Darwin

class BarChartTests: XCTestCase {
    
    //MARK: - testing drawYValue
    func testDrawYValue() {
        var chart = BarChart()
        let yValue = 74.9
        let barLabelFont = UIFont.systemFont(ofSize: 12, weight: UIFontWeightLight)
        let grade:Float = 0.25
        let size = CGSize(width:150.0, height:200)
        let frame = CGRect(x: 0, y: 0, width: 44, height: 55)
        
        UIGraphicsBeginImageContextWithOptions(frame.size, false, 0)
        if let context = UIGraphicsGetCurrentContext() {
            chart.drawYValue (context: context, yValue:yValue, barLabelFont:barLabelFont, barRect:frame, grade:grade, size: size, useIntValues:true)
        }
        UIGraphicsEndImageContext()
    }
    
    //    //MARK: - testing drawObject
    func testDrawObject() {
        var chart = BarChart()
        let frame = CGRect(x: 0, y: 0, width: 44, height: 55)
        let clipPath = UIBezierPath(roundedRect: frame, cornerRadius: 2).cgPath
        UIGraphicsBeginImageContextWithOptions(frame.size, false, 0)
        if let context = UIGraphicsGetCurrentContext() {
            
            chart.drawObject(context:context, clipPath:clipPath, fillColor:UIColor.black)
        }
        UIGraphicsEndImageContext()
    }
    
    //MARK: - testing drawBottonLine
    func testDrawBottomLine() {
        // setup several params to pass tested object
        let chartMargin:CGFloat   = 22
        let kXLabelHeight:CGFloat = 33
        let frame = CGRect(x: 0, y: 0, width: 44, height: 55)
        
        // Instantiate mocks
        let mockUIColor      = MockUIColor()
        let mockUIBezierPath = MockUIBezierPath()
        
        // Instantiate the object being tested
        var chart = BarChart()
        
        // set several params on the tested object
        chart.chartMargin = chartMargin
        chart.kXLabelHeight = kXLabelHeight
        
        // setup expected result
        let expectedBottomMoveToPoint = CGPoint(x:chartMargin, y:frame.size.height - kXLabelHeight - chartMargin)
        
        chart.drawBottonLine(bottomLine: mockUIBezierPath, chartBorderColor: mockUIColor, frame:frame)
        
        // assert that test passed
        XCTAssertEqual(mockUIBezierPath.observedBottomMoveToPoint.x, expectedBottomMoveToPoint.x)
        XCTAssertEqual(mockUIBezierPath.observedBottomMoveToPoint.y, expectedBottomMoveToPoint.y)
    }
    
    // MARK: - testing getGrade()
    func testGetGrade() {
        let chart = BarChart()
        let yValue:Double = 147.8
        let yValueMax:Double = 837.9
        let returnedGrade = chart.getGrade(yValue:yValue, yValueMax:yValueMax)
        let expectedGrade = fabsf(Float(yValue) / Float(yValueMax))
        XCTAssertEqual(returnedGrade, expectedGrade)
    }
    
    // MARK: - testing getBarLabelColor()
    func testGetBarLabelColor_DarkRedColor() {
        var chart = BarChart()
        let grade:Float = 0.25
        let labelPoint = CGPoint(x:34.5, y:150.7)
        let barRect = CGRect(x:0, y:0, width:labelPoint.x, height:labelPoint.y)
        
        let returnedBarLabelColor = chart.getBarLabelColor(grade:grade,
                                                           labelPoint:labelPoint,
                                                           barRect:barRect,
                                                           yValueRect:barRect)
        
        XCTAssertEqual(returnedBarLabelColor, chart.darkRedColor)
    }
    
    func testGetBarLabelColor_Black() {
        var chart = BarChart()
        let grade:Float = 0.75
        let labelPoint = CGPoint(x:34.5, y:150.7)
        let barRect = CGRect(x:0, y:0, width:labelPoint.x, height:labelPoint.y)
        
        let returnedBarLabelColor = chart.getBarLabelColor(grade:grade,
                                                           labelPoint:labelPoint,
                                                           barRect:barRect,
                                                           yValueRect:barRect)
        
        XCTAssertEqual(returnedBarLabelColor, UIColor.black)
    }
    
    // MARK: - testing getBarColor()
    func testGetBarColor_DarkRedColor() {
        let chart = BarChart()
        let grade:Float = 0.25
        let returnedColor = chart.getBarColor(grade:grade)
        XCTAssertEqual(returnedColor, chart.darkRedColor)
    }
    
    func testGetBarColor_MiddleColor() {
        let chart = BarChart()
        let grade:Float = 0.6
        let returnedColor = chart.getBarColor(grade:grade)
        XCTAssertEqual(returnedColor, chart.middleColor)
    }
    
    func testGetBarColor_TopColor() {
        let chart = BarChart()
        let grade:Float = 0.8
        let returnedColor = chart.getBarColor(grade:grade)
        XCTAssertEqual(returnedColor, chart.topColor)
    }
    
    // MARK: - testing getMaxYValue()
    func testGetMaxYValue () {
        let chart = BarChart()
        let lowValue = 14.7
        let middleValue = 75.3
        let highValue = 987.8
        let returnedMax = chart.getMaxYValue (yValues:[lowValue, middleValue, highValue])
        XCTAssertEqual(returnedMax, highValue)
    }
    
    // MARK: - testing evaluateStringTextSize()
    func testEvaluateStringTextSize() {
        let chart = BarChart()
        let barLabelFont = UIFont.systemFont(ofSize: 12, weight: UIFontWeightLight)
        let yValue = 42.25
        let yValueString = String(format:"%.2f", yValue)
        
        let maxSize = CGSize(width:150.0, height:200)
        let attributesDictionary = [NSFontAttributeName: barLabelFont]
        let returnedRect = chart.evaluateStringTextSize(textToEvaluate: yValueString, font:barLabelFont, size:maxSize)
        
        let expectedRect = NSString(string: yValueString).boundingRect(with: maxSize,
                                                                       options: .usesLineFragmentOrigin,
                                                                       attributes: attributesDictionary,
                                                                       context: nil)
        
        XCTAssertEqual(returnedRect.origin.x, expectedRect.origin.x)
        XCTAssertEqual(returnedRect.origin.y, expectedRect.origin.y)
        XCTAssertEqual(returnedRect.size.width, expectedRect.size.width)
        XCTAssertEqual(returnedRect.size.height, expectedRect.size.height)
    }
    
    //    //MARK: - setUp & tearDown
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    //    //MARK: - Mocks
    class MockUIColor: UIColor {
        override func setStroke() {
            print("setStroke:")
        }
    }
    
    class MockUIBezierPath: UIBezierPath {
        var observedBottomMoveToPoint = CGPoint(x:0, y:0)
        override func move(to: CGPoint) {
            self.observedBottomMoveToPoint = to
            print("move: to: \(to)")
        }
        override func stroke() {
            print("stroke:")
        }
        override func addLine(to: CGPoint) {
            print("addLine: to: \(to)")
        }
    }
}
