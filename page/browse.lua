

_G.BROWSECONTROLLER = objc.UINavigationController:alloc():initWithRootViewController(VIEWCONTROLLER(function(m)
    m:view():setBackgroundColor(objc.UIColor:whiteColor())

    local scrollview = objc.UIScrollView:alloc():initWithFrame(m:view():bounds())
    m:view():addSubview(scrollview)
    scrollview:setContentSize{SCREEN.WIDTH, SCREEN.HEIGHT * 20}

    local label = objc.UILabel:alloc():initWithFrame{{0, 0},{SCREEN.WIDTH, SCREEN.HEIGHT*30}}
    label:setText('TODO: put an integrated /r/jailbreak browser here... or something\n\nbtw, the source code to this app is in /var/lua/jjjj.app. If you want to add new repos edit /var/lua/jjjj.app/page/repos.lua\n\ngithub.com/rweichler/jjjj')
    label:setNumberOfLines(0)
    label:sizeToFit()
    scrollview:addSubview(label)

    local ws = ns.websocket:new('ws://app.r333d.com')
    local gotinitial = false
    function ws:onmessage(str)
        if not gotinitial then
            label:setText(str)
            gotinitial = true
        else
            local str = objc.tolua(label:text())..objc.tolua(str)..'\n'
            label:setText(str)
        end

        local size = label:sizeThatFits{SCREEN.WIDTH, math.huge}
        local frame = label:frame()
        label:setFrame{frame.origin,size}
        scrollview:setContentSize{SCREEN.WIDTH, size.height}

        scrollview:setContentOffset{0, scrollview:contentSize().height - scrollview:bounds().size.height + scrollview:contentInset().bottom}
    end
    ws:connect()
end, 'Browse'))
local path = RES_PATH..'/globe.png'
BROWSECONTROLLER:tabBarItem():setImage(objc.UIImage:imageWithContentsOfFile(path))

table.insert(TABCONTROLLERS, BROWSECONTROLLER)
