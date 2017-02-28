local super = Object
ui.gesture = Object.new(super)

local newmproxy -- forward decl
local methodname = 'doItLololol:'

local flags = {}
function ui.gesture:new(class)
    assert(class)
    local self = super.new(self)

    self.class = class

    self.mproxy = newmproxy(self)

    self.m = self.class:alloc():initWithTarget_action(self.mproxy, objc.SEL(methodname))
    objc.Lua(self.m, self)

    return self
end

function ui.gesture:onevent()
end

newmproxy = function(self)
    local class = objc.GenerateClass()
    objc.addmethod(class, methodname, function()
        self:onevent()
    end, ffi.arch == 'arm64' and 'v24@0:8@16' or 'v12@0:4@8')
    return class:alloc():init()
end

return ui.gesture
