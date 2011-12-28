--[[
    ~ MSAccessList ~
    ~ Moonshine ~
--]]

-- Vars
local menu;

-- Util
local function verifyPos()
    if (not IsValid(menu)) then
        return false;
    end
    -- Ensure they're where they were when they opened the menu.
    if (lpl:GetPos() == menu.openPos) then
        return true;
    end
    -- They've moved. This probably breaks everything so give up
    menu:Close();
    menu:Remove();
    gui.EnableScreenClicker(false); 
    return false;
end

-- Button functions
local takeFunction;
local giveFunction;
do
    local function btn(what, how)
        local uid;
        if (what.IsPlayer) then
            if (IsValid(what)) then
                uid = what:UniqueID();
            end
        else
            uid = what.UniqueID;
        end
        if (uid) then
            RunConsoleCommand("mshine", "access", how, uid);
        end
    end
    local function giveAccess(what)
        btn(what, "give");
    end
    local function takeAccess(what)
        btn(what, "take");
    end
    local function itemfunction(panel, item)
        local name, desc, mdl
        if (item.IsPlayer) then
            name = item:GetName();
            desc = "TODO! Details - Clan";
            mdl  = item:GetModel();
        else
            name = item.Name;
            desc = item.Description;
            mdl  = item.Model;
        end
        panel:SetName(name);
        panel:SetDescription(desc);
        panel:SetPortrait(mdl);
    end
    function giveFunction(panel, item)
        itemfunction(panel, item);
        panel:AddButton("Give Access", giveAccess);
    end
    function takeFunction(panel, item)
        itemfunction(panel, item);
        panel:AddButton("Take Access", takeAccess);
    end
end

local function getList(panel)
    return panel._AccessList
end

local function formatPlayerList(list)
    local res = {};
    local trans = {};
    for _, group in pairs(GM.Groups) do
        local data = {
            SortWeight = group.SortWeight;
        };
        for _, team in pairs(group.Teams) do
            local arf = {
                SortWeight = team.SortWeight;
            };
            data[team.Name] = arf;
            trans[team.TeamID] = arf;
        end
        res[group.Name] = data;
    end

    for _, ply in pairs(list) do
        local data = trans[ply:Team()];
        if (not data) then
            continue;
        end
        table.insert(data, ply);
    end

    for name, gdata in pairs(res) do
        for name, tdata in pairs(gdata) do
            if (#tdata == 0) then
                gdata[name] = nil;
            end
        end
        if (#gdata == 0) then
            res[name] = nil;
        end
    end

    return res;
end

local function formatTeams(list)
    local res = {};
    local trans = {};
    
    for _, group in pairs(GM.Groups) do
        local gangs = {
            SortWeight = group.SortWeight;
        };
        for _, gang in (data.Gangs) do
            local teams = {
                SortWeight = gang.SortWeight;
            };
            for _, team in pairs(gang.Teams) do
                trans[team.TeamID] = teams;
            end
            gangs[gang.Name] = teams;
        end
        teams = {
            SortWeight = 10;
        }
        for _, team in pairs(group.Teams) do
            if (not trans[team.TeamID]) then
                trans[team.TeamID] = teams;
            end
        end
        gangs["Unaffiliated"] = teams;
        res[data.Name] = gangs;
    end

    for _, id in pairs(list) do
        local team = GM.Teams[id];
        if (not team) then
            continue;
        end
        local data = trans[team.TeamID];
        if (not data) then
            continue;
        end
        table.insert(data, team);
    end

    -- TODO: DELETE EXCESS TABLE THINGS
    -- TODO: SORT THE TEAMS WITHIN LISTS

    return res;
end

local function formatGangs(list)
    local groups = {};
    local gangs = {};
    for _, id in pairs(list) do
        if (id < 0) then
            groups[-id] = true;
        else
            gangs[id] = true;
        end
    end
    local res = {};
    for _, group in pairs(GM.Groups) do
        local data = {};
        for _, gang in pairs(group.Gangs) do
            if (gangs[gang.GangID]) then
                table.insert(data, gang);
            end
        end
        if (groups[group.GroupID]) then
            table.insert(data, group);
        end
        res[group.Name] = data;
    end
    return ret;
end

local function CreateMenu(data)
    if (IsValid(menu)) then
        menu:Close();
        menu:Remove();
        menu = nil;
    end
    -- TODO: CREATE MENU
end

local function UpdateMenu(data)
    if (not IsValid(menu)) then
        MsgN("Sent an access menu update with no access menu open!");
        return;
    end
    -- TODO: UPDATE MENU
end

if (net) then
    -- TODO: LOOK UP CORRECT SYNTAX
    net.Receive("MS Access List", CreateMenu);
    net.Receive("MS Access List update", UpdateMenu);
else
    datastream.Hook("MS Access List", function(_,_,_, data)
        CreateMenu(data);
    end);
    datastream.Hook("MS Access List update", function(_,_,_, data)
        UpdateMenu(data);
    end);
end