TEAM.Name             = "Police Commander";
TEAM.Description      = "Runs the police force.";
TEAM.Color            = Color(50,155,255);
TEAM.GroupLevel       = GROUP_GANGBOSS;
TEAM.Models.Male      = {"models/player/urban.mdl"};
TEAM.Models.Female    = TEAM.Models.Male;
TEAM.SizeLimit        = 1;
TEAM.Salary           = 300;
TEAM.PossessiveString = "The %s";
TEAM.StartingEquipment.Weapons = {
	"cider_baton",
	"cider_glock18",
}
GANG.StartingEquipment.Ammo["smg1"] = 120;
