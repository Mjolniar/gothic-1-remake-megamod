// MegaMod - mana and health regeneration (port of the UE4SS module regen).
// This is an unofficial modification. It is not made, endorsed or supported by THQ Nordic.
//
// Twice a second the module looks at the hero's Mana and Health (AttributeSet_Mana, AttributeSet_Health). Time counts
// only while the game's clock runs (the world's timers stop while the game is paused; a clock that stands - a
// cutscene, a menu - is seen by GetCurrentGameTimeInRealTime not moving). After the value went down (a spell, a hit)
// regeneration waits for the time set; it also waits once after a load. A step adds a share of the maximum and a
// fixed number of points, whole points only (the fraction is carried over), up to the chosen part of the maximum,
// with the game's own TrySetAttributeBaseValue. Mana can depend on the magic circle (MagicianLevel: -1 no training,
// 0 the basics, 1-6 the circles), and both can run slower while a weapon or spell is drawn (State.Combat).
// The game blocks casting with State.OutMana when a spell used the mana up and takes it off only with its own
// effects; after a step from zero the module takes the tag off with the game's RemoveTag.
// Never: a dead or defeated hero gets nothing; nothing goes above the limit; after a load the first look only
// takes the values.

struct FMegaRegenPart
{
	float Last = -1.0f;       // the value at the last look (-1: the next look only takes it)
	float Pause = 0.0f;       // seconds of waiting left
	float Waited = 0.0f;      // seconds counted towards the next step
	float Carry = 0.0f;       // the fraction of a point not given yet
	bool Resting = true;      // the last step reached the limit, or nothing ran yet
}

class UMegaRegen : UGothicModExt_WorldSubsystem
{
	const float LOOK_SECONDS = 0.5f;

	FMegaRegenPart Mana;
	FMegaRegenPart Health;
	float LastClock = -1.0f;
	FTimerHandle Timer;

	UFUNCTION(BlueprintOverride)
	void HandleReadyForPlay()
	{
		Mana = FMegaRegenPart();
		Health = FMegaRegenPart();
		LastClock = -1.0f;
		Timer = System::SetTimer(this, n"Look", LOOK_SECONDS, true);
	}

	UFUNCTION()
	void Look()
	{
		const UMegaSettings_Regen S = UMegaSettings_Regen.DefaultObject;
		AGothicPlayerState Hero = Mega::Player();
		if (!Mega::On(S.Enabled) || !IsValid(Hero) || !IsValid(Hero.AbilitySystemComponent))
		{
			Mana = FMegaRegenPart();
			Health = FMegaRegenPart();
			return;
		}
		// time counts only while the game's clock runs
		float Seconds = LOOK_SECONDS;
		UGameTimeSubsystem Time = UGameTimeSubsystem::Get();
		if (IsValid(Time))
		{
			float Clock = Time.GetCurrentGameTimeInRealTime();
			if (LastClock >= 0.0f && Math::Abs(Clock - LastClock) < 0.0001f)
				Seconds = 0.0f;
			LastClock = Clock;
		}
		UGothicAbilitySystemComponent Abilities = Hero.AbilitySystemComponent;
		if (Down(Hero))
			return;

		if (Mega::On(S.ManaEnabled))
		{
			float Amount = Mega::Num(S.ManaFlat);
			float Share = Mega::Num(S.ManaPercent);
			float Factor = Mega::On(S.ManaByCircle) ? CircleShare(S, Abilities) : 1.0f;
			Run(Mana, Abilities, UAttributeSet_Mana::StaticClass(), n"Mana", n"MaxMana", "Mana", Amount, Share, Factor,
				Mega::Num(S.ManaSeconds), Mega::Int(S.ManaUpTo), Mega::Int(S.ManaPause), Mega::Int(S.ManaArmedPercent), Seconds, Hero, S);
		}
		else
			Mana = FMegaRegenPart();

		if (Mega::On(S.HealthEnabled))
		{
			Run(Health, Abilities, UAttributeSet_Health::StaticClass(), n"Health", n"MaxHealth", "Health",
				Mega::Num(S.HealthFlat), Mega::Num(S.HealthPercent), 1.0f,
				Mega::Num(S.HealthSeconds), Mega::Int(S.HealthUpTo), Mega::Int(S.HealthPause), Mega::Int(S.HealthArmedPercent), Seconds, Hero, S);
		}
		else
			Health = FMegaRegenPart();
	}

