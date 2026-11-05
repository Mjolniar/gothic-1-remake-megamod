// MegaMod - lock picking by skill (port of the UE4SS module locks).
// This is an unofficial modification. It is not made, endorsed or supported by THQ Nordic.
//
// The game takes the first connections of a lock away as the hero's LockpickPrecision says, and a lock pick takes as
// many wrong moves as LockpickDurability says (AttributeSet_Lockpicking; the hero's definition sets 0/1/2 and 2/4/6
// for the skill tags Untrained/Trained/Master - SOURCE Script/Player/PlayerCharacter.as). Ten times a second the
// module looks at the hero and keeps both numbers at what the settings want for his level; nothing is written while
// a lock is being picked (tag State.PickLock).
// "half" and "safe" depend on the lock: while the hero's chest or door ability is running (before the lock is set
// up) its lock name is read and the number for that lock is written; between locks the game's own number stands.
// A lock not in the table (MegaLockData.as) is left as the game has it.

class UMegaLocks : UGothicModExt_WorldSubsystem
{
	const float LOOK_SECONDS = 0.1f;
	const float ALL = 99.0f;          // more connections than any lock has (the largest has 11)
	const float NEVER = 100000.0f;    // wrong moves of a pick that does not break
	const float SAME = 0.01f;

	// the choices of a level's "connections taken away"
	const int GAME = 1;
	const int NONE = 2;
	const int ONE = 3;
	const int TWO = 4;
	const int HALF = 5;
	const int SAFE = 6;
	const int EVERY = 7;

	bool MinePrecision = false;       // the number in place is this module's, not the game's
	bool MineDurability = false;
	bool Picking = false;
	FName Announced;                  // the lock of the running chest / door ability
	int AnnouncedCount = 0;
	int AnnouncedValue = -1;          // -1: not in the table
	FTimerHandle Timer;

	UFUNCTION(BlueprintOverride)
	void HandleReadyForPlay()
	{
		MinePrecision = false;
		MineDurability = false;
		Picking = false;
		Announced = FName();
		Timer = System::SetTimer(this, n"Look", LOOK_SECONDS, true);
	}

	// 0 untrained, 1 skilled, 2 master; -1 none of the three tags
	int Level(AGothicPlayerState Hero)
	{
		if (Hero.HasGameplayTag(GameplayTag::Skill_Lockpicking_Master))
			return 2;
		if (Hero.HasGameplayTag(GameplayTag::Skill_Lockpicking_Trained))
			return 1;
		if (Hero.HasGameplayTag(GameplayTag::Skill_Lockpicking_Untrained))
			return 0;
		return -1;
	}

	FString LevelName(int L)
	{
		if (L == 2)
			return "master";
		if (L == 1)
			return "skilled";
		return "untrained";
	}

	float OwnPrecision(int L)
	{
		return float(L);
	}

	float OwnDurability(int L)
	{
		return 2.0f + 2.0f * L;
	}

	int Mode(const UMegaSettings_Locks S, int L)
	{
		if (L == 2)
			return Mega::Int(S.MasterConnections);
		if (L == 1)
			return Mega::Int(S.SkilledConnections);
		return Mega::Int(S.UntrainedConnections);
	}

	int Moves(const UMegaSettings_Locks S, int L)
	{
		if (L == 2)
			return Mega::Int(S.MasterWrongMoves);
		if (L == 1)
			return Mega::Int(S.SkilledWrongMoves);
		return Mega::Int(S.UntrainedWrongMoves);
	}

	// The lock of the hero's running chest or door ability (None when there is none).
	FName OpeningLock(UGothicAbilitySystemComponent Abilities)
	{
		TArray<UGameplayAbility> Active;
		Abilities.GetActiveAbilitiesWithTags(FGameplayTagContainer(), Active);
		for (UGameplayAbility A : Active)
		{
			UGameplayAbilityOpen Chest = Cast<UGameplayAbilityOpen>(A);
			if (IsValid(Chest) && !Chest.m_Lock.IsNone())
				return Chest.m_Lock;
			UGameplayAbilityDoor Door = Cast<UGameplayAbilityDoor>(A);
			if (IsValid(Door) && !Door.m_Lock.IsNone())
				return Door.m_Lock;
		}
		return FName();
	}

	// Takes note of the lock being opened and works out its number for "half" / "safe".
	void Announce(FName Lock, int Choice, int L)
	{
		if (Lock == Announced)
			return;
		Announced = Lock;
		AnnouncedCount = 0;
		AnnouncedValue = -1;
		UMegaLockData Data = UMegaLockData::Get();
		int Count = 0;
		int Proven = 0;
		if (IsValid(Data) && Data.Find(Lock, Count, Proven))
		{
			int Base = Choice == HALF ? Count / 2 : Count;
			AnnouncedCount = Count;
			AnnouncedValue = Math::Min(Math::Max(Base, L), Proven);
		}
	}

