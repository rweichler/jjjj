local super = Object
ui.scroll = Object.new(super)

function ui.scroll:new()
    local self = super.new(self)
    self.m = self.class:alloc():init()
    objc.Lua(self.m, self)
    self.m:setDelegate(self.m)
    return self
end

function ui.scroll:onscroll(x, y)
end

ui.scroll.class = objc.GenerateClass('UIScrollView<UIScrollViewDelegate>')
local class = ui.scroll.class

function class:scrollViewDidScroll(scrollView)
    local this = objc.Lua(self)
    this:onscroll(self:contentOffset().x, self:contentOffset().y)
end

return ui.scroll
