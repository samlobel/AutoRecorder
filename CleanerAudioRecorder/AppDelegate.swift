//
//  AppDelegate.swift
//  CleanerAudioRecorder
//
//  Created by Sam Lobel on 9/25/15.
//  Copyright © 2015 Sam Lobel. All rights reserved.
//

import Cocoa
import AVFoundation
import Foundation



class QueueNode<T> {
    var value: T
    var next: QueueNode<T>? = nil
    
    init(value: T) { self.value = value }
}

public final class Queue<T> {
    // note, these are both optionals, to handle
    // an empty queue
    private var head: QueueNode<T>? = nil
    private var tail: QueueNode<T>? = nil
    
    public init() { }
}

extension Queue {
    // append is the standard name in Swift for this operation
    public func append(newElement: T) {
        let oldTail = tail
        self.tail = QueueNode(value: newElement)
        if  head == nil { head = tail }
        else { oldTail?.next = self.tail }
    }
    
    public func dequeue() -> T? {
        if let head = self.head {
            self.head = head.next
            if head.next == nil { tail = nil }
            return head.value
        }
        else {
            return nil
        }
    }
    public func peek() -> T? {
        if (self.head == nil) {
            return nil
        }
        else {
            return self.head!.value
        }
    }
    public func isEmpty() -> Bool {
        let head = self.head
        if (head == nil) {
            return true
        }
        else {
            return false
        }
    }
    public func size() -> Int {
        var head = self.head
        var s = 0
        while(head != nil) {
            head = head?.next
            s += 1
        }
        return s
    }
    public func empty() {
        while(!self.isEmpty()){
            self.dequeue()
        }
    }
}



@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-2)
    var pathAndRecQueue = Queue<NSDictionary>()
