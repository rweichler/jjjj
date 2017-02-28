local super = Object
local Repo = Object.new(super)

function Repo:new(url)
    local self = super.new(self)
    self.url = url
    self.prettyurl = string.gsub(string.gsub(self.url, 'http://', ''), 'https://', '')
    self.prettyurl = string.sub(self.prettyurl, 1, #self.prettyurl - 1)
    self.cacheurl = string.gsub(self.prettyurl, '/', '-')
    return self
end

function Repo:getrelease(callback)
    local dl = ns.http:new()
    dl.url = (self.releaseurl or self.url)..'Release'
    function dl.handler(dl, data, percent, errcode)
        if errcode then
        elseif data then
            local str = objc.tolua(objc.NSString:alloc():initWithData_encoding(data, NSUTF8StringEncoding))
            for line in (str.."\n"):gmatch"(.-)\n" do
                local k,v = Deb.ParseLine(line)
                if k and v then
                    self[k] = v
                end
            end
            callback()
        end
    end
    dl:start()
end

local map = {}
map['.bz2'] = 'bunzip2'
map['.gz'] = 'gzip -d'
map['Index'] = 'touch'

local HOME = CACHE_DIR..'/repos'

local function import_lua_table(self, callback, ext)
    callback('Importing to Lua table...')
    C.run_async(function()
        if line == ffi.NULL then
            self.debs = Deb.List(self.path)
            for k, deb in ipairs(self.debs) do
                deb.repo = self
            end
            callback()
        end
    end)
end

local function last_modified_warning(self)
    --C.alert_display('Warning', 'This repo does not support the Last-Modified header. This makes listings load slower. Please notify the owner of '..self.prettyurl..' if possible.', 'Dismiss', nil, nil)
end

local function doit(self, callback, info)
    local dl = ns.http:new()
    dl.getheaders = true
    dl.url = self.url..'Packages'..info.ext
    function dl.handler(_, data, percent, errcode)
        if not dl.headers['Last-Modified'] then
            last_modified_warning(self)
        end
        if dl.headers['Last-Modified'] == info.last then
            os.setuid('mkdir -p '..HOME)
            self.path = HOME..'/'..self.cacheurl
            import_lua_table(self, callback, info.ext)
        else
            self:getpackages(callback, '.bz2')
        end
    end
    dl:start()
end

local cachedatadir = HOME..'/cachedata'
function Repo:getpackages(callback, ext)
    if not ext then
        local path = cachedatadir..'/'..self.cacheurl..'.lua'
        local f = io.open(path, 'r')
        if f then
            f:close()
            doit(self, callback, dofile(path))
            return
        end
    end
    ext = ext or '.bz2'
    local dl = ns.http:new()
    dl.url = (self.packagesurl or self.url)..'Packages'..ext
    dl.download = true
    function dl.handler(_, path, percent, errcode)
        print('dl handler??')
        if errcode then
            if errcode == 404 then
                if ext == '.bz2' then
                    self:getpackages(callback, '.gz')
                elseif ext == '.gz' then
                    self:getpackages(callback, 'Index')
                else
                    callback("Error: can't find packages on this repo")
                end
            else
                callback("Error: can't find packages on this repo")
            end
        elseif percent then
            callback('Downloading Packages'..ext..'... '..math.floor(percent*100 + 0.5)..'%')
        elseif path then
            os.setuid('mkdir -p '..cachedatadir)
            os.setuid('chown -R mobile '..cachedatadir)
            if dl.headers['Last-Modified'] then
                local f = io.open(cachedatadir..'/'..self.cacheurl..'.lua', 'w')
                f:write('return {\n')
                f:write('    last = '..dl.headers['Last-Modified']..',\n')
                f:write('    ext = "'..ext..'",\n')
                f:write('}')
                f:close()
            else
                last_modified_warning(self)
            end
            os.setuid('mkdir -p '..HOME)
            self.path = HOME..'/'..self.cacheurl
            os.setuid('mv '..path..' '..self.path..ext)
            os.setuid('rm -f '..self.path)
            callback('Extracting...')
            local cmd
            if map[ext] then
                cmd = map[ext]..' '..self.path..ext
            else
                cmd = 'cp '..self.path..ext..' '..self.path
            end
            local result = ''
            -- TODO make the package cache
            -- a Lua script (so that it opens
            -- faster)
            Cmd(cmd, function(line, status)
                if line == ffi.NULL then
                    if status == 0 then
                        os.setuid('rm -f '..self.path..ext)
                        import_lua_table(self, callback, ext)
                    else
                        C.alert_display('Could not extract Packages'..ext, result, 'Dismiss', nil, nil)
                        callback('Something went wrong :(')
                    end
                else
                    result = result..ffi.string(line)
                end
            end)
        end
    end
    dl:start()
end

function Repo:geticon(callback)
    local dl = ns.http:new()
    dl.url = (self.releaseurl or self.url)..'CydiaIcon.png'
    function dl.handler(dl, data, percent, errcode)
        if data then
            self.icon = objc.UIImage:alloc():initWithData(data)
            callback()
        end
    end
    dl:start()
end


local function populate(repolist)
    local t = {}
    for line in (repolist.."\n"):gmatch"(.-)\n" do
        repeat -- remove comments
            local match = string.match(line, '(.*)#.*')
            line = match or line
        until not match

        local url = string.match(line, 'deb%s+(.*/)%s+%.%/')
        if url then
            t[#t + 1] = Repo:new(url)
        end
    end
    return t
end

function Repo.List(url, oncomplete)
    local dl = ns.http:new()
    dl.url = 'https://raw.githubusercontent.com/jonluca/MasterRepo/master/masterrepoeasyinstall/etc/apt/sources.list.d/MasterRepo.list'
    function dl.handler(dl, data, percent, errcode)
        if data then
            local str = objc.NSString:alloc():initWithData_encoding(data, NSUTF8StringEncoding)
            oncomplete(populate(objc.tolua(str)))
        elseif errcode then
            dl:start()
        end
    end
    dl:start()

end

return Repo
