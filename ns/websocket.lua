local super = Object
ns.websocket = Object.new(super)

function ns.websocket:new(url, ...)
    assert(url)
    local self = super.new(self, ...)

    self.url = url
    self.m = self.class:alloc():initWithURL_protocols(objc.NSURL:URLWithString(self.url), nil)
    objc.Lua(self.m, self)
    self.m:setDelegate(self.m)

    return self
end

function ns.websocket:write(str)
    self.m:writeString(str)
end

function ns.websocket:connect()
    self.m:connect()
end

function ns.websocket:onconnect()
end

function ns.websocket:ondisconnect()
end

function ns.websocket:ondata(data)
end
function ns.websocket:onmessage(str)
end

ns.websocket.class = objc.GenerateClass('JFRWebSocket')
local class = ns.websocket.class

objc.addmethod(class, 'websocketDidConnect:', function(self, socket)
    local this = objc.Lua(self)
    this:onconnect()
end, ffi.arch == 'arm64' and 'v24@0:8@16' or 'v12@0:4@8')

objc.addmethod(class, 'websocketDidDisconnect:error:', function(self, socket, err)
    local this = objc.Lua(self)
    this:ondisconnect()
end, ffi.arch == 'arm64' and 'v32@0:8@16@24' or 'v16@0:4@8@12')

objc.addmethod(class, 'websocket:didReceiveMessage:', function(self, socket, str)
    local this = objc.Lua(self)
    this:onmessage(str)
end, ffi.arch == 'arm64' and 'v32@0:8@16@24' or 'v16@0:4@8@12')

objc.addmethod(class, 'websocket:didReceiveData:', function(self, socket, data)
    local this = objc.Lua(self)
    this:ondata(data)
end, ffi.arch == 'arm64' and 'v32@0:8@16@24' or 'v16@0:4@8@12')

return ns.websocket
