// MegaMod - movement speeds (port of the UE4SS module movement).
// This is an unofficial modification. It is not made, endorsed or supported by THQ Nordic.
//
// Once a second:
// - the hero on foot and the rideable scavenger: their AttributeSet_Movement.SpeedModifier (base value; the game's
//   own is 1.0 - SOURCE Player/PlayerCharacter.as, AI/AIAgent/Creature/CharacterDefinition_Creature.as) is set to the
//   setting; the game's tiredness effects still apply on top of it;
// - swimming: the speeds of ULocomotionSpeedSettings_Swim_Laying_Player (walking 100, running 150, sprinting 220 -
//   SOURCE Player/SpeedConfig_Player.as) are set to the game's speeds times the setting.
// Switched off, every number goes back to the game's own once.

class UMegaMovement : UGothicModExt_WorldSubsystem
{
	const float LOOK_SECONDS = 1.0f;
	const float GAME_FACTOR = 1.0f;
	const float SAME = 0.001f;

	bool PutBack = true;            // the game's own numbers are in place (nothing to put back)
	FTimerHandle Timer;

	UFUNCTION(BlueprintOverride)
	void HandleReadyForPlay()
	{
		PutBack = false;            // a save may hold a factor of this module: looked at once even when off
		Timer = System::SetTimer(this, n"Look", LOOK_SECONDS, true);
		Look();
	}

	UFUNCTION()
	void Look()
	{
		const UMegaSettings_Movement S = UMegaSettings_Movement.DefaultObject;
		bool On = Mega::On(S.Enabled);
		if (!On && PutBack)
			return;
		float Hero = On ? Mega::Num(S.HeroSpeed) : GAME_FACTOR;
		float Swim = On ? Mega::Num(S.SwimSpeed) : GAME_FACTOR;
		float Mount = On ? Mega::Num(S.MountSpeed) : GAME_FACTOR;
		bool Log = Mega::On(S.LogChanges);

		AGothicPlayerState Player = Mega::Player();
		if (IsValid(Player))
			Factor(Player.AbilitySystemComponent, "hero", Hero, Log);
		AGothicNPCState Scavenger = FCharacterUniqueName(n"Scavenger_Adult_Rideable").NPCState;
		if (IsValid(Scavenger))
			Factor(Scavenger.AbilitySystemComponent, "scavenger", Mount, Log);
		Swimming(Swim, Log);
		PutBack = !On;
	}

	void Factor(UGothicAbilitySystemComponent Abilities, FString Who, float Want, bool Log)
	{
		if (!IsValid(Abilities))
			return;
		float Base = 0.0f;
		if (!Abilities.TryGetAttributeBaseValue(UAttributeSet_Movement::StaticClass(), n"SpeedModifier", Base))
			return;
		if (Math::Abs(Base - Want) <= SAME)
			return;
		if (Abilities.TrySetAttributeBaseValue(UAttributeSet_Movement::StaticClass(), n"SpeedModifier", Want))
		{
			if (Log)
				Mega::Say("movement", f"{Who}: speed factor {Base} -> {Want}");
		}
		else
			Mega::Say("movement", f"{Who}: the speed factor could not be written");
	}

	void Swimming(float Factor, bool Log)
	{
		ULocomotionSpeedSettings_WalkSpeed Table = Cast<ULocomotionSpeedSettings_WalkSpeed>(ULocomotionSpeedSettings_Swim_Laying_Player::StaticClass().GetDefaultObject());
		UMegaMemory Memory = UMegaMemory::Get();
		if (!IsValid(Table) || !IsValid(Memory))
			return;
		Speed(Table, Memory, EWalkSpeed::Walking, "walking", Factor, Log);
		Speed(Table, Memory, EWalkSpeed::Running, "running", Factor, Log);
		Speed(Table, Memory, EWalkSpeed::Sprinting, "sprinting", Factor, Log);
	}

	void Speed(ULocomotionSpeedSettings_WalkSpeed Table, UMegaMemory Memory, EWalkSpeed Kind, FString Name, float Factor, bool Log)
	{
		if (!Table.m_Speeds.Contains(Kind))
			return;
		float Own = Memory.Original(f"swim.{Name}", Table.m_Speeds[Kind]);
		float Want = Own * Factor;
		if (Math::Abs(Table.m_Speeds[Kind] - Want) <= SAME)
			return;
		Table.m_Speeds.Add(Kind, Want);
		if (Log)
			Mega::Say("movement", f"swimming ({Name}): {Want} (the game: {Own})");
	}
}
