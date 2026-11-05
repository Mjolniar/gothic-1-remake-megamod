// MegaMod - experience multiplier (port of the UE4SS module xp).
// This is an unofficial modification. It is not made, endorsed or supported by THQ Nordic.
//
// Every gain of the hero's experience (the attribute LevelProgression.Experience: quests, kills, learning) is looked
// at four times a second; the part the multiplier adds is given with the game's own GiveExperience, so levels follow
// as the game handles them. Experience that the module itself gave is not counted again. After a game is loaded the
// first look only takes the value as it is (loading never changes experience).

class UMegaXp : UGothicModExt_WorldSubsystem
{
	// not settings: the largest single gain that is multiplied (larger = a load or a script setting the value),
	// how long after the world is ready the first value is only taken, how often to look
	const float MAX_GAIN = 50000.0f;
	const float SETTLE_SECONDS = 10.0f;
	const float LOOK_SECONDS = 0.25f;

	float Last = -1.0f;            // the experience at the last look (-1: not read yet)
	float Carry = 0.0f;            // the fraction not given yet (the game counts whole points)
	float ReadyAt = 0.0f;
	FTimerHandle Timer;

	UFUNCTION(BlueprintOverride)
	void HandleReadyForPlay()
	{
		Last = -1.0f;
		Carry = 0.0f;
		ReadyAt = World.TimeSeconds;
		Timer = System::SetTimer(this, n"Look", LOOK_SECONDS, true);
	}

	UFUNCTION()
	void Look()
	{
		const UMegaSettings_Xp S = UMegaSettings_Xp.DefaultObject;
		AGothicPlayerState Hero = Mega::Player();
		if (!IsValid(Hero))
			return;
		float Now = Hero.GetExperienceAttribute();
		if (Last < 0.0f || World.TimeSeconds - ReadyAt < SETTLE_SECONDS)
		{
			Last = Now;
			return;
		}
		float Gain = Now - Last;
		Last = Now;
		if (Gain <= 0.0f || Gain > MAX_GAIN || !Mega::On(S.Enabled))
			return;

		float Factor = Mega::Num(S.Multiplier);
		int LargeFrom = Mega::Int(S.LargeGainFrom);
		if (LargeFrom > 0 && Gain >= LargeFrom)
			Factor = Mega::Num(S.LargeGainMultiplier);
		float Extra = Gain * (Factor - 1.0f) + Carry;
		int Whole = Math::TruncToInt(Extra);
		Carry = Extra - Whole;
		if (Whole <= 0)
		{
			if (Mega::On(S.LogGains))
				Mega::Say("xp", f"gain {Gain} x{Factor}: nothing to add");
			return;
		}
		Hero.GiveExperience(Whole);
		Last = Hero.GetExperienceAttribute();        // what the module gave is not a gain of the game
		if (Mega::On(S.LogGains))
			Mega::Say("xp", f"gain {Gain} x{Factor}: {Whole} added");
		if (Mega::On(S.ShowMessage))
			Mega::Note("xp", f"+{Whole} experience (x{Factor})");
	}
}
