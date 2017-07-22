local super = Object
local Deb = Object.new(super)

function Deb:newfromurl(url, oncomplete, onprogress)
    local self = self:new()
    local dl = ns.http:new()
    dl.download = true
    dl.url = url
    print('Deb:newfromurl("'..url..'")')
    dl.requestheaders = Repo.CydiaHeaders()
    function dl.handler(dl, path, percent, errcode)
        if errcode then
            oncomplete(errcode)
        elseif path then
            if self:init(path) then
                oncomplete()
            end
        elseif percent then
            if onprogress then
                onprogress(percent)
            end
        end
    end
    dl:start()
    return self
end

function Deb:new(path)
    local self = super.new(self)

    if path and not self:init(path) then
        return nil
    end

    return self
end

function Deb.ParseLine(line)
    local colon = string.find(line, ':')
    if colon then
        local k = string.sub(line, 1, colon - 1)
        local v = string.sub(line, colon + 1, #line)
        v = string.match(v, '%s*(.*)')
        return k, v
    end
end

function Deb:getfiles()
    local cmd, regex
    if self.installed then
        cmd = 'dpkg -L '..self.Package
        regex = '(.*)'
    elseif self.path then
        cmd = 'dpkg-deb --contents '..self.path
        regex = '.*%s+%.(/.*)'
    else
        return nil
    end

    local files = {}
    for line in os.setuid(cmd):gmatch"(.-)\n" do
        local path = string.match(line, regex)
        if path then
            files[#files + 1] = path
        end
    end

    return files
end

function Deb:gettweaks()
    local tweaks = {}
    for k, path in ipairs(self:getfiles()) do
        local base = string.match(path, '('..SUBSTRATE_DIR..'/.+)%.dylib')
        if base then
            local dict = objc.NSDictionary:alloc():initWithContentsOfFile(base..'.plist')
            if dict then
                local tweak = objc.tolua(dict)
                tweak.name = string.sub(base, #SUBSTRATE_DIR + 2, #base)
                tweaks[#tweaks + 1] = tweak
            end
        end
    end
    return tweaks
end

function Deb:hasapp()
    for k,path in ipairs(self:getfiles()) do
        if string.match(path, '(/Applications/.+%.app/Info.plist)') then
            return true
        end
    end
    return false
end

local control_dir = '/var/tmp/dpkgappcontrol'
function Deb:init(path)
    local function cleanup()
        os.setuid('rm -rf '..control_dir)
    end
    local function die(reason)
        C.alert_display('Failed getting deb info', reason, 'Dismiss', nil, nil)
        cleanup()
        return false
    end

    cleanup()
    local result, status = os.setuid('dpkg-deb --control '..path..' '..control_dir)
    if not(status == 0) then
        return die(result)
    end
    local f = io.open(control_dir..'/control', 'r')
    if not f then
        return die('No control file')
    end
    for line in f:lines() do
        local k, v = Deb.ParseLine(line)
        if k and v then
            self[k] = v
        end
    end
    f:close()

    if not self.Package then
        return die('Malformed control file')
    end

    local newpath = CACHE_DIR..'/'..self.Package..'.deb'
    os.setuid('mkdir -p '..CACHE_DIR)
    os.setuid('mv '..path..' '..newpath)

    self.path = newpath
    cleanup()
    return true
end

function Deb:uninstall(f)
    Cmd('dpkg --remove '..self.Package, function(str, status)
        if str == ffi.NULL and status == 0 then
            self.installed = false
        end
        f(str, status)
    end)
end

function Deb:install(f)
    Cmd('dpkg -i '..self.path, function(str, status)
        if str == ffi.NULL and status == 0 then
            self.installed = true
        end
        f(str, status)
    end)
end

function Deb.List(path)
    local t = {}
    local f = io.open(path or '/var/lib/dpkg/status', 'r')
    if not f then
        t[1] = {
            Name = 'Error',
            Package = 'error',
            Description = 'File "'..path..'" not found',
        }
        return t
    end

    local filter = path and function(deb) return deb end or function(deb)
        local x = deb.Status
        if x then
            for _, y in ipairs{'ok installed', 'ok unpacked'} do
                if string.sub(x, #x - #y + 1, #x) == y then
                    deb.installed = true
                    return deb
                end
            end
        end
    end

    local map = {}

    local deb
    for line in f:lines() do
        local k,v = Deb.ParseLine(line)
        if k and v then
            if not deb then
                deb = Deb:new()
            end
            deb[k] = v
        elseif deb then
            if deb.Package then
                local deb = filter(deb)
                if deb then
                    local idx = map[deb.Package]
                    local existing = idx and t[idx]
                    if existing then
                        if deb.Version > existing.Version then
                            deb.downgrades = existing.downgrades or {}
                            existing.downgrades = nil
                            table.insert(deb.downgrades, existing)
                            t[idx] = deb
                        else
                            existing.downgrades = existing.downgrades or {}
                            table.insert(existing.downgrades, deb)
                        end
                    else
                        t[#t + 1] = deb
                        map[deb.Package] = #t
                    end
                end
            end
            deb = nil
        end
    end
    f:close()
    t[#t + 1] = deb

    local lower = string.lower
    table.sort(t, function(a, b)
        if a.Name and b.Name then
            return lower(a.Name) < lower(b.Name)
        elseif not a.Name and not b.Name then
            return lower(a.Package) < lower(b.Package)
        elseif a.Name then
            return true
        else
            return false
        end
    end)
    return t
end

function Deb.UpdateList()
end

return Deb
