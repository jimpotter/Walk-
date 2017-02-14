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
        // Do any additional setup after loading the view, typically from a nib.
        startNSLogger()
        
        logMessage(message: "viewDidLoad of Walk! iPhone app")

        if WCSession.isSupported() {        // configure and activate the session
            session = WCSession.default()
            session.delegate = self
            session.activate()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        LogMessageRaw("viewWillAppear: \(Date())")

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // Called when all delegate callbacks for the previously selected watch has occurred. The session can be re-activated for the now selected watch using activateSession.
    @available(iOS 9.3, *)
    public func sessionDidDeactivate(_ session: WCSession) {
        //..
    }
    
    
    // Called when the session can no longer be used to modify or add any new transfers and, all interactive messages will be cancelled, but delegate callbacks for background transfers can still occur. This will happen when the selected watch is being changed.
    @available(iOS 9.3, *)
    public func sessionDidBecomeInactive(_ session: WCSession) {
        //..
    }
    
    
    // Called when the session has completed activation. If session state is WCSessionActivationStateNotActivated there will be an error with more details.
    @available(iOS 9.3, *)
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        //..
    }
}

//MARK: - WatchSessionProtocol -> ViewController
typealias WatchSessionProtocol = ViewController
extension WatchSessionProtocol {
    
    // WCSession Delegate protocol
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        // Reply handler, received message
        if let value = message["Message"] as? String {
            
//            print(value)                // print message to the console
            logMessage(message: value)  // send message string to NSLogger

            let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                .appendingPathComponent("aoutputStream.txt")
            
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

//MARK: - PairedActions -> ViewController
//typealias PairedActions = ViewController
//extension PairedActions {
//    @IBAction func sendToWatch(_ sender: AnyObject) {    // Send message to Apple Watch
//        sendMessage()
//    }
//}

//MARK: - WatchSessionTasks -> ViewController
//typealias WatchSessionTasks = ViewController
//extension WatchSessionTasks {
//    func sendMessage() {    // Method to send message to watchOS
//        
//        let messageToSend = ["Message":"Hi watch, are you here?"]        // A dictionary of property list values that you want to send.
//        
//        // Task : Sends a message immediately to the counterpart and optionally delivers a response
//        session.sendMessage(messageToSend, replyHandler: { (replyMessage) in
//            // Reply handler - present the reply message on screen
//            let value = replyMessage["Message"] as? String
//        }) { (error) in
//            // Catch any error Handler
//            print("error: \(error.localizedDescription)")
//        }
//    }
//}
