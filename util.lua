ffi.cdef[[
void dpkg_syslog(const char *);
]]
function print(str, ...)
    if ... then
        local args = {str, ...}
        local t = {}
        for i=1,#args do
            t[i] = tostring(args[i])
        end
        C.dpkg_syslog(table.concat(t, ', '))
    else
        C.dpkg_syslog(tostring(str))
    end
end

ffi.cdef[[
typedef void DIR;
DIR *opendir(const char *);
int closedir(DIR *dirp);
]]

if ffi.arch == 'arm64' then
    ffi.cdef[[
    struct dirent{
        uint64_t d_ino;
        uint64_t d_seekoff;
        uint16_t d_reclen;
        uint16_t d_namlen;
        uint8_t d_type;
        char d_name[1024];
    };
    struct dirent *readdir(DIR *);
    ]]
    function ls(directory)
        dir = C.opendir(directory)
        if dir == ffi.NULL then return end
        local i = 0
        local t = {}
        local ent = C.readdir(dir)
        while not(ent == ffi.NULL) do
            local name = ffi.string(ent.d_name)
            if not(name == '.' or name == '..') then
                i = i + 1
                t[i] = ffi.string(ent.d_name)
            end
            ent = C.readdir(dir)
        end
        C.closedir(dir)
        return t
    end
else
    -- this is a hack. doesnt work on a lot of iOS versions.
    -- i need to port that cdef above to 32bit
    function ls(directory)
        local i = 0
        local t = {}
        local f = io.popen('ls '..directory)
        for filename in f:lines() do
            i = i + 1
            t[i] = filename
        end
        f:close()
        return t
    end
end

function isdir(path)
    local dir = C.opendir(path)
    if dir == ffi.NULL then
        return false
    else
        C.closedir(dir)
        return true
    end
end
function os.capture(cmd, noerr)
    local f
    if noerr then
        f = assert(io.open(cmd, 'r'))
    else
        f = assert(io.popen(cmd..' 2>&1', 'r'))
    end
    local s = assert(f:read('*a'))
    local rc = {f:close()}
    return string.sub(s, 1, #s - 1), rc[3]
end

function os.setuid(cmd)
    local f = io.popen(APP_PATH..'/setuid /usr/bin/env '..cmd..' 2>&1', 'r')
    local s = f:read('*a')
    local rc = {f:close()}
    return s, rc[3]
end


local fs = {}
fs.WIDTH = function()
    return objc.UIScreen:mainScreen():bounds().size.width
end
fs.HEIGHT = function()
    return objc.UIScreen:mainScreen():bounds().size.height
end

_G.SCREEN = setmetatable({}, {
    __index = function(t, k)
        local f = fs[k]
        if f then return f() end
    end,
})
