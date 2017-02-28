

_G.BROWSECONTROLLER = objc.UINavigationController:alloc():initWithRootViewController(VIEWCONTROLLER(function(m)
    m:view():setBackgroundColor(objc.UIColor:whiteColor())

    local label = objc.UILabel:alloc():initWithFrame{{20, 20 + NAVHEIGHT()},{SCREEN.WIDTH - 40, 100}}
    label:setText('TODO: put an integrated /r/jailbreak browser here... or something')
    label:setNumberOfLines(0)
    label:sizeToFit()
    m:view():addSubview(label)
end, 'Browse'))
local path = RES_PATH..'/globe.png'
BROWSECONTROLLER:tabBarItem():setImage(objc.UIImage:imageWithContentsOfFile(path))

table.insert(TABCONTROLLERS, BROWSECONTROLLER)
