local function PUSHCONTROLLER(f, title)
    REPOCONTROLLER:pushViewController_animated(VIEWCONTROLLER(f, title), true)
end

_G.REPOCONTROLLER = objc.UINavigationController:alloc():initWithRootViewController(VIEWCONTROLLER(function(m)
    m:view():setBackgroundColor(objc.UIColor:whiteColor())
    local tbl = ui.filtertable:new()


    tbl.items = {{'Loading...'}}
    tbl.cell = ui.cell:new()
    tbl:refresh()
    tbl.m:setFrame(m:view():bounds())
    m:view():addSubview(tbl.m)

    Repo.List(function(repos)
        for _,url in ipairs(REPOS or {}) do
            local repo = Repo:new(url)
            repo.can_delete = true
            table.insert(repos, 1, repo)
        end
        function tbl:search(text, item)
            local function find(s)
                if s then
                    local success, result = pcall(string.find, string.lower(s), string.lower(text))
                    return not success or result
                end
                return s and string.find(string.lower(s), string.lower(text))
            end
            return find(item.Origin) or find(item.Title) or find(item.prettyurl)
        end

        function tbl:caneditcell(section, row)
            local repo = self:list()[row]
            return repo.can_delete
        end

        function tbl:editcell(section, row, style)
            if not(style == UITableViewCellEditingStyleDelete) then return end

            local repo = self:list()[row]
            local list = self:list()

            if not(list == self.deblist) then
                for i=1,#self.deblist do
                    if self.deblist[i] == repo then
                        table.remove(self.deblist, i)
                        break
                    end
                end
            end
            for i=1,#REPOS do
                if REPOS[i] == repo then
                    table.remove(REPOS, i)
                    break
                end
            end
            local listi
            for i=1,#list do
                if list[i] == repo then
                    table.remove(list, i)
                    listi = i
                    break
                end
            end

            local rows = objc.toobj{objc.NSIndexPath:indexPathForRow_inSection(listi - 1, 0)}
            self.m:deleteRowsAtIndexPaths_withRowAnimation(rows, UITableViewRowAnimationFade)
        end

        for i, repo in ipairs(repos) do
            local function callback()
                for i,v in ipairs(tbl:list()) do
                    if v == repo then
                        local rows = objc.toobj{objc.NSIndexPath:indexPathForRow_inSection(i - 1, 0)}
                        tbl.m:reloadRowsAtIndexPaths_withRowAnimation(rows, UITableViewRowAnimationNone)
                        break
                    end
                end
            end
            repo:getrelease(callback)
            repo:geticon(callback)
        end
        --tbl.items = {repos}
        tbl.deblist = repos
        tbl.cell = ui.cell:new()
        function tbl.cell.onshow(_, m, section, row)
            local repo = tbl:list()[row]
            repo:rendercell(m)
        end
        function tbl.cell.onselect(_, section, row)
            local repo = tbl:list()[row]
            local tbl = ui.filtertable:new()
            tbl.items = {{'Loading...'}}
            tbl.cell = ui.cell:new()
            tbl:refresh()

            repo:getpackages(function(progressmsg)
                if progressmsg then
                    tbl.items[1][1] = progressmsg
                    local rows = objc.toobj{objc.NSIndexPath:indexPathForRow_inSection(0, 0)}
                    tbl.m:reloadRowsAtIndexPaths_withRowAnimation(rows, UITableViewRowAnimationNone)
                else
                    function tbl:search(text, item)
                        local function find(s)
                            if s then
                                local success, result = pcall(string.find, string.lower(s), string.lower(text))
                                return not success or result
                            end
                            return s and string.find(string.lower(s), string.lower(text))
                        end
                        return find(item.Name) or find(item.Package) or find(item.Description)
                    end
                    tbl.deblist = repo.debs
                    tbl.cell = ui.cell:new()
                    function tbl.cell.onshow(_, m, section, row)
                        local deb = tbl:list()[row]
                        m:textLabel():setText(deb.Name or deb.Package)
                        m:detailTextLabel():setText(deb.Description)

                        local img = nil
                        if deb.Section then
                            local path = '/Applications/Cydia.app/Sections/'..string.gsub(deb.Section, ' ', '_')..'.png'
                            local f = io.open(path, 'r')
                            if f then
                                f:close()
                            else
                                img = repo.icon
                                path = '/Applications/Cydia.app/unknown.png'
                            end
                            img = img or objc.UIImage:imageWithContentsOfFile(path)
                        end

                        m:imageView():setImage(img)
                    end
                    function tbl.cell.onselect(_, section, row)
                        local depiction = Depiction:new()
                        depiction.deb = tbl:list()[row]
                        PUSHCONTROLLER(function(m)
                            depiction:view(m)
                        end, depiction:gettitle())
                    end
                    tbl:refresh()
                end
            end)

            PUSHCONTROLLER(function(m)
                m:view():setBackgroundColor(objc.UIColor:whiteColor())
                tbl.m:setFrame(m:view():bounds())
                m:view():addSubview(tbl.m)
            end, repo.Origin or repo.Title or repo.prettyurl)
        end
        tbl:refresh()
    end)
end, 'Repos'))
local path = '/Applications/Cydia.app/install7@2x.png'
REPOCONTROLLER:tabBarItem():setImage(objc.UIImage:imageWithContentsOfFile(path))


table.insert(TABCONTROLLERS, REPOCONTROLLER)
