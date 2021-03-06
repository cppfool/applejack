--[[
	~ Shared Team Library ~
	~ Applejack ~
--]]
GM.Teams = {};
GM.Gangs = {};
GM.Groups = {};
GROUP_BASE = 1;			-- Base team member, all other teams in this group brach off it. There can only be one.
GROUP_MERCHANT = 2;		-- Sells stuff. At the moment, this is identical to TWIG.
GROUP_TWIG = 2;			-- A twig below the team base. Not a gang member but at the same level
GROUP_GANGMEMBER = 2;	-- A base member of a gang
GROUP_GANGBOSS = 3;		-- The boss of a gang, able to demote his subordinates.
do
local newgroup, newgang, newteam;
local reggroup, reggang, regteam;
local loadteams, loadteamsplugin;
local GROUPCOUNT, GANGCOUNT, TEAMCOUNT
-- Loads all the teams, gangs and groups. If you are not sh_init.lua during the initial startup phase, do not call this.
function GM:LoadTeams()
	local path = self.LuaFolder.."/gamemode/teams/";
	MsgN("Applejack: Loading Teams.");
	GROUPCOUNT = 0;
	GANGCOUNT = 0;
	TEAMCOUNT = 0;
	local cpath;
	local files, folders = file.Find(path.."*", "LUA")
	for _, group in ipairs(folders) do
		cpath = path .. group .. "/"
		if (not (validfile(group) and not group:find('.',1,true) and
			file.Exists(cpath .. "init.lua", "LUA"))) then
			continue;
		end
		newgroup();
		includecs(cpath .. "init.lua");
		if (not GROUP.Valid) then
			GROUP = nil;
			MsgN(" Canceled the load of group ", group, ".");
			continue;
		end
		MsgN(" Loaded group ", GROUP.Name, ".");
		GROUP.UniqueID = string.lower(group);
		reggroup();
		files, folders = file.Find(cpath .. "*", "LUA")
		for _, gang in ipairs(folders) do
			local cpath = cpath .. gang .. "/";
			if (not (validfile(gang) and not gang:find('.',1,true) and
			   file.Exists(cpath .. "init.lua", "LUA"))) then
				continue;
			end
			newgang();
			includecs(cpath .. "init.lua");
			if (not GANG.Valid) then
				GANG = nil;
				MsgN("  Canceled the load of gang ", gang, ".")
				continue;
			end
			MsgN("  Loaded gang ", GANG.Name, ".");
			GANG.UniqueID = string.lower(gang);
			reggang();
			loadteams(cpath);
			GANG = nil;
		end
		loadteams(cpath);
		GROUP = nil;
	end
	MsgN("Applejack: Loading teams from plugins:");
	local plugins = {};
	for _, plugin in pairs(GM.Plugins) do
		if (plugin._HasTeams) then
			table.insert(plugins, plugin);
		end
	end
	table.sort(plugins, function(a, b)
		return a.Folder < b.Folder
	end);

	local gdata, init, path;
	for _, plugin in ipairs(plugins) do
		path = plugin.FullPath .. "/teams/";
		MsgN(" Looking in ", plugin.Name);
		files, folders = file.Find(path .. "*", "LUA");
		for _, group in ipairs(folders) do
			cpath = path .. group .. "/";
			if (not validfile(group) or group:find('.', 1, true)) then
				continue;
			end
			gdata = "GROUP_" .. string.upper(group);
			gdata = _G[gdata];
			if (gdata) then
				GROUP = self.Groups[gdata] or Error("oh god what? group:", group, " gdata:", gdata, " res:", tostring(self.Groups[gdata]));
			end
			init = file.Exists(cpath .. "init.lua", "LUA");
			if (init) then
				if (not gdata) then
					newgroup();
				end
				-- Load any modifications.
				includecs(cpath .. "init.lua");
				if (not GROUP.Valid) then
					GROUP = nil;
					MsgN("  Canceled the load of group ", group, ".");
					continue;
				end
				if (not gdata) then
					MsgN("  Loaded group ", GROUP.Name, ".");
					GROUP.UniqueID = string.lower(group);
					reggroup();
				else
					MsgN("  Modified group ", GROUP.Name, ".");
				end
			elseif (not gdata) then
				ErrorNoHalt("  Warning! Unknown group ", group, " with no init.lua!\n");
				continue;
			else
				MsgN("  Loaded group ", GROUP.Name, ".");
			end
			local files, folders = file.Find(cpath .. "*", "LUA");
			for _, gang in ipairs(folders) do
				local cpath = cpath .. gang .. "/";
				if (not validfile(gang) or gang:find('.',1,true)) then
					continue;
				end
				gdata = "GANG_" .. string.upper(gang);
				gdata = _G[gdata];
				if (gdata) then
					GANG = self.Gangs[gdata] or Error("oh god what? gang:", gang, " gdata:", gdata, " res:", tostring(self.Gangs[gdata]));
				end
				init = file.Exists(cpath .. "init.lua", "LUA");
				if (init) then
					if (not gdata) then
						newgang();
					end
					-- Load any modifications.
					includecs(cpath .. "init.lua");
					if (not GANG.Valid) then
						GANG = nil;
						MsgN("   Canceled the load of gang ", gang, ".")
						continue;
					end
					if (not gdata) then
						MsgN("   Loaded gang ", GANG.Name, ".");
						GANG.UniqueID = string.lower(gang);
						reggang();
					else
						MsgN("   Modified gang ", GANG.Name, ".");
					end
				elseif (not gdata) then
					ErrorNoHalt("   Warning! Unknown gang ", gang, " with no init.lua!\n");
					continue;
				else
					MsgN("   Loaded gang ", GANG.Name, ".");
				end
				loadteamsplugin(cpath);
				GANG = nil;
			end
			loadteamsplugin(cpath);
			GROUP = nil;
		end
	end
	MsgN("Applejack: Loaded ", GROUPCOUNT, " groups, ", GANGCOUNT, " gangs and ", TEAMCOUNT, " teams.\n");
	GROUPCOUNT, GANGCOUNT, TEAMCOUNT = nil;
