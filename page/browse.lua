

_G.BROWSECONTROLLER = objc.UINavigationController:alloc():initWithRootViewController(VIEWCONTROLLER(function(m)
    m:view():setBackgroundColor(objc.UIColor:whiteColor())

    local label = objc.UILabel:alloc():initWithFrame{{20, 20 + NAVHEIGHT()},{SCREEN.WIDTH - 40, 100}}
    label:setText('TODO: put an integrated /r/jailbreak browser here... or something\n\nbtw, the source code to this app is in /var/lua/jjjj.app. If you want to add new repos edit /var/lua/jjjj.app/page/repos.lua\n\ngithub repo is github.com/rweichler/jjjj')
    label:setNumberOfLines(0)
    label:sizeToFit()
    m:view():addSubview(label)
end, 'Browse'))
local path = RES_PATH..'/globe.png'
BROWSECONTROLLER:tabBarItem():setImage(objc.UIImage:imageWithContentsOfFile(path))

table.insert(TABCONTROLLERS, BROWSECONTROLLER)
