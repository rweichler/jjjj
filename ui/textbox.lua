local super = Object
ui.textbox = Object.new(super)

function ui.textbox:new()
    local self = super.new(self)
    self.m = self.class:alloc():init()
    objc.Lua(self.m, self)
    self.m:setDelegate(self.m)
    return self
end

function ui.textbox:onactive()
end

ui.textbox.class = objc.GenerateClass('UITextField')
local class = ui.textbox.class

objc.addmethod(class, 'textFieldDidBeginEditing:', function(self, field)
    local this = objc.Lua(self)
    this:onactive()
end, ffi.arch == 'arm64' and 'v24@0:8@16' or 'v12@0:4@8')


return ui.textbox