	bool Down(AGothicPlayerState Hero)
	{
		return Hero.HasGameplayTag(GameplayTag::State_Dead) || Hero.HasGameplayTag(GameplayTag::State_Defeated)
			|| Hero.GetHealthAttribute() <= 0.0f;
	}

	float CircleShare(const UMegaSettings_Regen S, UGothicAbilitySystemComponent Abilities)
	{
		float Level = 0.0f;
		if (!Abilities.TryGetAttributeCurrentValue(UAttributeSet_Mana::StaticClass(), n"MagicianLevel", Level))
			return 1.0f;
		int Circle = Math::RoundToInt(Level);
		if (Circle < 0)
			return Mega::Int(S.ManaCircleNone) / 100.0f;
		if (Circle < 1)
			return Mega::Int(S.ManaCircleNovice) / 100.0f;
		return (Mega::Int(S.ManaCircleFirst) + (Circle - 1) * Mega::Int(S.ManaCircleStep)) / 100.0f;
	}

	void Run(FMegaRegenPart& Part, UGothicAbilitySystemComponent Abilities, TSubclassOf<UAngelscriptAttributeSet> Set,
		FName Key, FName TopKey, FString Word, float Flat, float Percent, float Factor, float StepSeconds, int UpTo,
		int PauseSeconds, int ArmedPercent, float Seconds, AGothicPlayerState Hero, const UMegaSettings_Regen S)
	{
		float Value = 0.0f;
		float Base = 0.0f;
		float Top = 0.0f;
		if (!Abilities.TryGetAttributeCurrentValue(Set, Key, Value) || !Abilities.TryGetAttributeBaseValue(Set, Key, Base)
			|| !Abilities.TryGetAttributeCurrentValue(Set, TopKey, Top))
			return;
		if (Part.Last < 0.0f)
		{
			Part.Last = Value;
			Part.Pause = PauseSeconds;
			return;
		}
		if (Value < Part.Last - 0.001f)
		{
			Part.Pause = PauseSeconds;
			Part.Waited = 0.0f;
			Part.Carry = 0.0f;
		}
		Part.Last = Value;
		if (Part.Pause > 0.0f)
		{
			Part.Pause -= Seconds;
			return;
		}
		Part.Waited += Seconds;
		if (Part.Waited < StepSeconds)
			return;
		Part.Waited = Math::Min(Part.Waited - StepSeconds, StepSeconds);

		float Limit = Math::FloorToFloat(Top * UpTo / 100.0f);
		if (Value >= Limit)
		{
			Part.Carry = 0.0f;
			Part.Resting = true;
			return;
		}
		float Amount = (Flat + Top * Percent / 100.0f) * Factor;
		if (ArmedPercent != 100 && Hero.HasGameplayTag(GameplayTag::State_Combat))
			Amount *= ArmedPercent / 100.0f;
		Part.Carry += Amount;
		float Points = Math::FloorToFloat(Part.Carry + 0.000001f);
		if (Points < 1.0f)
			return;
		float Target = Math::Min(Value + Points, Limit);
		Part.Carry -= Points;
		if (!Abilities.TrySetAttributeBaseValue(Set, Key, Base + (Target - Value)))
		{
			Mega::Say("regen", f"{Word} could not be written");
			Part.Carry = 0.0f;
			return;
		}
		float Now = Value;
		Abilities.TryGetAttributeCurrentValue(Set, Key, Now);
		Part.Last = Now;
		if (Mega::On(S.LogSteps))
			Mega::Say("regen", f"{Word} {Value} -> {Now} of {Top}");
		bool Started = Part.Resting;
		Part.Resting = false;
		if (Mega::On(S.ShowMessage))
		{
			if (Now >= Limit)
				Mega::Note("regen", f"{Word} has regenerated ({Math::RoundToInt(Now)} of {Math::RoundToInt(Top)})");
			else if (Started)
				Mega::Note("regen", f"{Word} regenerates again");
		}
		if (Key == n"Mana" && Value <= 0.0f && Hero.HasGameplayTag(GameplayTag::State_OutMana))
		{
			Abilities.RemoveTag(GameplayTag::State_OutMana);
			if (Mega::On(S.LogSteps))
				Mega::Say("regen", "the game's block on casting (out of mana) was taken off");
		}
	}
}
