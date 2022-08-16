//
//  AppDelegate.swift
//  WhatWatt
//
//  Created by Jiawei Chen on 8/15/22.
//

// Thanks:  https://sarunw.com/posts/how-to-make-macos-menu-bar-app/

import Cocoa
import IOKit.ps

class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private var count: Int = 0
    private var timer: Timer?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        /*if let button = statusItem.button{
            button.image = NSImage(systemSymbolName: "1.circle", accessibilityDescription: "1")
        }*/
        let menu = NSMenu()
        menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem.menu = menu
        //statusItem.button?.title="Hello!"
        
        
        /*
        // Check for power every 5s
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true){timer in
            debugPrint("Timer")
        }*/
        // Thanks https://stackoverflow.com/questions/38057615/create-a-cfrunloopsourceref-using-iopsnotificationcreaterunloopsource-in-swift and https://stackoverflow.com/questions/50774391/swift-4-getting-thread-1-exc-bad-access-error-with-avfoundation
        let context = UnsafeMutableRawPointer(Unmanaged.passRetained(self).toOpaque())
        let loop: CFRunLoopSource = IOPSNotificationCreateRunLoopSource({(context:UnsafeMutableRawPointer?) in
            if context != nil{
                let opaque = Unmanaged<AppDelegate>.fromOpaque(context!)
                let _self = opaque.takeUnretainedValue()
                
                _self.powerSourceDidChange()
                }
                //
                //
            
            
            /*if
                _self.powerSourceDidChange()
            }*/
            
            
        }, context).takeRetainedValue() as CFRunLoopSource
        CFRunLoopAddSource(CFRunLoopGetCurrent(), loop, CFRunLoopMode.defaultMode)
        powerSourceDidChange()
        
    }
    
    
    func powerSourceDidChange(){
        let unmanagedDict:Unmanaged<CFDictionary>? = IOPSCopyExternalPowerAdapterDetails()
        

        // Thanks https://stackoverflow.com/questions/59458981/cfdictionarygetvalue-throws-exc-bad-access
        var watts = 0
        if let dict = unmanagedDict?.takeRetainedValue() as? [String:Any]{
            if let maybeWatts = dict[kIOPSPowerAdapterWattsKey] as? Int{
                watts = maybeWatts
            }
        }
        if watts != 0{
            statusItem.button?.title=String(format:"%d W", watts)
        }
        else{
            statusItem.button?.title=""
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        //timer?.invalidate()
    }
}

