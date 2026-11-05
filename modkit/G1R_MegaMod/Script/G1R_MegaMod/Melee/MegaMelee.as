// MegaMod - melee clean-ups (port of the UE4SS module melee).
// This is an unofficial modification. It is not made, endorsed or supported by THQ Nordic.
//
// Every three seconds:
// - flow helper: the game's option "fake sloppy combos" (UGothicGameUserSettings.m_FakeSloppyCombos) is set on or
//   off; "game" leaves it alone (and puts back what the game had, if the module changed it). The property is written
//   directly: the game's profile keeps its own value (melee facts M4/M5);
// - hit stop: m_FreezeDuration and m_BlendOutDuration of the freeze tables of UGenericMeleeFeedback (every melee
//   weapon's feedback; SOURCE Items/Weapons/ControlFeedback.as) are the game's times the percentage;
// - camera shake: off, every entry of its two shake tables names UMatineeCameraShake_None (the game's own shake
//   without motion); on, the game's classes are back.
// The game's own values are kept in UMegaMemory for the whole game; entries are never added or removed.

class UMegaMelee : UGothicModExt_WorldSubsystem
{
	const float LOOK_SECONDS = 3.0f;
	const float SAME = 0.0001f;

	const int FLOW_GAME = 1;
	const int FLOW_OFF = 2;
	const int FLOW_ON = 3;

	bool FlowMine = false;
	int LastStop = -1;
	int LastShake = -1;
	FTimerHandle Timer;

	UFUNCTION(BlueprintOverride)
	void HandleReadyForPlay()
	{
		Timer = System::SetTimer(this, n"Look", LOOK_SECONDS, true);
		Look();
	}

	UFUNCTION()
	void Look()
	{
		const UMegaSettings_Melee S = UMegaSettings_Melee.DefaultObject;
		UMegaMemory Memory = UMegaMemory::Get();
		if (!IsValid(Memory))
			return;
		bool On = Mega::On(S.Enabled);
		Flow(Memory, On ? Mega::Int(S.FlowHelper) : FLOW_GAME, Mega::On(S.ShowMessage));

		UFeedbackData Feedback = Cast<UFeedbackData>(UGenericMeleeFeedback::StaticClass().GetDefaultObject());
		if (!IsValid(Feedback))
			return;
		int Stop = On ? Mega::Int(S.HitStop) : 100;
		bool Shake = !On || Mega::On(S.HitShake);
		Freeze(Memory, Feedback.m_AttackFreezeParams, "attack", Stop / 100.0f);
		Freeze(Memory, Feedback.m_HitFreezeParams, "hit", Stop / 100.0f);
		Shakes(Memory, Feedback.m_AttackCameraShakeParams, "attack", Shake);
		Shakes(Memory, Feedback.m_HitCameraShakeParams, "hit", Shake);
		int ShakeNumber = Shake ? 1 : 0;
		if ((Stop != LastStop || ShakeNumber != LastShake) && LastStop >= 0 && Mega::On(S.ShowMessage))
			Mega::Note("melee", f"Melee: hit stop {Stop}%, camera shake " + (Shake ? "on" : "off"));
		LastStop = Stop;
		LastShake = ShakeNumber;
	}

	void Flow(UMegaMemory Memory, int Choice, bool Show)
	{
		UGothicGameUserSettings Settings = UGothicGameUserSettings::GetGothicGameUserSettings();
		if (!IsValid(Settings))
			return;
		if (Choice == FLOW_GAME)
		{
			if (FlowMine && Memory.Flags.Contains("melee.flow"))
				Settings.m_FakeSloppyCombos = Memory.Flags["melee.flow"];
			FlowMine = false;
			return;
		}
		Memory.OriginalFlag("melee.flow", Settings.m_FakeSloppyCombos);
		bool Want = Choice == FLOW_ON;
		if (Settings.m_FakeSloppyCombos != Want)
		{
			Settings.m_FakeSloppyCombos = Want;
			Mega::Say("melee", "flow helper " + (Want ? "on" : "off"));
			if (Show)
				Mega::Note("melee", "Melee: mirrored follow-up swings " + (Want ? "on" : "off"));
		}
		FlowMine = true;
	}

	void Freeze(UMegaMemory Memory, TMap<FGameplayTag, FFreezeParams>& Table, FString Name, float Factor)
	{
		TArray<FGameplayTag> Keys;
		for (auto Entry : Table)
			Keys.Add(Entry.Key);
		for (FGameplayTag Key : Keys)
		{
			FFreezeParams P = Table[Key];
			FString Place = f"melee.{Name}.{Key.ToString()}";
			float Duration = Memory.Original(Place + ".freeze", P.m_FreezeDuration) * Factor;
			float BlendOut = Memory.Original(Place + ".blend", P.m_BlendOutDuration) * Factor;
			if (Math::Abs(P.m_FreezeDuration - Duration) <= SAME && Math::Abs(P.m_BlendOutDuration - BlendOut) <= SAME)
				continue;
			P.m_FreezeDuration = Duration;
			P.m_BlendOutDuration = BlendOut;
			Table.Add(Key, P);
		}
	}

	void Shakes(UMegaMemory Memory, TMap<FGameplayTag, TSubclassOf<UCameraShakeBase>>& Table, FString Name, bool On)
	{
		TArray<FGameplayTag> Keys;
		for (auto Entry : Table)
			Keys.Add(Entry.Key);
		for (FGameplayTag Key : Keys)
		{
			TSubclassOf<UCameraShakeBase> Own = Memory.OriginalShake(f"melee.{Name}.{Key.ToString()}", Table[Key]);
			TSubclassOf<UCameraShakeBase> Want = Own;
			if (!On)
				Want = UMatineeCameraShake_None::StaticClass();
			if (Table[Key].Get() != Want.Get())
				Table.Add(Key, Want);
		}
	}
}
