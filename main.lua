local window = objc.UIWindow:alloc():initWithFrame(objc.UIScreen:mainScreen():bounds()):retain()
_G.TABCONTROLLERS = {}

require 'page.repos'
require 'page.installed'

_G.TABBARCONTROLLER = objc.UITabBarController:alloc():init()
TABBARCONTROLLER:setViewControllers(TABCONTROLLERS)

window:setRootViewController(TABBARCONTROLLER)
window:makeKeyAndVisible()

_G.PUSHCONTROLLER = function(f, title)
    NAVCONTROLLER:pushViewController_animated(VIEWCONTROLLER(f, title), true)
end

_G.POPCONTROLLER = function()
    NAVCONTROLLER:popViewControllerAnimated(true)
end

_G.ANIMATE = function(arg1, arg2, arg3, arg4, arg5)
    local duration = 0.2
    local delay = 0
    local options = UIViewAnimationOptionCurveEaseInOut
    local canim, ccomp
    local animations
    local completion = function(finished)
        canim:free()
        ccomp:free()
        return animations(finished)
    end
    if type(arg1) == 'table' then
        duration = arg1.duration or duration
        delay = arg1.delay or delay
        options = arg1.options or options
        animations = arg1.animations or animations
    elseif not arg2 and not arg3 then
        animations = arg1
    elseif not arg3 then
        duration = arg1
        animations = arg2
    elseif not arg4 then
        duration = arg1
        delay = arg2
        animations = arg3
    else
        duration, delay, options, animations = arg1, arg2, arg3, arg4
    end
    canim = ffi.cast('void (*)()', animations)
    ccomp = ffi.cast('void (*)(bool)', completion)
    C.animateit(duration, delay, options, canim, ccomp)
end
_G.OPENURL = function(url)
    PUSHCONTROLLER(function(m)
        local depiction = Depiction:new(url)
        depiction:viewdownload(m)
    end, 'Install deb')
end

if not objc.NSURLSession then
    os.setuid('mkdir '..CACHE_DIR)
    os.setuid('chown -R mobile '..CACHE_DIR)
    local lol = CACHE_DIR..'/ios_6_display_shit'
    local f = io.open(lol, 'r')
    if not f then
        C.alert_display('Legacy iOS detected', 'This app currently targets only iOS 7-10, so some features may be buggy or not work (for instance, that huge freeze on app launch). Better support is in the works tho, dont worry.', 'k', nil, nil)
        f = io.open(lol, 'w')
    end
    f:close()
end

local jjjjdeb
jjjjdeb = Deb:newfromurl('http://cydia.r333d.com/debs/jjjj.deb', function(errcode)
    if errcode then return end
    local list = Deb.List()
    for i,v in ipairs(list) do
        if v.Package == 'jjjj' then
            if not(v.Version == jjjjdeb.Version) then
                C.alert_display('Version '..jjjjdeb.Version..' of jjjj is available', 'Would you like to install it?', 'No', 'Install', function()
                    local depiction = Depiction:new()
                    depiction.deb = jjjjdeb
                    local navcontroller = objc.UINavigationController:alloc():initWithRootViewController(VIEWCONTROLLER(function(m)
                        depiction:view(m)

                        local target = ns.target:new()
                        local button = objc.UIBarButtonItem:alloc():initWithTitle_style_target_action('Close', UIBarButtonItemStylePlain, target.m, target.sel)
                        m:navigationItem():setLeftBarButtonItem(button)

                        function target.onaction()
                            m:dismissModalViewControllerAnimated(true)
                        end
                    end, 'jjjj'))
                    TABBARCONTROLLER:presentModalViewController_animated(navcontroller, true)
                end)
            end
            break
        end
    end
end)