end

local groupid = 0;
function reggroup()
	groupid = groupid + 1;
	GROUP.GroupID = groupid;
	GROUP.Teams = {};
	GROUP.Gangs = {};
	GM.Groups[groupid] = GROUP;
	_G['GROUP_' .. GROUP.UniqueID:upper()] = groupid;
	GROUPCOUNT = GROUPCOUNT + 1;
end
local gangid = 0;
function reggang()
	gangid = gangid + 1;
	GANG.GangID = gangid;
	GANG.Group = GROUP;
	table.insert(GROUP.Gangs, GANG);
	GANG.Teams = {};
	GM.Gangs[gangid] = GANG;
	_G['GANG_' .. GANG.UniqueID:upper()] = gangid;
	GANGCOUNT = GANGCOUNT + 1;
end
local teamid = 0;
function regteam()
	teamid = teamid + 1;
	TEAM.TeamID = teamid;
	TEAM.Group = GROUP;
	TEAM.Gang = GANG;
	table.insert(GROUP.Teams, TEAM);
	if (TEAM.GroupLevel == GROUP_BASE) then
		GROUP.BaseTeam = TEAM;
	end
	if (GANG) then
		table.insert(GANG.Teams, TEAM);
	end
	if (TEAM.Default) then
		TEAM_DEFAULT = teamid;
	end
	GM.Teams[teamid] = TEAM;
	_G['TEAM_' .. TEAM.UniqueID:upper()] = teamid;
	team.SetUp(teamid, TEAM.Name, TEAM.Color);
	TEAMCOUNT = TEAMCOUNT + 1;
end
local a, b = "(.*)%.lua", "%1"
function loadteams(path)
	local str = "";
	for _, filename in pairs(file.Find(path.."*.lua", "LUA")) do
		if (validfile(filename) and filename ~= "init.lua") then
			newteam();
			includecs(path..filename);
			if (TEAM.Valid) then
				TEAM.UniqueID = string.lower(filename:gsub(a, b));
				str = str .. TEAM.Name .. ", ";
				regteam();
			else
				MsgN("Canceled team ", filename, ".");
			end
			TEAM = nil;
		end
	end
	MsgN((GANG and " " or ""), "  Loaded teams: ", str:sub(1,-3), ".");
