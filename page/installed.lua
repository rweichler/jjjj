local tbl = ui.filtertable:new()
tbl.items = {}
tbl.deblist = Deb.List()

function tbl:search(text, item)
    local function find(s)
        if s then
            local success, result = pcall(string.find, string.lower(s), string.lower(text))
            return not success or result
        end
        return s and string.find(string.lower(s), string.lower(text))
    end
    return find(item.Name) or find(item.Package)
end

tbl.cell = ui.cell:new()
tbl.cell.identifier = objc.toobj('lolwatttt')
function tbl.cell.onselect(_, section, row)
    local depiction = Depiction:new()
    depiction.deb = tbl.items[section][row]
    PUSHCONTROLLER(function(m)
        depiction:view(m)
    end, depiction:gettitle())
end

function tbl.cell:onshow(m, section, row)
    local deb = tbl.items[section][row]
    if not deb then return end

    local img = nil
    if deb.Section then
        local path = '/Applications/Cydia.app/Sections/'..string.gsub(deb.Section, ' ', '_')..'.png'
        local f = io.open(path, 'r')
        if f then
            f:close()
        else
            path = '/Applications/Cydia.app/unknown.png'
        end
        img = objc.UIImage:imageWithContentsOfFile(path)
    end

    m:imageView():setImage(img)
    m:textLabel():setText(deb.Name or deb.Package)
    m:detailTextLabel():setText(deb.Description or '')
end
tbl:refresh()

HOOK(Deb, 'UpdateList', function(orig, ...)
    tbl.deblist = Deb.List()
    tbl:refresh()
    return orig(...)
end)

_G.NAVCONTROLLER = objc.UINavigationController:alloc():initWithRootViewController(VIEWCONTROLLER(function(m)
    tbl.m:setFrame(m:view():bounds())
    m:view():addSubview(tbl.m)
end, 'Installed'))

_G.NAVHEIGHT = function()
    return 64
end

_G.BARHEIGHT = function()
    -- TODO return 56 on iOS 7
    return 49
end


local path = '/Applications/Cydia.app/manage7@2x.png'
NAVCONTROLLER:tabBarItem():setImage(objc.UIImage:imageWithContentsOfFile(path))

table.insert(TABCONTROLLERS, NAVCONTROLLER)
