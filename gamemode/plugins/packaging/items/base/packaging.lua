--[[
	~ Base packaging ~
	~ Applejack ~
--]]
ITEM:Derive("item");
ITEM.Capacity	= 20
ITEM.AutoClose	= true
ITEM.NoVehicles = true;
ITEM.Size		= 2;
ITEM.Batch      = 5;
local plugin = (GM or GAMEMODE):GetPlugin("packaging");
function ITEM:onUse(player)
	return plugin:CrateTime(player,self)
end
