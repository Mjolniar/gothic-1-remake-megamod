// MegaMod - crime switch (port of crime.lua of G1R_Repopulate).
// This is an unofficial modification. It is not made, endorsed or supported by THQ Nordic.
//
// Every crime starts by looking up a rule for its tag (UCrimeProcessingSubsystem.GetCrimeDefinition, SOURCE
// AI/AssessmentResponseSystem/CrimeProcessingSubsystem/CrimeProcessingSubsystem.as; the human and orc subsystems derive
// from it). For a kind that is switched off the lookup hands out an existing stand-in rule that looks for victims
// where the game supplies none for that crime, so the crime is thrown away as "no victim" before it is written down
// (the same stand-ins as crime.lua: the rule of a failed pickpocket for crimes reported without a person, the rule of
// theft for crimes reported without an object). Hitting and killing, defeats and story fights are never touched.
// Not ported: forgetting crimes already committed; owners who only hear a chest or door being used.

namespace MegaCrime
{
	const int NONE = 0;
	const int THEFT = 1;
	const int TRESPASSING = 2;
	const int WEAPONS = 3;

	// the stand-in a crime kind gets: true = the rule of a failed pickpocket, false = the rule of theft
	bool PersonRule(FGameplayTag Crime)
	{
		return Crime.MatchesTag(GameplayTag::Crime_Theft) || Crime.MatchesTag(GameplayTag::Crime_Lockpicking)
			|| Crime.MatchesTag(GameplayTag::Crime_Interaction) || Crime.MatchesTag(GameplayTag::Crime_Trespassing_OnGuild)
			|| Crime.MatchesTag(GameplayTag::Crime_Trespassing_OnPerson);
	}

	int Group(FGameplayTag Crime)
	{
		if (Crime.MatchesTag(GameplayTag::Crime_Theft) || Crime.MatchesTag(GameplayTag::Crime_Pickpocket_Fail)
			|| Crime.MatchesTag(GameplayTag::Crime_Pickpocket_Success) || Crime.MatchesTag(GameplayTag::Crime_Lockpicking)
			|| Crime.MatchesTag(GameplayTag::Crime_IgnoredWarning_Lockpicking) || Crime.MatchesTag(GameplayTag::Crime_Interaction)
			|| Crime.MatchesTag(GameplayTag::Crime_IgnoredWarning_Interaction))
			return THEFT;
		if (Crime.MatchesTag(GameplayTag::Crime_Trespassing_OnGuild) || Crime.MatchesTag(GameplayTag::Crime_Trespassing_OnPerson)
			|| Crime.MatchesTag(GameplayTag::Crime_IgnoredWarning_Trespassing) || Crime.MatchesTag(GameplayTag::Crime_Creeping))
			return TRESPASSING;
		if (Crime.MatchesTag(GameplayTag::Crime_ThreateningWeaponDrawn) || Crime.MatchesTag(GameplayTag::Crime_FistsDrawn)
			|| Crime.MatchesTag(GameplayTag::Crime_ThreateningWeaponTooClose) || Crime.MatchesTag(GameplayTag::Crime_FistsTooClose)
			|| Crime.MatchesTag(GameplayTag::Crime_DirectThreat_Weapon) || Crime.MatchesTag(GameplayTag::Crime_DirectThreat_Fists)
			|| Crime.MatchesTag(GameplayTag::Crime_IgnoredWarning_WeaponDrawn) || Crime.MatchesTag(GameplayTag::Crime_IgnoredWarning_FistsDrawn)
			|| Crime.MatchesTag(GameplayTag::Crime_IgnoredWarning_DirectThreat_Weapon)
			|| Crime.MatchesTag(GameplayTag::Crime_IgnoredWarning_DirectThreat_Fists) || Crime.MatchesTag(GameplayTag::Crime_BlockingPath))
			return WEAPONS;
		return NONE;
	}

	bool Ignored(FGameplayTag Crime)
	{
		const UMegaSettings_Repopulate S = UMegaSettings_Repopulate.DefaultObject;
		if (Mega::On(S.CrimeAsGame))
			return false;
		int G = Group(Crime);
		if (G == THEFT)
			return Mega::On(S.IgnoreTheft);
		if (G == TRESPASSING)
			return Mega::On(S.IgnoreTrespassing);
		if (G == WEAPONS)
			return Mega::On(S.IgnoreWeapons);
		return false;
	}
}

UCLASS(meta=(ReplaceParentClass))
class UCrimeProcessingSubsystem_MegaMod : UCrimeProcessingSubsystem
{
	const UCrimeDefinition GetCrimeDefinition(FGameplayTag Crime) const override
	{
		if (!MegaCrime::Ignored(Crime))
			return Super::GetCrimeDefinition(Crime);
		if (MegaCrime::PersonRule(Crime))
			return Cast<UCrimeDefinition>(UCrimeDefinition_Pickpocket_Fail::StaticClass().GetDefaultObject());
		return Cast<UCrimeDefinition>(UCrimeDefinition_Theft::StaticClass().GetDefaultObject());
	}
}
