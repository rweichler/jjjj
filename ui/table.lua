local super = Object
ui.table = Object.new(super)

function ui.table:new()
    local self = super.new(self)
    self.m = self.class:alloc():init()
    objc.Lua(self.m, self)
    self.m:setDelegate(self.m)
    self.m:setDataSource(self.m)
    self.items = {}
    self.cell = ui.cell:new()
    return self
end

function ui.table:init()
end

function ui.table:getmcell(section, row)
    local indexPath = objc.NSIndexPath:indexPathForRow_inSection(row-1, section-1)
    return self.m:cellForRowAtIndexPath(indexPath) or error 'wtf'
end

function ui.table:refresh()
    self.m:reloadData()
end

function ui.table:getcell(section, row)
    if self.cell then
        self.cell.table = self
        return self.cell
    else
        error('wat??')
    end
end

function ui.table:onscroll(x, y)
end

ui.table.class = objc.GenerateClass('UITableView', 'UITableViewDelegate', 'UITableViewDataSource', 'UIScrollViewDelegate')
local class = ui.table.class

function class:tableView_didSelectRowAtIndexPath(tableView, indexPath)
    local this = objc.Lua(self)
    local section, row = tonumber(indexPath:section()) + 1, tonumber(indexPath:row()) + 1

    local cell = this:getcell(section, row)
    cell:onselect(section, row)

    tableView:deselectRowAtIndexPath_animated(indexPath, true)

end

function class:tableView_heightForRowAtIndexPath(tableView, indexPath)
    local this = objc.Lua(self)
    local section, row = tonumber(indexPath:section()) + 1, tonumber(indexPath:row()) + 1

    local cell = this:getcell(section, row)
    return cell:getheight(section, row)
end

function class:tableView_numberOfRowsInSection(tableView, section)
    local this = objc.Lua(self)
    local section = tonumber(section) + 1

    return #this.items[section]
end

function class:numberOfSectionsInTableView(tableView)
    local this = objc.Lua(self)

    return #this.items
end

function class:scrollViewDidScroll(scrollView)
    local this = objc.Lua(self)
    this:onscroll(self:contentOffset().x, self:contentOffset().y)
end

function class:tableView_cellForRowAtIndexPath(tableView, indexPath)
    local this = objc.Lua(self)
    local section, row = tonumber(indexPath:section()) + 1, tonumber(indexPath:row()) + 1

    local cell = this:getcell(section, row)
    local m = self:dequeueReusableCellWithIdentifier(cell.identifier)
    if m == ffi.NULL then
        m = cell:mnew()
    end

    return m
end

function class:tableView_willDisplayCell_forRowAtIndexPath(tableView, mcell, indexPath)
    local this = objc.Lua(self)
    local section, row = tonumber(indexPath:section()) + 1, tonumber(indexPath:row()) + 1

    local cell = this:getcell(section, row)
    cell:onshow(mcell, section, row)
end

return ui.table
