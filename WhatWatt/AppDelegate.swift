//
//  AppDelegate.swift
//  WhatWatt
//
//  Created by Jiawei Chen on 8/15/22.
//



import Cocoa
import IOKit.ps

class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Thanks  https://sarunw.com/posts/how-to-make-macos-menu-bar-app/
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let menu = NSMenu()
        menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem.menu = menu
        
        // Saves a pointer to this specific instance of AppDelegate, so we can call its member functions in a run loop handler
        // Thanks https://stackoverflow.com/questions/38057615/create-a-cfrunloopsourceref-using-iopsnotificationcreaterunloopsource-in-swift and https://stackoverflow.com/questions/50774391/swift-4-getting-thread-1-exc-bad-access-error-with-avfoundation
        let context = UnsafeMutableRawPointer(Unmanaged.passRetained(self).toOpaque())
        // Create an async event listener for power source change events (e.g. plugging or unplugging the charger)
        let loop: CFRunLoopSource = IOPSNotificationCreateRunLoopSource(
            // Updates power
            {(context:UnsafeMutableRawPointer?) in
                let _self = Unmanaged<AppDelegate>.fromOpaque(context!).takeUnretainedValue()
                _self.powerSourceDidChange()
            }, context).takeRetainedValue() as CFRunLoopSource
        
        // Registers the listener
        CFRunLoopAddSource(CFRunLoopGetCurrent(), loop, CFRunLoopMode.defaultMode)
        
        // Updates the menu bar for the first time
        powerSourceDidChange()
    }
    
    // Event handler for power source change
    func powerSourceDidChange(){
        let unmanagedDict:Unmanaged<CFDictionary>? = IOPSCopyExternalPowerAdapterDetails()
        var watts = 0
        // Converts the CFDict into a Swift dict so we don't get nasty null pointer errors
        // Thanks https://stackoverflow.com/questions/59458981/cfdictionarygetvalue-throws-exc-bad-access
        if let dict = unmanagedDict?.takeRetainedValue() as? [String:Any]{
            // This might fail so it's all optional (e.g. watts isn't available when there's no charger present
            if let maybeWatts = dict[kIOPSPowerAdapterWattsKey] as? Int{
                watts = maybeWatts
            }
        }
        statusItem.button?.title=String(format:"%d W", watts)
    }

    func applicationWillTerminate(_ notification: Notification) {
    }
}