	// The precision the settings want now; false for the game's own.
	bool WantPrecision(const UMegaSettings_Locks S, int L, float& Out)
	{
		int Choice = Mode(S, L);
		if (Choice == NONE) { Out = 0.0f; return true; }
		if (Choice == ONE) { Out = 1.0f; return true; }
		if (Choice == TWO) { Out = 2.0f; return true; }
		if (Choice == EVERY) { Out = ALL; return true; }
		if ((Choice == HALF || Choice == SAFE) && !Announced.IsNone() && AnnouncedValue >= 0)
		{
			Out = float(AnnouncedValue);
			return true;
		}
		return false;
	}

	bool WantDurability(const UMegaSettings_Locks S, int L, float& Out)
	{
		if (Mega::On(S.PicksNeverBreak)) { Out = NEVER; return true; }
		int M = Moves(S, L);
		if (M > 0) { Out = float(M); return true; }
		return false;
	}

	// Brings one attribute to the wanted number, or back to the game's own when the number in place is this
	// module's (per-lock choices: always the game's own between locks). Returns the new "mine" flag.
	bool Settle(UGothicAbilitySystemComponent Abilities, FName Attribute, bool Want, float Value, float Own, bool Mine, bool Always)
	{
		if (!Want && !Mine && !Always)
			return false;
		float Current = 0.0f;
		if (!Abilities.TryGetAttributeCurrentValue(UAttributeSet_Lockpicking::StaticClass(), Attribute, Current))
			return Mine;
		float Target = Want ? Value : Own;
		if (Math::Abs(Current - Target) > SAME)
		{
			if (!Abilities.TrySetAttributeBaseValue(UAttributeSet_Lockpicking::StaticClass(), Attribute, Target))
			{
				Mega::Say("locks", f"{Attribute} could not be written");
				return Mine;
			}
		}
		return Want && Math::Abs(Value - Own) > SAME;
	}

	UFUNCTION()
	void Look()
	{
		const UMegaSettings_Locks S = UMegaSettings_Locks.DefaultObject;
		AGothicPlayerState Hero = Mega::Player();
		if (!IsValid(Hero) || !IsValid(Hero.AbilitySystemComponent))
			return;
		UGothicAbilitySystemComponent Abilities = Hero.AbilitySystemComponent;
		int L = Level(Hero);
		if (L < 0)
			return;

		bool Now = Hero.HasGameplayTag(GameplayTag::State_PickLock);
		if (Now && !Picking)
			Started(S, Abilities, L);
		Picking = Now;
		if (Picking)
			return;

		bool On = Mega::On(S.Enabled);
		int Choice = Mode(S, L);
		bool PerLock = On && (Choice == HALF || Choice == SAFE);
		if (PerLock)
		{
			FName Lock = OpeningLock(Abilities);
			if (Lock.IsNone())
				Announced = FName();
			else
				Announce(Lock, Choice, L);
		}
		else
			Announced = FName();

		float Value = 0.0f;
		bool Want = On && WantPrecision(S, L, Value);
		MinePrecision = Settle(Abilities, n"LockpickPrecision", Want, Value, OwnPrecision(L), MinePrecision, PerLock);
		Want = On && WantDurability(S, L, Value);
		MineDurability = Settle(Abilities, n"LockpickDurability", Want, Value, OwnDurability(L), MineDurability, false);
	}

	// A lock has started: the note and the log line.
	void Started(const UMegaSettings_Locks S, UGothicAbilitySystemComponent Abilities, int L)
	{
		FString Text = "";
		float Precision = 0.0f;
		float Durability = 0.0f;
		Abilities.TryGetAttributeCurrentValue(UAttributeSet_Lockpicking::StaticClass(), n"LockpickPrecision", Precision);
		Abilities.TryGetAttributeCurrentValue(UAttributeSet_Lockpicking::StaticClass(), n"LockpickDurability", Durability);
		if (MinePrecision)
		{
			int Removed = Math::RoundToInt(Precision);
			if (AnnouncedCount > 0)
				Text = f"{Math::Min(Removed, AnnouncedCount)} of {AnnouncedCount} connections taken away";
			else if (Precision >= ALL)
				Text = "all connections taken away";
			else
				Text = f"{Removed} connections taken away";
		}
		if (MineDurability)
		{
			FString Pick = Durability >= NEVER ? "the pick does not break" : f"the pick breaks after {Math::RoundToInt(Durability)} wrong moves";
			Text = Text.IsEmpty() ? Pick : Text + ", " + Pick;
		}
		FString Lock = Announced.IsNone() ? "" : f", {Announced}";
		if (Mega::On(S.LogLocks))
			Mega::Say("locks", f"lock started ({LevelName(L)}{Lock}): " + (Text.IsEmpty() ? "as the game has it" : Text));
		if (!Text.IsEmpty() && Mega::On(S.ShowMessage))
			Mega::Note("locks", f"Lock picking ({LevelName(L)}): {Text}");
	}
}
