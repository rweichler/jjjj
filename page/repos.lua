local function PUSHCONTROLLER(f, title)
    REPOCONTROLLER:pushViewController_animated(VIEWCONTROLLER(f, title), true)
end

local function update_repos()
    os.setuid('mkdir -p '..PATH..'/config')
    os.setuid('chown -R mobile '..PATH..'/config')
    local f = io.open(PATH..'/config/repos.lua', 'w')
    f:write('REPOS = {\n')
    for i=1,#REPOS do
        f:write('    "'..REPOS[i]..'",\n')
    end
    f:write('}\n')
    f:close()
end

_G.REPOCONTROLLER = objc.UINavigationController:alloc():initWithRootViewController(VIEWCONTROLLER(function(m)
    m:view():setBackgroundColor(objc.UIColor:whiteColor())
    local tbl = ui.filtertable:new()

    tbl.searchbar.m:setPlaceholder('Filter repos')

    tbl.items = {{'Loading...'}}
    tbl.cell = ui.cell:new()
    tbl:refresh()
    tbl.m:setFrame(m:view():bounds())
    m:view():addSubview(tbl.m)

    local function loadrepo(repo)
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

    Repo.List(function(repos)


        local target = ns.target:new()
        local button = objc.UIBarButtonItem:alloc():initWithTitle_style_target_action('Add repo', UIBarButtonItemStylePlain, target.m, target.sel)
        m:navigationItem():setRightBarButtonItem(button)

        function target.onaction()
            C.alert_input('Add repo', 'Please type the URL', 'Cancel', 'Add repo', function(text)
                local url = ffi.string(text)
                local repo = Repo:new(url)
                repo.can_delete = true
                table.insert(tbl.deblist, 1, repo)
                tbl:updatefilter()
                tbl:refresh(true)
                loadrepo(repo)
                REPOS[#REPOS + 1] = url
                update_repos()
            end)
        end

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
                if REPOS[i] == repo.orig_url then
                    table.remove(REPOS, i)
                    update_repos()
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
            loadrepo(repo)
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
            tbl.searchbar.m:setPlaceholder('Filter packages')
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
