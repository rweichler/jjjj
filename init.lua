if jit.arch == 'arm64' then
    -- arm64 JIT not stable
    jit.off()
end

local argc, argv = ...
package.path = PATH..'/?.lua;'..
               PATH..'/?/init.lua;'..
               package.path

require 'constants'
config = require 'config'
ffi = require 'ffi'
C = ffi.C
bit = require 'bit'
objc = require 'objc'

require 'util'
require 'cdef'

function Cmd(cmd, f)
    C.pipeit(APP_PATH..'/setuid /usr/bin/env '..cmd, f)
end

function HOOK(t, k, hook)
    local orig = t[k]
    if not(type(orig) == 'function') then
        error('invalid type')
    end
    t[k] = function(...)
        return hook(orig, ...)
    end
end

local count = 0
function objc.GenerateClass(super, ...)
    super = super or 'NSObject'
    count = count + 1
    local name = 'DPKGAPP_'..count..super

    if ... then
        objc.class(name, super..'<'..table.concat({...}, ',')..'>')
    else
         objc.class(name, super)
    end

    return objc[name]
end
local objc_objz = {}
function objc.AssocLua(obj, set)
    local hash = tonumber(ffi.cast('uintptr_t',obj))
    local result = objc_objz[hash]
    if set then
        if result then error('wtf???') end
        objc_objz[hash] = set
        result = set
    end
    return result
end

function objc.Lua(...)
    return objc.AssocLua(...)
end


function VIEWCONTROLLER(callback, title)
    local m = objc.GenerateClass('UIViewController'):alloc():init()
    m:setTitle(title or '')
    if callback then
        function m:viewDidLoad()
            callback(m)
        end
    end
    return m
end

Object = require 'object'
Deb = require 'deb'
Depiction = require 'depiction'
Repo = require 'repo'

ui = {}
require 'ui.table'
require 'ui.filtertable'
require 'ui.cell'
require 'ui.searchbar'
require 'ui.button'
require 'ui.gesture'

ns = {}
require 'ns.target'
require 'ns.http'

objc.class('AppDelegate', 'UIResponder')

objc.addmethod(objc.AppDelegate, 'application:didFinishLaunchingWithOptions:', function(self, app, options)
    require 'main'
    return true
end, ffi.arch == 'arm64' and 'B32@0:8@16@24' or 'B16@0:4@8@12')


objc.addmethod(objc.AppDelegate, 'application:openURL:sourceApplication:annotation:', function(self, app, url, sourceApp, annotation)
    url = objc.tolua(url:absoluteString())
    url = string.sub(url, #'dpkgapp://' + 1, #url)
    OPENURL(url)
    return true
end, ffi.arch == 'arm64' and 'B48@0:8@16@24@32@40' or 'B24@0:4@8@12@16@20')

return C.UIApplicationMain(argc, argv, nil, objc.toobj('AppDelegate'))
