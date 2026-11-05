// MegaMod - wait on a key (port of the UE4SS module wait).
// This is an unofficial modification. It is not made, endorsed or supported by THQ Nordic.
//
// Four keys (settings: key numbers, see Core/MegaCore.as KeyOf): wait a short time, wait a long time, wait until the
// morning hour, wait until the evening hour. The game's own UGameTimeSubsystem does it: SkipTime for a span,
// AdvanceToClockTime for an hour (it may end up on the next day); what goes by the clock catches up at the game's
// next step, as when the game itself jumps (wait facts W9).
// Refused (each a setting): during a fight (State.Combat: a weapon, the fists or a spell drawn), a conversation
// (State.Conversation), a cutscene (State.PartOfCinematic), while the clock stands still (a cutscene freezes it);
// and within the cooldown after the last wait. Keys are looked at every frame (the world's tick; not while paused).

class UMegaWait : UScriptWorldSubsystem
{
	const float CLOCK_LOOK_SECONDS = 1.0f;

	float Elapsed = 0.0f;
	float LastSkip = -1000.0f;
	float ClockLookAt = 0.0f;
	float LastClock = -1.0f;
	bool ClockRuns = true;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Elapsed += DeltaTime;
		const UMegaSettings_Wait S = UMegaSettings_Wait.DefaultObject;
		if (!Mega::On(S.Enabled))
			return;
		WatchClock();
		if (Mega::Pressed(Mega::Int(S.ShortKey)))
			Span(S, Mega::Int(S.ShortMinutes));
		else if (Mega::Pressed(Mega::Int(S.LongKey)))
			Span(S, Mega::Int(S.LongMinutes));
		else if (Mega::Pressed(Mega::Int(S.MorningKey)))
			UntilHour(S, Mega::Int(S.MorningHour), "morning");
		else if (Mega::Pressed(Mega::Int(S.EveningKey)))
			UntilHour(S, Mega::Int(S.EveningHour), "evening");
	}

	// Whether the game's clock moved in the last second.
	void WatchClock()
	{
		if (Elapsed < ClockLookAt)
			return;
		ClockLookAt = Elapsed + CLOCK_LOOK_SECONDS;
		UGameTimeSubsystem Time = UGameTimeSubsystem::Get();
		if (!IsValid(Time))
			return;
		float Clock = Time.GetCurrentGameTimeInRealTime();
		ClockRuns = LastClock < 0.0f || Math::Abs(Clock - LastClock) > 0.0001f;
		LastClock = Clock;
	}

	// Why a wait is refused now ("" when it is not).
	FString Refused(const UMegaSettings_Wait S)
	{
		if (Elapsed - LastSkip < Mega::Num(S.Cooldown))
			return "too soon after the last wait";
		AGothicPlayerState Hero = Mega::Player();
		if (!IsValid(Hero))
			return "no game running";
		if (Mega::On(S.NotInFight) && Hero.HasGameplayTag(GameplayTag::State_Combat))
			return "a weapon or spell is drawn";
		if (Mega::On(S.NotInConversation) && Hero.HasGameplayTag(GameplayTag::State_Conversation))
			return "in a conversation";
		if (Mega::On(S.NotInCutscene) && Hero.HasGameplayTag(GameplayTag::State_PartOfCinematic))
			return "in a cutscene";
		if (Mega::On(S.NotWhenClockStopped) && !ClockRuns)
			return "the clock stands still";
		return "";
	}

	bool Allowed(const UMegaSettings_Wait S)
	{
		FString Why = Refused(S);
		if (Why.IsEmpty())
			return true;
		if (Mega::On(S.LogSkips))
			Mega::Say("wait", f"not waiting: {Why}");
		if (Mega::On(S.ShowRefused))
			Mega::Note("wait", f"Wait: not now ({Why})");
		return false;
	}

	void Span(const UMegaSettings_Wait S, int Minutes)
	{
		UGameTimeSubsystem Time = UGameTimeSubsystem::Get();
		if (Minutes <= 0 || !IsValid(Time) || !Allowed(S))
			return;
		FClockTime Before = Time.GetCurrentClockTime();
		Time.SkipTime(FInGameTime::FromMinutes(Minutes));
		Done(S, Before, Time.GetCurrentClockTime(), f"{Minutes} minutes");
	}

	void UntilHour(const UMegaSettings_Wait S, int Hour, FString Name)
	{
		UGameTimeSubsystem Time = UGameTimeSubsystem::Get();
		if (!IsValid(Time) || !Allowed(S))
			return;
		FClockTime Before = Time.GetCurrentClockTime();
		FClockTime Target = Before;
		Target.SetHour(Math::Clamp(Hour, 0, 23));
		Target.SetMinute(0);
		Time.AdvanceToClockTime(Target);
		Done(S, Before, Time.GetCurrentClockTime(), f"until {Name}");
	}

	void Done(const UMegaSettings_Wait S, FClockTime Before, FClockTime After, FString What)
	{
		LastSkip = Elapsed;
		LastClock = -1.0f;
		if (Mega::On(S.LogSkips))
			Mega::Say("wait", f"waited {What}: {Before.ToShortString()} -> {After.ToShortString()}");
		if (Mega::On(S.ShowMessage))
			Mega::Note("wait", f"Waited {What}: now {After.ToShortString()}");
	}
}
