// MegaMod - settings of the repopulate part (the UE4SS mod G1R_Repopulate had a config.lua of its own, no schema).
// This is an unofficial modification. It is not made, endorsed or supported by THQ Nordic.

UCLASS(Config=GameUserSettings)
class UMegaSettings_Repopulate : UGothicModExt_UserSettings
{
	default CategoryName = FText::FromString("MegaMod: World and crime");

	// ---- Herbs and items in the world (read when the game starts) ----

	// hours until a picked herb, plant or mushroom grows again; 0 = as the game has it (168 for most, some never)
	UPROPERTY(Config)
	FModUserSettingsInt HerbHours = FModUserSettingsInt(
		Value = 24,
		DefaultValue = 24,
		DisplayText = FText::FromString("Herbs grow again after (hours; 0 = the game's; after a restart)"),
		MinValue = 0,
		MaxValue = 720);

	// hours until another item lying in the world comes back; 0 = never, as the game has it
	UPROPERTY(Config)
	FModUserSettingsInt ItemHours = FModUserSettingsInt(
		Value = 160,
		DefaultValue = 160,
		DisplayText = FText::FromString("Items in the world come back after (hours; 0 = never; after a restart)"),
		MinValue = 0,
		MaxValue = 2000);

	// ---- Crime ----

	UPROPERTY(Config)
	FModUserSettingsBool CrimeAsGame = FModUserSettingsBool(
		Value = true,
		DefaultValue = true,
		DisplayText = FText::FromString("Crime as the game has it (off: the kinds below are ignored)"));

	UPROPERTY(Config)
	FModUserSettingsBool IgnoreTheft = FModUserSettingsBool(
		Value = true,
		DefaultValue = true,
		DisplayText = FText::FromString("Ignore theft, pickpocketing, lock picking, using others' things"));

	UPROPERTY(Config)
	FModUserSettingsBool IgnoreTrespassing = FModUserSettingsBool(
		Value = true,
		DefaultValue = true,
		DisplayText = FText::FromString("Ignore trespassing and sneaking"));

	UPROPERTY(Config)
	FModUserSettingsBool IgnoreWeapons = FModUserSettingsBool(
		Value = true,
		DefaultValue = true,
		DisplayText = FText::FromString("Ignore drawn weapons, threats, blocking the way"));
}
