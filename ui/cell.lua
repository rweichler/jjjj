local super = Object
ui.cell = Object.new(super)

local count = 0
function ui.cell:new()
    local self = super.new(self)
    self.identifier = objc.toobj('hax'..count)
    count = count + 1
    return self
end

function ui.cell:getheight(section, row)
    return 44
end

function ui.cell:onshow(m, section, row)
    local o = self.table.items[section][row]
    m:textLabel():setText(tostring(o))
end

function ui.cell:onselect(section, row)
end

function ui.cell:mnew()
    local m = objc.UITableViewCell:alloc():initWithStyle_reuseIdentifier(3, self.identifier)
    objc.Lua(m, {})
    return m
end

ui.cell.class = objc.GenerateClass('UITableViewCell')
local class = ui.cell.class

return ui.cell
