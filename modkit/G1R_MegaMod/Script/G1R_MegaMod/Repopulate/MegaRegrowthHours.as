// MegaMod - herbs regrow, items in the world come back (port of items.lua of G1R_Repopulate).
// This is an unofficial modification. It is not made, endorsed or supported by THQ Nordic.
//
// The game refills an item spawner after its refill time (SetRefill, hours; herbs mostly 168, other items never -
// SOURCE Map/MainMap/ItemSpawnManagerConfig_MainMap.as). MegaRegrowth.as (made by modkit/tools/gen_regrowth.py when
// the package is built) gives the herb and loose-item spawners again with the hours of the settings. The hours are
// read when the spawners' configuration is built, at the start of the game.

namespace MegaRegrowth
{
	int Herb(int GameHours)
	{
		const UMegaSettings_Repopulate S = UMegaSettings_Repopulate.DefaultObject;
		int Hours = Mega::Int(S.HerbHours);
		return Hours > 0 ? Hours : GameHours;
	}

	// 0: never, as the game has it
	int Loose()
	{
		const UMegaSettings_Repopulate S = UMegaSettings_Repopulate.DefaultObject;
		return Math::Max(0, Mega::Int(S.ItemHours));
	}
}
