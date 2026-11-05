// MegaMod - the scavenger you ride (port of the UE4SS module mount).
// This is an unofficial modification. It is not made, endorsed or supported by THQ Nordic.
//
// The game's follow routine of the rideable scavenger gives up or never starts when the hero carries
// State.RidingBlocked (a missed exit of a no-riding region), or the scavenger fears him (mount facts M5-M7).
// At every whistle (the rising edge of Action.CallMount on the hero) one line goes to the log; WaitSeconds later,
// when the scavenger has not come closer and the hero is not mounted, AutoFix puts it right: "full" takes the riding
// block off the hero, both take the fear effect (UGE_Fear) off the scavenger and put it back to its idle routine
// (which makes it friendly to the player again). The fix key does the same at once.
// Its name: the game makes it from its text table by the unique name Scavenger_Adult_Rideable (M9); the install
// script writes a text override for the name the player chose (deploy/install_modkit.py --scavenger-name).

class UMegaMount : UScriptWorldSubsystem
{
	const int FULL = 1;
	const int SAFE = 2;

	float Elapsed = 0.0f;
	bool Whistling = false;
	float CheckAt = -1.0f;        // when to look again after a whistle (-1: no whistle pending)
	float DistanceAtWhistle = 0.0f;
	int Whistles = 0;
	int Fixed = 0;

	AGothicNPCState Scavenger()
	{
		return FCharacterUniqueName(n"Scavenger_Adult_Rideable").NPCState;
	}

	// Metres between the hero and the scavenger in the plane (-1 when one of them is not there).
	float Distance(AGothicNPCState Mount)
	{
		APawn Pawn = Gameplay::GetPlayerPawn(0);
		if (!IsValid(Pawn) || !IsValid(Mount))
			return -1.0f;
		FVector A = Pawn.ActorLocation;
		FVector B = Mount.GetCharacterLocation();
		return FVector(A.X - B.X, A.Y - B.Y, 0.0f).Size() / 100.0f;
	}

	FString Report(AGothicPlayerState Hero, AGothicNPCState Mount)
	{
		FString Block = Hero.HasGameplayTag(GameplayTag::State_RidingBlocked) ? "yes" : "no";
		FString Mounted = Hero.HasGameplayTag(GameplayTag::State_Mounted) ? "yes" : "no";
		if (!IsValid(Mount))
			return f"you: riding block {Block}, mounted {Mounted} | scavenger: not there";
		FString Fear = Mount.HasGameplayTag(GameplayTag::Debuff_Fear) ? "yes" : "no";
		int Metres = Math::RoundToInt(Distance(Mount));
		return f"you: riding block {Block}, mounted {Mounted} | scavenger: {Metres} m away, fears you {Fear}";
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Elapsed += DeltaTime;
		const UMegaSettings_Mount S = UMegaSettings_Mount.DefaultObject;
		AGothicPlayerState Hero = Mega::Player();
		if (!IsValid(Hero))
			return;
		if (Mega::Pressed(Mega::Int(S.FixKey)))
		{
			Mega::Say("mount", "fix key: " + Report(Hero, Scavenger()));
			Fix(S, Hero, FULL, "by the key");
			return;
		}
		if (!Mega::On(S.Enabled))
			return;

		bool Now = Hero.HasGameplayTag(GameplayTag::Action_CallMount);
		if (Now && !Whistling)
		{
			Whistles++;
			AGothicNPCState Mount = Scavenger();
			DistanceAtWhistle = Distance(Mount);
			CheckAt = Elapsed + Mega::Int(S.WaitSeconds);
			Mega::Say("mount", f"whistle {Whistles}: " + Report(Hero, Mount));
		}
		Whistling = Now;

		if (CheckAt >= 0.0f && Elapsed >= CheckAt)
		{
			CheckAt = -1.0f;
			AGothicNPCState Mount = Scavenger();
			Mega::Say("mount", f"{Mega::Int(S.WaitSeconds)} s later: " + Report(Hero, Mount));
			if (Hero.HasGameplayTag(GameplayTag::State_Mounted))
				return;
			float Metres = Distance(Mount);
			bool Came = Metres >= 0.0f && (Metres < 5.0f || Metres < DistanceAtWhistle - 5.0f);
			int Mode = Mega::Int(S.AutoFix);
			if (!Came && (Mode == FULL || Mode == SAFE))
				Fix(S, Hero, Mode, "after a whistle");
		}
	}

	void Fix(const UMegaSettings_Mount S, AGothicPlayerState Hero, int Mode, FString Why)
	{
		FString Done = "";
		if (Mode == FULL && Hero.HasGameplayTag(GameplayTag::State_RidingBlocked) && IsValid(Hero.AbilitySystemComponent))
		{
			Hero.AbilitySystemComponent.RemoveTag(GameplayTag::State_RidingBlocked);
			Done += "riding block taken off you, ";
		}
		AGothicNPCState Mount = Scavenger();
		if (IsValid(Mount))
		{
			if (IsValid(Mount.AbilitySystemComponent) && Mount.HasGameplayTag(GameplayTag::Debuff_Fear))
			{
				Mount.AbilitySystemComponent.RemoveActiveGameplayEffectBySourceEffect(UGE_Fear::StaticClass(), nullptr, -1);
				Done += "fear taken off the scavenger, ";
			}
			Mount.ExchangeDailyRoutineToClass(UDailyRoutine_Scavenger_Rideable_Idle::StaticClass());
			Done += "scavenger back to its idle routine";
		}
		Fixed++;
		FString Text = Done.IsEmpty() ? "nothing to put right (no scavenger found)" : Done;
		Mega::Say("mount", f"put right {Why}: {Text}");
		if (Mega::On(S.ShowNotes))
			Mega::Note("mount", "Scavenger put right - whistle again");
	}
}
