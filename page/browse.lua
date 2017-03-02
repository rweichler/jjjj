
ffi.cdef'struct CGColor {};'
_G.BROWSECONTROLLER = objc.UINavigationController:alloc():initWithRootViewController(VIEWCONTROLLER(function(m)
    m:view():setBackgroundColor(objc.UIColor:whiteColor())

    local ws = ns.websocket:new('ws://app.r333d.com')
    local gotinitial = false

    local textboxheight = 32
    local frame = m:view():bounds()
    frame.size.height = frame.size.height - textboxheight
    local scroll = ui.scroll:new()
    scroll.m:setFrame(frame)
    m:view():addSubview(scroll.m)
    scroll.m:setContentSize{SCREEN.WIDTH, SCREEN.HEIGHT * 20}

    local textview = objc.UIView:alloc():initWithFrame{{0, frame.size.height - BARHEIGHT()},{frame.size.width, textboxheight}}
    m:view():addSubview(textview)

    local textbox = ui.textbox:new()
    local f = textview:frame()
    textbox.m:setFrame{{10, 0}, {f.size.width - 70, f.size.height}}
    textbox.m:setBackgroundColor(objc.UIColor:whiteColor())
    do
        local layer = textbox.m:layer()
        layer:setCornerRadius(5)
        layer:setBorderColor(objc.UIColor:grayColor():CGColor())
        layer:setBorderWidth(1)
        textbox.m:setClipsToBounds(true)
    end
    textview:addSubview(textbox.m)

    local button = ui.button:new()
    button:setTitle('Send')
    button.m:setFrame{{f.size.width - 60, 0},{60, f.size.height}}
    button:setColor(objc.UIColor:grayColor())
    textview:addSubview(button.m)

    function button.ontoggle()
        if not gotinitial or textbox.m:text():length() == 0 then return end
        ws:write(textbox.m:text())
        textbox.m:setText('')
    end

    function button.ondrag()
        print('draggin')
    end

    local keyboardup = false
    local disablescroll = false

    function scroll.onscroll(_, x, y)
        if disablescroll then return end
        textbox.m:resignFirstResponder()
        if keyboardup then
            keyboardup = false
            local h = frame.size.height - BARHEIGHT()
            ANIMATE(0.3, function(finished)
                if not(finished == nil) then return end
                textview:setFrame{{0, h},textview:frame().size}
                scroll.m:setFrame{{0, 0}, {SCREEN.WIDTH, h}}
            end)
        end
    end

    local keyboardsize = 80

    function textbox.onactive()
        print('animating for keyboardsize: '..keyboardsize)
        keyboardup = true
        disablescroll = true
        local h = frame.size.height - keyboardsize
        scroll.m:setContentOffset{0, scroll.m:contentSize().height - h + scroll.m:contentInset().bottom}
        ANIMATE(0.3, function(finished)
            if not(finished == nil) then
                disablescroll = false
                return
            end
            textview:setFrame{{0, h},textview:frame().size}
            scroll.m:setFrame{{0, 0}, {SCREEN.WIDTH, h}}
            disablescroll = false
        end)
    end

    local target = ns.target:new()
    objc.NSNotificationCenter:defaultCenter():addObserver_selector_name_object(target.m, target.sel, C.UIKeyboardWillChangeFrameNotification, nil)

    function target.onaction(_, notification)
        local rect = notification.userInfo:valueForKey(C.UIKeyboardFrameEndUserInfoKey):CGRectValue()
        local changed = not(keyboardsize == rect.size.height)
        keyboardsize = rect.size.height
        if changed then
            textbox.onactive()
        end
    end

    local label = objc.UILabel:alloc():initWithFrame{{0, 0},{SCREEN.WIDTH, SCREEN.HEIGHT*30}}
    --label:setText('TODO: put an integrated /r/jailbreak browser here... or something\n\nbtw, the source code to this app is in /var/lua/jjjj.app. If you want to add new repos edit /var/lua/jjjj.app/page/repos.lua\n\ngithub.com/rweichler/jjjj')
    label:setText('Loading chat...')
    label:setNumberOfLines(0)
    label:sizeToFit()
    scroll.m:addSubview(label)

    function ws:onmessage(str)
        local y = scroll.m:contentOffset().y
        local bottom = scroll.m:contentSize().height - scroll.m:bounds().size.height + scroll.m:contentInset().bottom
        local wasnearbottom = not gotinitial or y + 40 > bottom

        if not gotinitial then
            label:setText(str)
            gotinitial = true
            button:setColor(objc.UIColor:blueColor())
        else
            local str = objc.tolua(label:text())..objc.tolua(str)..'\n'
            label:setText(str)
        end

        local size = label:sizeThatFits{SCREEN.WIDTH, math.huge}
        local frame = label:frame()
        label:setFrame{frame.origin,size}
        scroll.m:setContentSize{SCREEN.WIDTH, size.height}

        if wasnearbottom then
            disablescroll = true
            scroll.m:setContentOffset{0, scroll.m:contentSize().height - scroll.m:bounds().size.height + scroll.m:contentInset().bottom}
            disablescroll = false
        end
    end
    ws:connect()
end, 'Chat'))
local path = RES_PATH..'/globe.png'
BROWSECONTROLLER:tabBarItem():setImage(objc.UIImage:imageWithContentsOfFile(path))

table.insert(TABCONTROLLERS, BROWSECONTROLLER)
