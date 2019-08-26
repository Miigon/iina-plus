iina.alert([[
Welcome!

This is a test plugin for IINA Plus.
An unofficial version of IINA that allows home-made plugins to run.

After this alert, a listenner listening for `player.openWindow` event will be attached.]]
)

function cb(url)
    iina.alert('testplugin: a window with following file is being opened ;)\n\n'..url)
end
iina.listen('player.openWindow',cb)