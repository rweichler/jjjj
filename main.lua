local window = objc.UIWindow:alloc():initWithFrame(objc.UIScreen:mainScreen():bounds()):retain()
_G.TABCONTROLLERS = {}

require 'page.repos'
require 'page.installed'
require 'page.browse'

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
    local animations
    local completion = function(finished)
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
    C.animateit(duration, delay, options, animations, completion)
end
_G.OPENURL = function(url)
    PUSHCONTROLLER(function(m)
        local depiction = Depiction:new(url)
        depiction:viewdownload(m)
    end, 'Install deb')
end
