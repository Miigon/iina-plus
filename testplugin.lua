iina.alert([[
Welcome!

This is a test plugin for IINA Plus.
An unofficial version of IINA that allows home-made plugins to run.

After this alert, a listenner listening for `player.openWindow` event will be attached.
LUA_VERSION:]].._VERSION
)

function cb(url)
    iina.alert('testplugin: a window with following file is being opened ;)\n\n'..url)
end


function listen_and_alert_when_triggered(event)
    local function universal_cb(...)
        local arg = {...}
        local argstring = {}
        for i=1,#arg do
            argstring[i] = tostring(arg[i]) or ("["..type(arg[i]).."]")
        end
        iina.alert(event.."("..table.concat(argstring,",")..")")
    end
    iina.listen(event,universal_cb)
end

iina.listen('player.openWindow',cb)
--listen_and_alert_when_triggered('player.togglePause')
iina.listen('player.togglePause',function()
    iina.showOSD.withSubtext("Hello,there!","pausing is forbidden!")
    return false
end)