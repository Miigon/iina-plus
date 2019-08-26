//
//  PluginCore.swift
//  iina
//
//  Created by Miigon on 2019/8/25.
//  Copyright © 2019 lhc. All rights reserved.
//

import Foundation
import Lua

class PluginCore{
  static let shared = PluginCore()
  static let subsystem = Logger.Subsystem(rawValue: "plugin")
  
  var pluginLoaded = [String: Plugin]()
  var vmspaces = [String: Lua.VirtualMachine]()
  
  // event: callbackList
  var listenners = [String: [Lua.Function]]()
  init() {
    listenners["player.openWindow"] = Array()
    listenners["player.togglePause"] = Array()
  }
  
  func initPluginCore() { // `applicationDidFinishLaunching()` in AppDelegate
    // Temporary code to test the plugin system
    let testplugin = loadPlugin(identifier: "miigon.testplugin")
    _ = testplugin.luavm.eval(URL(fileURLWithPath: NSHomeDirectory() + "/.iina-plus/plugins/testplugin.lua"))
    
  }
  
  // initialize luavm and load all iina apis.
  private func initializeLuaVM(_ luavm: Lua.VirtualMachine) {
    let iina = luavm.createTable()
    
    // Show an OSD message on currently active PlayerCore
    let showOSD = luavm.createTable()
    showOSD["normal"] = luavm.createFunction([String.arg]) { args in
      let (text) = (args.string)
      PlayerCore.lastActive.sendOSD(.general(text))
      return .nothing
    }
    showOSD["withSubtext"] = luavm.createFunction([String.arg, String.arg]) { args in
      let (text, subtext) = (args.string, args.string)
      PlayerCore.lastActive.sendOSD(.generalWithSubtext(text, subtext))
      return .nothing
    }
    showOSD["withProgress"] = luavm.createFunction([String.arg, String.arg]) { args in
      let (text, progress) = (args.string, args.double)
      PlayerCore.lastActive.sendOSD(.generalWithProgress(text, progress))
      return .nothing
    }
    iina["showOSD"] = showOSD
    
    // Logger.log
    iina["log"] = luavm.createFunction([String.arg]) { args in
      let (message) = (args.string)
      Logger.log(message, subsystem: PluginCore.subsystem)
      return .nothing
    }
    
    // Show an alert box
    iina["alert"] = luavm.createFunction([String.arg]) { args in
      let (message) = (args.string)
      Utility.showAlert(message: message, alertStyle: .informational)
      return .nothing
    }
    
    // Attach a listenner
    iina["listen"] = luavm.createFunction([String.arg, Function.arg]) { args in
      let (event,callback) = (args.string, args.function)
      if let callbackList = self.listenners[event] {
        Logger.log("a listenner is being attached for " + event, subsystem: PluginCore.subsystem)
        self.listenners[event]!.append(callback)
        return .value(callbackList.count)
      } else {
        // Invaild event type
        Logger.log("failed to attach listenner: " + event, subsystem: PluginCore.subsystem)
        return .value(-1)
      }
    }
    
    luavm.globals["iina"] = iina
  }
  
  class Plugin{
    // description
    let identifier: String
    let vmspace: String
    
    // runtime state
    var luavm: Lua.VirtualMachine
    
    init(identifier: String, vmspace: String, luavm: Lua.VirtualMachine) {
      self.identifier = identifier
      self.vmspace = vmspace
      self.luavm = luavm
    }
  }
  
  func loadPlugin(identifier: String, vmspace: String? = nil) -> Plugin {
    
    // Use identifier as vmspace name by default
    let vmspaceName: String
    if let vmspaceUnwrapped = vmspace {
      vmspaceName = vmspaceUnwrapped
    } else {
      vmspaceName = identifier
    }
    
    // Reuse vm of the same vmspace, or create a new vm
    let luavm: Lua.VirtualMachine
    if let existingvm = vmspaces[vmspaceName] {
      luavm = existingvm
    } else {
      luavm = Lua.VirtualMachine()
      initializeLuaVM(luavm)
      vmspaces[vmspaceName] = luavm
    }
    let plugin = Plugin(identifier: identifier, vmspace: vmspaceName, luavm: luavm)
    pluginLoaded[identifier] = plugin
    return plugin
  }
  
  /* MARK: - Event Callback */

  func dispatchEvent(_ event: String,_ dispatcher: (_ callback: Lua.Function) -> Bool) -> Bool {
    var ret = true
    if let callbackList = listenners[event] {
      for callback in callbackList {
        if dispatcher(callback) == false {
          ret = false
        }
      }
    }
    return ret
  }
  
  func dispatchEvent(_ event: String) -> Bool { // with default dispatcher
    return dispatchEvent(event) { (callback) -> Bool in
      let result = callback.call([])
      // TODO: properly handle return value
      return false
    }
  }
  
  func dispatchEvent(_ event: String,_ args: [Lua.Value]) -> Bool { // with arguments
    return dispatchEvent(event) { (callback) -> Bool in
      _ = callback.call(args)
      return false
    }
  }
  
  func cb_player_openWindow(_ url: String) { // `openMainWindow()` in PlayerCore, at the beginning, right after `Logger.log()`
    Logger.log("dispatching event: player.openWindow", subsystem: PluginCore.subsystem)
    dispatchEvent("player.openWindow",[url])
  }
  
  func cb_player_togglePause(_ paused: Bool) -> Bool {
    Logger.log("dispatching event: player.togglePause", subsystem: PluginCore.subsystem)
    return dispatchEvent("player.togglePause",[paused])
  }
  
}

