//
//  AppDelegate.swift
//  song
//
//  Created by Knife on 2017/4/14.
//  Copyright © 2017年 Knife. All rights reserved.
//

import Cocoa
import ScriptingBridge


// http://stackoverflow.com/questions/37285616/get-audio-metadata-from-current-playing-audio-in-itunes-on-os-x
@objc protocol iTunesApplication {
    @objc optional func currentTrack()-> AnyObject
    @objc optional var properties: NSDictionary { get }
}


struct Song {
    let title: String
    let artist: String
    let album: String
}


// http://qiita.com/Eiryyy/items/6b43d6d3f4186a585bd5
// http://stackoverflow.com/questions/38204703/notificationcenter-issue-on-swift-3
protocol TrackInfoDelegate: class {
    func updateTrackInfo(_ song: Song?)
}

class TrackInfoController: NSObject {
    var delegate: TrackInfoDelegate! = nil
    let iTunes: AnyObject
    
    override init() {
        self.iTunes = SBApplication(bundleIdentifier: "com.apple.iTunes")!
    }
    
    func checkSong() {
        guard
            iTunes.isRunning,
            let trackDict = iTunes.currentTrack?().properties as Dictionary?,
            trackDict["name"] != nil else {
                delegate.updateTrackInfo(nil)
                return
        }
        
        let title = trackDict["name"]! as! String
        let artist = trackDict["artist"]! as! String
        let album = trackDict["album"]! as! String
        
        delegate.updateTrackInfo(Song(title: title, artist: artist, album: album))
    }
    
    func notified(notification: NSNotification?) {
        // some things are numbers so we can't convert the whole dictionary to strings
        guard let info = notification?.userInfo as! Dictionary<String, Any>? else {
            delegate.updateTrackInfo(nil)
            return
        }
        
        checkSong()
        return
        
        // don't use the notification cuz me be lazy
        
        // can use playing if we want another state for paused songs
        let playing = info["Current State"]! as! String == "Playing"
        let title = info["Name"] as! String
        let artist = info["Artist"] as! String
        let album = info["Album"] as! String
        
        delegate.updateTrackInfo(Song(title: title, artist: artist, album: album))
    }

    func onComplete(response: URLResponse!, data: NSData!, error: NSError!) {
        print(response)
        print(data)
    }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, TrackInfoDelegate {

    @IBOutlet weak var statusMenu: NSMenu!
    let statusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)

    @IBAction func quitClicked(_ sender: NSMenuItem) {
        NSApplication.shared().terminate(self)
    }
    
    let defaultTitle = "Wat Singu?"
    
    let trackInfoController = TrackInfoController()
    func updateTrackInfo(_ song: Song?) {
        guard let song = song else {
            statusItem.title = defaultTitle
            return
        }
        
        statusItem.title = "\(song.artist) — \(song.title)"
    }
    
    func getCurrentStatus() {
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusItem.title = defaultTitle
        statusItem.menu = statusMenu
        
        trackInfoController.delegate = self
        trackInfoController.checkSong()
       
        let dnc = DistributedNotificationCenter.default()
        dnc.addObserver(trackInfoController,
                        selector: #selector(trackInfoController.notified(notification:)),
                        name: NSNotification.Name(rawValue: "com.apple.iTunes.playerInfo"),
                        object: nil)
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        let dnc = DistributedNotificationCenter.default()
        dnc.removeObserver(trackInfoController)
    }
}
