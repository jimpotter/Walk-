//
//  ViewController.swift
//  Walk!
//
//  Created by jrp on 2/6/17.
//  Copyright © 2017 jrp. All rights reserved.
//

import UIKit
import WatchConnectivity
import NSLogger

class ViewController: UIViewController, WCSessionDelegate {

    // MARK: - Properties
    fileprivate var session: WCSession!

    func logMessage(message: String) {
        let appID = Bundle.main.bundleIdentifier
        LogMessage_va(appID, 0, message, getVaList([]))
    }
    
    func startNSLogger() {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true);
        let file = "\(paths.first!)/loggerdata"
        let bundleName = Bundle.main.object(forInfoDictionaryKey: kCFBundleNameKey as String) as! String
        
        let logger = LoggerInit()
        LoggerSetBufferFile(logger, file as CFString!)
        LoggerSetOptions(logger, UInt32(kLoggerOption_BufferLogsUntilConnection | kLoggerOption_BrowseBonjour | kLoggerOption_BrowseOnlyLocalDomain))
        LoggerSetupBonjour(logger, nil, bundleName as CFString!)
        LoggerStart(nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        startNSLogger() // start NSLogger
        
        if WCSession.isSupported() {        // configure and activate the session
            session = WCSession.default()
            session.delegate = self
            session.activate()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @available(iOS 9.3, *)
    public func sessionDidDeactivate(_ session: WCSession) {
    }
    
    @available(iOS 9.3, *)
    public func sessionDidBecomeInactive(_ session: WCSession) {
    }
    
    @available(iOS 9.3, *)
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
}

//MARK: - WatchSessionProtocol -> ViewController
typealias WatchSessionProtocol = ViewController
extension WatchSessionProtocol {
    
    // WCSession Delegate protocol
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        // Reply handler, received message
        if let value = message["Message"] as? String {
            
            logMessage(message: value)  // send message string to NSLogger

            let bundleName = Bundle.main.object(forInfoDictionaryKey: kCFBundleNameKey as String) as! String
            let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                .appendingPathComponent(bundleName + ".txt")
            
            if let outputStream = OutputStream(url: fileURL, append: true) {
                outputStream.open()
                let newValue = value + "\n"
                
                let bytesWritten = outputStream.write(newValue, maxLength:newValue.characters.count)
                if bytesWritten < 0 {
                    print("write failure")
                }
                else {
                    print("value \(value)")
                    print("\(bytesWritten) bytesWritten")
                }
                outputStream.close()
            } else {
                print("Unable to open file")
            }
        }
        
        // Send a reply
        replyHandler(["Message":"Hey Watch! Nice to meet you!\nWould you like work with me?"])
    }
}