//    var preparedRecorders = Queue<NSDictionary>()
    let queueLength = 10
    
    var globalTimer = NSTimer?();
    
    
    
    
    func getDesktopFileName() -> String {
        let today = NSDate()
        let formatter = NSDateFormatter()
        formatter.timeStyle = .MediumStyle
        formatter.dateStyle = .MediumStyle
        let dateString = formatter.stringFromDate(today)
//        print("date coming")
//        print(dateString)
        
        var path = "~/Desktop/"
        path += dateString
        path += ".aiff"
        path = NSString(string: path).stringByExpandingTildeInPath
        return path
    }
    
    func saveLastElementAndRepopulate() {
        if (pathAndRecQueue.isEmpty()){
            print("pathAndReqQueue is empty. shouldn't be calling saveLastElement from here");
            return
        }
        else {
            print("saving last element")
        }
        
        let firstElem = pathAndRecQueue.dequeue()!
        let urlString = firstElem["urlString"] as! String
        let rec = firstElem["rec"] as! AVAudioRecorder
        
        rec.stop()
        
        let destName = getDesktopFileName()
        let Manager = NSFileManager.defaultManager()
        if (Manager.fileExistsAtPath(urlString) && !Manager.fileExistsAtPath(destName)){
            do {
                try Manager.moveItemAtPath(urlString, toPath: destName)
            }
            catch {
                print("error moving!")
                print(error)
            }
        }
        
        let newRec = makeRecordingObjectFromURLString(urlString)
        newRec.record()
        let newDict = NSDictionary(dictionary: ["rec" : newRec, "urlString" : urlString])
        pathAndRecQueue.append(newDict)

    }
    
    func deleteAndRequeue() {
        if (pathAndRecQueue.isEmpty()){
            print("pathAndReqQueue is empty. shouldn't be calling delete and requeue from here");
            return
        }
        else {
            print("deleting and requeueing")
        }
        let firstElem = pathAndRecQueue.dequeue()!
        let urlString = firstElem["urlString"] as! String
        let rec = firstElem["rec"] as! AVAudioRecorder
        rec.deleteRecording()
        let newRec = makeRecordingObjectFromURLString(urlString)
        newRec.record()
        let newDict = NSDictionary(dictionary: ["rec" : newRec, "urlString" : urlString])
        pathAndRecQueue.append(newDict)

    }
    
    func makeURLString(i : Int) -> String {
        var name = "/tmp/"
        name += "tempSong_"
        name += String(i)
        name += ".aiff"
//        let toReturn = NSString(string: name).stringByExpandingTildeInPath
        return name
    }

    func makeRecordingObjectFromURLString(URLString : String) -> AVAudioRecorder{
        let soundFileURL = NSURL(fileURLWithPath: URLString)
        do {
            let recording = try AVAudioRecorder.init(URL: soundFileURL, settings: [AVSampleRateKey: 44100.0])
            return recording
        }
        catch {
            print("error!")
            return AVAudioRecorder()
            //            return nil
        }
    }
    
    func sleepListener(aNotification : NSNotification) {
        print("Sleep Listening");
        while(!pathAndRecQueue.isEmpty()) {
            print("deleting")
            let firstElem = pathAndRecQueue.dequeue()!
            let rec = firstElem["rec"] as! AVAudioRecorder
            rec.deleteRecording()
        }
        print("Queue initialized")
        if globalTimer != nil {
            globalTimer?.invalidate()
        }
        globalTimer = nil

    }
    
    func wakeUpListener(aNotification : NSNotification) {
        print("Wake Up Listening");
        setUpEverything();
    }
    
    func screenSleepListener(aNotification : NSNotification) {
        print("Screen Sleep Listening");
        while(!pathAndRecQueue.isEmpty()) {
            print("deleting")
            let firstElem = pathAndRecQueue.dequeue()!
            let rec = firstElem["rec"] as! AVAudioRecorder
            rec.deleteRecording()
        }
        print("Queue initialized")
        if globalTimer != nil {
            globalTimer?.invalidate()
        }
        globalTimer = nil
        
        

    }
    
    func screenWakeUpListener(aNotification : NSNotification) {
        print("Screen Wake Up Listening");
        setUpEverything();
    }
    
    
    
    func setUpEverything(){
//        pathAndRecQueue.empty();
        while(!pathAndRecQueue.isEmpty()) {
            print("deleting")
            let firstElem = pathAndRecQueue.dequeue()!
            let rec = firstElem["rec"] as! AVAudioRecorder
            rec.deleteRecording()
        }

        for index in 0..<queueLength{
            print(index)
            let urlString = makeURLString(index)
            let rec = makeRecordingObjectFromURLString(urlString)
            rec.record()
            let dict = NSDictionary(dictionary: ["rec" : rec, "urlString" : urlString])
            pathAndRecQueue.append(dict)
        }
        
        print("Queue initialized")
        if globalTimer != nil {
            globalTimer?.invalidate()
        }
        globalTimer = nil
        globalTimer = NSTimer.scheduledTimerWithTimeInterval(30.0, target: self, selector: "deleteAndRequeue", userInfo: nil, repeats: true)
        NSRunLoop.mainRunLoop().addTimer(globalTimer!, forMode: NSRunLoopCommonModes)
        print("Timer added to run loop")
    }
    
    
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        
        globalTimer = nil
        
        setUpEverything()
        
        NSWorkspace.sharedWorkspace().notificationCenter.addObserver(self, selector: "sleepListener:", name: NSWorkspaceWillSleepNotification, object: nil)
        NSWorkspace.sharedWorkspace().notificationCenter.addObserver(self, selector: "wakeUpListener:", name: NSWorkspaceDidWakeNotification, object: nil)
        
        NSWorkspace.sharedWorkspace().notificationCenter.addObserver(self, selector: "screenSleepListener:", name: NSWorkspaceScreensDidSleepNotification, object: nil)
        NSWorkspace.sharedWorkspace().notificationCenter.addObserver(self, selector: "screenWakeUpListener:", name: NSWorkspaceScreensDidWakeNotification, object: nil)
        
            if let button = statusItem.button {
                button.image = NSImage(named: "Volume")
            }


        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Save last 5 minutes", action: Selector("saveLastElementAndRepopulate"), keyEquivalent: "s"))
        menu.addItem(NSMenuItem.separatorItem())
        menu.addItem(NSMenuItem(title: "Quit Autorecorder", action: Selector("terminate:"), keyEquivalent: "q"))
        statusItem.menu = menu

        
        
//        
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "sleepListener", name: NSWorkspaceWillSleepNotification, object: nil)
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "wakeUpListener", name: NSWorkspaceDidWakeNotification, object: nil)
        


//        // Insert code here to initialize your application
//        if let button = statusItem.button {
//            button.image = NSImage(named: "Volume")
////            button.image = NSImage.init
//        }
////        statusItem.image = NSImage(named: "Icon_Mic")
//        
//        for index in 0..<queueLength{
//            print(index)
//            let urlString = makeURLString(index)
//            let rec = makeRecordingObjectFromURLString(urlString)
//            rec.record()
//            let dict = NSDictionary(dictionary: ["rec" : rec, "urlString" : urlString])
//            pathAndRecQueue.append(dict)
//        }
//        print("Queue initialized")
//        let timer = NSTimer.scheduledTimerWithTimeInterval(30.0, target: self, selector: "deleteAndRequeue", userInfo: nil, repeats: true)
//        NSRunLoop.mainRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)
//        print("Timer added to run loop")
//
//        let menu = NSMenu()
//        menu.addItem(NSMenuItem(title: "Save last 5 minutes", action: Selector("saveLastElementAndRepopulate"), keyEquivalent: "s"))
//        menu.addItem(NSMenuItem.separatorItem())
//        menu.addItem(NSMenuItem(title: "Quit Autorecorder", action: Selector("terminate:"), keyEquivalent: "q"))
//        statusItem.menu = menu
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
        while(!pathAndRecQueue.isEmpty()) {
            print("deleting")
            let firstElem = pathAndRecQueue.dequeue()!
            let rec = firstElem["rec"] as! AVAudioRecorder
            rec.deleteRecording()
        }
    }


}