end
function loadteamsplugin(path)
	local new     = "";
	local changed = "";
	local tuid, tdata;
	for _, filename in pairs(file.Find(path.."*.lua", "LUA")) do
		if (not validfile(filename) or filename == "init.lua") then
			continue;
		end
		tuid = filename:gsub(a, b);
		tdata = _G["TEAM_" .. string.upper(tuid)];
		if (tdata) then
			TEAM = GM.Teams[tdata] or Error(">:/ fn:", filename, " tu:", tuid, " tdata:", tdata, " r:", tostring(GM.Teams[tdata]));
		else
			newteam();
		end
		includecs(path .. filename);
		if (not TEAM.Valid) then
			TEAM = nil;
			MsgN("Canceled team ", filename, ".");
			continue;
		elseif (not tdata) then
			TEAM.UniqueID = tuid;
			new = new .. TEAM.Name .. ", ";
			regteam();
		else
			changed = changed .. TEAM.Name .. ", ";
		end
		TEAM = nil;
	end
	if (new ~= "") then
		MsgN((GANG and " " or ""), "  Created teams: ", new:sub(1, -3), ".");
	end
	if (changed ~= "") then
		MsgN((GANG and " " or ""), "  Modified teams: ", changed:sub(1, -3), ".");
	end
end

function newteam()
	TEAM = {}
	TEAM.Name = "Example Team";
	TEAM.Description = "This team is an example to demonstrate the new team system";
	TEAM.Color = color_white; -- This team shows up as white in the scoreboard / ooc
	TEAM.Salary = 200; -- Players get $200 every payday when in this team.
	TEAM.Models = {
		Male = GM.Config["Male Citizen Models"]; -- This job uses the default male citzien models
		Female = GM.Config["Female Citizen Models"]; -- This job uses the default female citizen models
	};
	TEAM.StartingEquipment = {
		Ammo = {}; -- This team has no ammo granted (Syntax [type] = amount, eg ["smg1"] = 200,)
		Weapons = {}; -- This team has no special weapons granted.
	}
	TEAM.PossessiveString = "The %ss"; -- A format string for this team possessing things.
	TEAM.CanMake = {}; -- Members of this team can't make anything special
	TEAM.CantUse = {}; -- There are no categories that members of this team cannot use
	TEAM.GroupLevel = GROUP_TWIG; -- This team is a twig of a group (Other options include GROUP_MERCHANT, GROUP_BASE, GROUP_GANGMEMBER and GROUP_GANGBOSS)
	TEAM.SizeLimit = 0; -- Any number of players can join this team.
	TEAM.TimeLimit = 0; -- Players can stay on this job as long as they want
	TEAM.Cooldown = 300; -- Players have to wait 5 minutes (300 seconds) befrore rejoining this team
	TEAM.Access = GM.Config['Base Access']; -- You only need the default access to join this team.
	TEAM.Whitelist = false; -- This team does not require a whitelist to join
	TEAM.Blacklist = true; -- Players can be blacklisted from this team
	TEAM.Valid = true; -- This is a valid team
	TEAM.Default = false; -- This is not the default starting team
	TEAM.Invisible = false; -- This team is not hidden from the client's dermas
	TEAM.IsTeam = true;
	TEAM.Type = "Team";
	TEAM.SortWeight = 0;
end
function newgang()
	GANG = {}
	GANG.Name = "Example Gang";
	GANG.Description = "An example gang to demonstrate the new team system";
	GANG.CanMake = {} -- Members of this gang can't make anything in particular
	GANG.CantUse = {} -- There's notthing special for these guys not to make
	GANG.StartingEquipment = {
		Ammo = {}; -- This gang has no ammo granted (Syntax {type,amount}; eg {"smg1", 200})
		Weapons = {}; -- This gang has no special weapons granted.
	}
	GANG.Whitelist = false; -- This gang does not require a whitelist to join
	GANG.Blacklist = true; -- Players can be blacklisted from this gang
	GANG.Valid = true; -- This is a valid gang
	GANG.Model = "error.mdl"; -- The model this gang will be represented by on the client
	GANG.Invisible = false -- This gang is not hidden from the client's dermas
	GANG.IsGang = true;
	GANG.Type = "Gang";
	GANG.SortWeight = 0;
