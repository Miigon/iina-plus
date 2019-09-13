iina.alert([[
Welcome!

This is a test plugin for IINA Plus.
An unofficial version of IINA that allows home-made plugins to run.

After this alert, a listenner listening for `player.openWindow` event will be attached.
LUA_VERSION:]].._VERSION
)

iina.listen('player.openWindow',function(url)
    iina.alert('testplugin: a window with following file is being opened ;)\n\n'..url)
end)

local try = 5
iina.listen('player.togglePause',function(paused)
    if paused == false then return "pass" end -- We don't care about user resuming the video.
    if try == 0 then
        iina.showOSD.withSubtext("You DID it!","congratulations!")
        try = 5
        return "interrupt",true
    else
        iina.showOSD.withSubtext("Hello,there!","Try ".. tostring(try) .." more times to pause the video")
        try = try - 1
    end
    return "interrupt",false
end)

iina.listen('player.sendOSD',function(msg)
    if msg == "继续" or msg == "暂停" then -- Disable `pause` and `resume` osd messages
        return "interrupt",false
    end
end)