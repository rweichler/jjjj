local super = Object
ns.target = Object.new(super)

local newmproxy -- forward decl
local methodname = 'doItLololol:'

local flags = {}
function ns.target:new(sel)
    local self = super.new(self)

    self.m = newmproxy(self)
    self.sel = objc.SEL(sel or methodname)

    return self
end

function ns.target:onaction()
end

newmproxy = function(self)
    local class = objc.GenerateClass()
    objc.addmethod(class, methodname, function(_, ...)
        self:onaction(...)
    end, ffi.arch == 'arm64' and 'v24@0:8@16' or 'v12@0:4@8')
    return class:alloc():init()
end

return ns.target
