--[[
	~ Spawnpoints Plugin ~
	~ Applejack ~
--]]

PLUGIN.Name = "Spawnpoints"
PLUGIN.Spawnpoints = {};
--[[
	TODO: Make it not spawn people if there's someone
	 in the way.
--]]

function PLUGIN:LoadData()
	local path, data, status, results;

	path = GM.LuaFolder.."/spawnpoints/"..game.GetMap()..".txt";
	if (not file.Exists(path, "DATA")) then
		return
	end
	data = file.Read(path, "DATA");
	status, results = pcall(util.JSONToTable,data);
	if (status == false) then
		error("Error JSON decoding '"..path.."': "..results);
	elseif (not results) then
		return
	end
	for name, spawns in pairs(results) do
		data = team.Get(name);
		if (data) then
			self.Spawnpoints[data.TeamID] = spawns;
		end
	end
end

function PLUGIN:SaveData()
	local data,tocode,status,result,path;
	tocode = {};
	for index, spawns in pairs(self.Spawnpoints) do
		data = team.Get(index);
		if (data) then
			tocode[data.Name] = spawns; --Indexes change, names tend not to.
		end
	end
	status, result = pcall(util.TableToJSON,tocode);
	if (status == false) then
		error("["..os.date().."] Spawnpoints Plugin: Error JSON encoding spawnpoints : "..results);
	end
	path = GM.LuaFolder.."/spawnpoints/"..game.GetMap()..".txt";
	if (not result or result == "") then
		if (file.Exists(path, "DATA")) then
			file.Delete(path, "DATA");
		end
		return;
	end
	file.CreateDir( "sample" );
	file.CreateDir(GM.LuaFolder .. "/spawnpoints/");
	file.Write(path,result);
end

function PLUGIN:PostPlayerSpawn(ply, light)
	local data,spawn;
	data = self.Spawnpoints[ply:Team()];
	if (data and table.Count(data) > 0) then
		spawn = table.Random(data);
		ply:SetPos(spawn.pos);
		ply:SetEyeAngles(spawn.ang);
	end
end

local plugin = PLUGIN;
local points = plugin.Spawnpoints;
-- A command to add a player spawn point.
GM:RegisterCommand{
	Command     = "spawnpoint";
	Access      = "a";
	Arguments   = "<Add|Remove> <Team>";
	Types       = "Phrase String";
	function(ply, action, name)
		local target,index,pos,count,left;
		target = team.Get(name);
		if (not target) then
			return false, "Could not locate team '"..name.."'!";
		end
		index = target.TeamID;
		if (action == "add") then
			points[index] = points[index] or {};
			table.insert(points[index],{pos = ply:GetPos(), ang = ply:GetAngles()});
			ply:Notify("You have added a spawnpoint for "..target.Name.." where you are standing.");
		else
			if (not points[index]) then
				return false, "'"..name.."' does not have any spawnpoints!";
			end
			pos = ply:GetEyeTraceNoCursor().HitPos;
			count = 0;
			for k,data in pairs(points[index]) do
				if ((pos - data.pos):LengthSqr() <= 65536) then
					points[index][k] = nil;
					count = count + 1;
				end
			end
			left = table.Count(points[index]);
			if (count > 0) then
				ply:Notify("You removed "..count.." "..target.Name.." spawnpoints from where you were looking, leaving "..left.." left.");
			else
				ply:Notify("There are no "..target.Name.." spawnpoints where you are looking!");
			end
			if (left == 0) then
				points[index] = nil;
			end
		end
		plugin:SaveData();
	end
};
