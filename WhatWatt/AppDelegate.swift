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
    private var chargerDetail: NSMenuItem!
    let STR_NOT_CHARGING = "Not Charging"
    let STR_CHARGING_BUT_NO_AMPS_VOLTS = "Charging"

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Thanks  https://sarunw.com/posts/how-to-make-macos-menu-bar-app/
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        chargerDetail = NSMenuItem(title: STR_NOT_CHARGING, action: nil, keyEquivalent: "")
        chargerDetail.isEnabled = false
        let menu = NSMenu()
        menu.addItem(chargerDetail)
        menu.addItem(NSMenuItem.separator())
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
        var amps = 0.0
        var volts = 0.0
        var hasValidVoltsAndAmps = false
        // Converts the CFDict into a Swift dict so we don't get nasty null pointer errors
        // Thanks https://stackoverflow.com/questions/59458981/cfdictionarygetvalue-throws-exc-bad-access
        if let dict = unmanagedDict?.takeRetainedValue() as? [String:Any]{
            // This might fail so it's all optional (e.g. watts isn't available when there's no charger present
            if let maybeWatts = dict[kIOPSPowerAdapterWattsKey] as? Int{
                watts = maybeWatts
                // Try to also get amps, with which we can use to calculate volts
                if let maybeAmps = dict[kIOPSPowerAdapterCurrentKey] as? Double{
                    amps = maybeAmps / 1000.0
                    if abs(amps) >= 1E-9{
                        volts = Double(watts) / amps
                        hasValidVoltsAndAmps = true
                    }
                }
            }
        }
        statusItem.button?.title=String(format:"%d W", watts)
        if hasValidVoltsAndAmps{
            // Display full information if we have valid volts and amps readings
            chargerDetail.title = String(format:"%.02f V,   %.02f A", volts, amps)
        }
        else{
            if watts != 0{
                // If we have watts but are somehow unable to get volts and/or amps, display a generic "I'm still charging" message
                chargerDetail.title = STR_CHARGING_BUT_NO_AMPS_VOLTS
            }
            else{
                // If we don't have volts and amps, and watts is zero, then we're most likely not charging.
                chargerDetail.title = STR_NOT_CHARGING
            }
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
    }
}