end
function newgroup()
	GROUP = {}
	GROUP.Name = "Example Group"
	GROUP.Description = "An example group to demonstrate the new team system."
	GROUP.CanMake = {CATEGORY_CONTRABAND}; -- Members of this group can make cars and contraband
	GROUP.CantUse = {} -- There's nothing special for members of this group not to use
	GROUP.StartingEquipment = {
		Ammo = {}; -- This group has no ammo granted (Syntax {type,amount}; eg {"smg1", 200})
		Weapons = {}; -- This group has no special weapons granted.
	}
	GROUP.Whitelist = false; -- This group does not require a whitelist to join
	GROUP.Blacklist = true; -- Players can be blacklisted from this group
	GROUP.Model = "error.mdl"; -- The model this group will be represented by on the client
	GROUP.Valid = true; -- This is a valid group
	GROUP.Invisible = false; -- This group is not hidden from the client's dermas
	GROUP.IsGroup = true;
	GROUP.Type = "Group";
	GROUP.SortWeight = 0;
end
end
do
local function genericget(id, tab)
	local nid = tonumber(id)
	if (nid) then
		return tab[nid];
	elseif (type(id) == "table") then
		return id;
	end
	local ret,len,lon;
	id = string.lower(id);
	for _,data in pairs(tab) do
		if (data.UniqueID == id) then
			return data;
		elseif (data.Name:lower():find(id)) then
			lon = data.Name:len()
			if (not ret or lon < len) then
				ret = data;
				len = lon;
			end
		end
	end
	return ret;
end
---
-- Gets a group by it's ID
-- @param id The ID
-- @return The group in question
function GM:GetGroup(id)
	return genericget(id, self.Groups);
end

---
-- Gets a gang by it's ID
-- @param id The ID
-- @return The gang in question
function GM:GetGang(id)
	return genericget(id, self.Gangs);
end

---
-- Gets a team by it's ID
-- @param id The ID
-- @return The team in question
function team.Get(id)
	return genericget(id, GM.Teams);
end

---
-- Gets a team by it's ID
-- @param id The ID
-- @return The team in question
function GM:GetTeam(id)
	return genericget(id, GM.Teams);
end
end

---
-- Queries a group table
-- @param id The ID of the table
-- @param key The key to ask for
-- @param default The default value to return if the key is missing.
-- @return The value from the table, or the default value.
function GM:QueryGroup(id, key, default)
	local group = self:GetGroup(id);
	if (not group or group[key] == nil) then
		return default;
	end
	return group[key];
end

---
-- Queries a gang table
-- @param id The ID of the table
-- @param key The key to ask for
-- @param default The default value to return if the key is missing.
-- @return The value from the table, or the default value.
function GM:QueryGang(id, key, default)
	local gang = self:GetGang(id);
	if (not gang) then return nil; end
	if (gang[key] == nil) then
		return default;
	end
	return gang[key];
end

local function getplayersinteams(teams)
	local res = {};
	for _, data in pairs(teams) do
		table.Add(res, team.GetPlayers(data.TeamID));
	end
	return res;
end

---
-- Gets all the players in a particular gang
-- @param id The ID of the gang in question
-- @return A table of players
function GM:GetGangMembers(id)
	local gang = self:GetGang(id);
	if (not gang) then error("Invalid gang ID passed!", 2); end
	return getplayersinteams(gang.Teams);
end

---
-- Gets all the players in a particular group
-- @param id The ID of the group in question
-- @return A table of players
function GM:GetGroupMembers(id)
	local group = self:GetGroup(id);
	if (not group) then error("Invalid group ID passed!", 2); end
	return getplayersinteams(group.Teams);
end

---
-- Queries a team table
-- @param id The ID of the table
-- @param key The key to ask for
-- @param default The default value to return if the key is missing.
-- @return The value from the table, or the default value.
function team.Query(id, key, default)
	local data = team.Get(id)
	if (not data or data[key] == nil) then
		return default;
	end
	return data[key];
end
