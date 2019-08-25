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
  }
  
  func initPluginCore() { // `applicationDidFinishLaunching()` in AppDelegate
    // Temporary code to test the plugin system
    let testplugin = loadPlugin(identifier: "miigon.testplugin")
    let _ = testplugin.luavm.eval("iina.alert(\"Welcome!\\n\\nThis is a test plugin for IINA Plus.\\nAn unofficial version of IINA that allows home-made plugins to run.\\n\\nAfter this alert, a listenner listening for `player.openWindow` event will be attached.\")")
    let _ = testplugin.luavm.eval("function cb(url) iina.alert('testplugin: a window with following file is being opened ;)\\n\\n'..url) end;iina.listen('player.openWindow',cb)")
  }
  
  private func initializeLuaVM(_ luavm: Lua.VirtualMachine){
    let iina = luavm.createTable()
    
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
        Logger.log("a listenner is being attached for " + event,subsystem: PluginCore.subsystem)
        self.listenners[event]!.append(callback)
        return .value(callbackList.count)
      } else {
        // Invaild event type
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
    
    init(identifier: String, vmspace: String, luavm: Lua.VirtualMachine){
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

  func dispatchEvent(_ event: String,_ dispatcher: (_ callback: Lua.Function) -> Void)
  {
    if let callbackList = listenners[event] {
      for callback in callbackList {
        dispatcher(callback)
      }
    }
  }
  
  func cb_player_openWindow(_ url: String){ // `openMainWindow()` in PlayerCore, at the beginning, right after `Logger.log()`
    Logger.log("dispatching event: player.openWindow", subsystem: PluginCore.subsystem)
    dispatchEvent("player.openWindow") { (callback) in
      let _ = callback.call([url])
    }
  }
  
}

