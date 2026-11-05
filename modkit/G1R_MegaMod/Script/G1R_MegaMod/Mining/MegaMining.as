// MegaMod - mining (port of the UE4SS module mining).
// This is an unofficial modification. It is not made, endorsed or supported by THQ Nordic.
//
// The game takes the ore of a swing from the mining config of its world definition (UMiningConfig: 3 ore a swing,
// 1 when 5 or fewer are left). Once a second the module works out the amount from the settings and the hero's
// Strength, Dexterity and mining skill and writes it there; switched off, the game's own numbers go back.
// Not ported yet: the chance of one more ore, veins that never run out, veins that last longer (they need the vein
// of each swing).

class UMegaMining : UGothicModExt_WorldSubsystem
{
	const float LOOK_SECONDS = 1.0f;

	bool HaveOriginal = false;
	int OrigHighOre = 5;
	int OrigAtHigh = 3;
	int OrigAtLow = 1;
	int LastAmount = -1;
	FTimerHandle Timer;

	UMiningSpotConfig Config()
	{
		return Cast<UMiningSpotConfig>(UMiningConfig::StaticClass().GetDefaultObject());
	}

	UFUNCTION(BlueprintOverride)
	void HandleReadyForPlay()
	{
		Timer = System::SetTimer(this, n"Look", LOOK_SECONDS, true);
		Look();
	}

	UFUNCTION()
	void Look()
	{
		const UMegaSettings_Mining S = UMegaSettings_Mining.DefaultObject;
		UMiningSpotConfig C = Config();
		if (!IsValid(C))
			return;
		if (!HaveOriginal)
		{
			OrigHighOre = C.m_HighOre;
			OrigAtHigh = C.m_AmountAtHighOre;
			OrigAtLow = C.m_AmountAtLowOre;
			HaveOriginal = true;
			Mega::Say("mining", f"the game's numbers: {OrigAtHigh} a swing, {OrigAtLow} at {OrigHighOre} or fewer left");
		}
		AGothicPlayerState Hero = Mega::Player();
		if (!Mega::On(S.Enabled) || !Mega::On(S.YieldEnabled) || !IsValid(Hero))
		{
			C.m_HighOre = OrigHighOre;
			C.m_AmountAtHighOre = OrigAtHigh;
			C.m_AmountAtLowOre = OrigAtLow;
			LastAmount = -1;
			return;
		}

		int Amount = Mega::Int(S.BaseAmount);
		float PerStrength = Mega::Num(S.StrengthPerOre);
		float PerDexterity = Mega::Num(S.DexterityPerOre);
		if (PerStrength > 0.0f)
			Amount += Math::FloorToInt(Hero.GetStrengthAttribute() / PerStrength);
		if (PerDexterity > 0.0f)
			Amount += Math::FloorToInt(Hero.GetDexterityAttribute() / PerDexterity);
		if (Hero.HasGameplayTag(GameplayTag::Skill_Mining_Master))
			Amount += Mega::Int(S.MasterBonus);
		else if (Hero.HasGameplayTag(GameplayTag::Skill_Mining_Trained))
			Amount += Mega::Int(S.TrainedBonus);
		Amount = Math::Clamp(Amount, Mega::Int(S.MinAmount), Math::Max(Mega::Int(S.MinAmount), Mega::Int(S.MaxAmount)));

		C.m_AmountAtHighOre = Amount;
		if (Mega::On(S.LowVeinRule))
		{
			C.m_HighOre = OrigHighOre;
			C.m_AmountAtLowOre = OrigAtLow;
		}
		else
		{
			C.m_HighOre = 0;
			C.m_AmountAtLowOre = Amount;
		}
		if (Amount != LastAmount)
		{
			if (Mega::On(S.LogSwings))
				Mega::Say("mining", f"a swing gives {Amount} ore now");
			if (Mega::On(S.ShowMessage) && LastAmount >= 0)
				Mega::Note("mining", f"Mining: {Amount} ore a swing");
			LastAmount = Amount;
		}
	}
}
