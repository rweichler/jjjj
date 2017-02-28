local super = Object
ns.http = Object.new(super)

function ns.http:new(...)
    local self = super.new(self, ...)

    self.m = self.class:alloc():init()
    objc.Lua(self.m, self)

    return self
end

function ns.http:start()
    local url = objc.NSURL:URLWithString(self.url)
    local request = objc.NSMutableURLRequest:requestWithURL(url)
    request:setValue_forHTTPHeaderField('Cydia/0.9 CFNetwork/808.2.16 Darwin/16.3.0', 'User-Agent')
    request:setValue_forHTTPHeaderField('iPhone6,1', 'X-Machine')
    request:setValue_forHTTPHeaderField('a253b3a7b970ec38008f04b9cd63be9a2b941c45', 'X-Unique-ID')
    if self.getheaders then
        request:setHTTPMethod('HEAD')
    end
    local config = objc.NSURLSessionConfiguration:defaultSessionConfiguration()
    local queue = objc.NSOperationQueue:mainQueue()
    local urlSession = objc.NSURLSession:sessionWithConfiguration_delegate_delegateQueue(config, self.m, queue)

    if self.download then
        self.task = urlSession:downloadTaskWithRequest(request)
    else
        self.task = urlSession:dataTaskWithRequest(request)
    end
    self.task:resume()

    self.session = urlSession
end

function ns.http:parseheaders(headers)
    if headers['Last-Modified'] then
        local day, month, year, hour, min, sec = string.match(headers['Last-Modified'], '%w+, (%d+) (%a+) (%d+) (%d+):(%d+):(%d+) GMT')
        if day and month and year and hour and min and sec then
            local MON ={Jan=1,Feb=2,Mar=3,Apr=4,May=5,Jun=6,Jul=7,Aug=8,Sep=9,Oct=10,Nov=11,Dec=12}
            month = MON[month]
            local offset = os.time()-os.time(os.date("!*t"))
            local epoch = os.time({day=day,month=month,year=year,hour=hour,min=min,sec=sec})+offset
            headers['Last-Modified'] = epoch
        end
    end
    self.headers = headers
end

function ns.http:handler()
    --[[
    ARGS
    file download: url, percent, errcode
    data: data, percent, errcode
    ]]
end

ns.http.class = objc.GenerateClass()
local class = ns.http.class

-- data request

objc.addmethod(class, 'URLSession:dataTask:didReceiveData:', function(self, session, task, data)
    local this = objc.Lua(self)

    if not this.mdata then
        this.mdata = objc.NSMutableData:alloc():init()
    end
    this.mdata:appendData(data)
end, ffi.arch == 'arm64' and 'v40@0:8@16@24@32' or 'v20@0:4@8@12@16')

-- download request

objc.addmethod(class, 'URLSession:downloadTask:didFinishDownloadingToURL:', function(self, session, task, url)
    local this = objc.Lua(self)

    local status = tonumber(task:response():statusCode())

    this:parseheaders(objc.tolua(task:response():allHeaderFields()))

    if status >= 200 and status < 300 then
        local url = objc.tolua(url:description())
        url = string.sub(url, #'file://' + 1, #url)
        this:handler(url)
    else
        this:handler(objc.tolua(url), nil, status)
    end
end, ffi.arch == 'arm64' and 'v40@0:8@16@24@32' or 'v20@0:4@8@12@16')

objc.addmethod(class, 'URLSession:downloadTask:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:', function(self, session, task, data, bytesWritten, totalBytes)
    local this = objc.Lua(self)
    local percent = tonumber(bytesWritten)/tonumber(totalBytes)

    if not this.totalbytes then
        this.totalbytes = totalBytes
    end
    this:handler(nil, percent)
end, ffi.arch == 'arm64' and 'v56@0:8@16@24Q32Q40Q48' or 'v28@0:4@8@12Q16Q20Q24')

objc.addmethod(class, 'URLSession:task:didCompleteWithError:', function(self, session, task, err)
    local this = objc.Lua(self)

    if err and not(err == ffi.NULL) then
        local desc = err.description
        this:handler(nil, nil, objc.tolua(desc))
    elseif not this.download then
        local response = task:response()
        local status = response and tonumber(response:statusCode())
        if this.mdata then
            if status >= 200 and status < 300 then
                local data = this.mdata
                this.mdata = nil
                this:handler(data)
            else
                this:handler(nil, nil, status)
            end
        elseif status then
            this:parseheaders(objc.tolua(task:response():allHeaderFields()))
            this:handler(nil, nil, status)
        end
    end
end, ffi.arch == 'arm64' and 'v32@0:8@16@24' or 'v16@0:4@8@12')


--- download bar

Downloadbar = Object:new(view)
function Downloadbar:new(frame)
    local self = Object.new(self)

    frame = frame or objc.UIScreen:mainScreen():bounds()

    local view = objc.UIView:alloc():initWithFrame(frame)

    local progress = objc.UIProgressView:alloc():initWithProgressViewStyle(UIProgressViewStyleDefault)
    progress:setProgress(0)

    local padding = 44
    local y = frame.size.height/2
    progress:setFrame{{padding, y},{frame.size.width-padding*2, 22}}

    local downloadingLabel = objc.UILabel:alloc():initWithFrame{{padding, y + 11},{20,20}}
    downloadingLabel:setText('Downloading...')
    downloadingLabel:setFont(downloadingLabel:font():fontWithSize(10))
    downloadingLabel:sizeToFit()

    local percentLabel = objc.UILabel:alloc():initWithFrame{{0, y + 11},{20,20}}
    percentLabel:setText('000%')
    percentLabel:setFont(percentLabel:font():fontWithSize(10))
    percentLabel:sizeToFit()
    local x = progress:frame().origin.x + progress:frame().size.width - percentLabel:frame().size.width
    percentLabel:setFrame{{x, percentLabel:frame().origin.y},percentLabel:frame().size}
    percentLabel:setTextAlignment(NSTextAlignmentRight)
    percentLabel:setText('0%')

    self.m = view
    self.progress = progress
    self.percent = percentLabel
    self.downloading = downloadingLabel

    view:addSubview(self.downloading)
    view:addSubview(self.percent)
    view:addSubview(self.progress)

    return self
end

return ns.http
