// MegaMod - what the mod shows on screen: notes (general), effect timers (timers), the list of keys (keys).
// This is an unofficial modification. It is not made, endorsed or supported by THQ Nordic.
//
// A widget extension of the game's crosshair widget (one of the HUD's parts, on screen while playing - SOURCE
// UI/GothicHUD.as). Three text blocks are put into the widget's root panel: the notes box in a corner (or as a line
// at the bottom), the effect timers in a corner, the key list in the middle of the left side. That the root is a
// canvas panel is UNKNOWN until the game shows it: when it is not, the module says so once in the log.
// Effect timers: the hero's active gameplay effects that run out (a total duration above 0), named by their class
// (the same names as the UE4SS module timers), with the time left.

class UMegaHud : UGothicModExt_WidgetExtension
{
	default AddToWidgetOfClass = n"/Game/UI/Crosshair/BP_CrosshairWidget.BP_CrosshairWidget_C";

	TSoftObjectPtr<UDataTable> TextStyle = n"/Game/UI/Texts/TS_Dialogue.TS_Dialogue";

	const float TIMER_LOOK_SECONDS = 0.25f;
	const int NOTES_SHOWN = 4;

	UAlkRichTextBlock NotesText;
	UAlkRichTextBlock TimersText;
	UAlkRichTextBlock KeysText;
	TArray<FString> Notes;
	TArray<float> NoteUntil;
	float Elapsed = 0.0f;
	float TimersAt = 0.0f;
	bool KeysShown = false;
	bool Ready = false;

	UFUNCTION(BlueprintOverride)
	bool RequiresTick() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void Initialize()
	{
		UUserWidget Host = GetWidget();
		UCanvasPanel Panel = Cast<UCanvasPanel>(Host.GetRootWidget());
		if (!IsValid(Panel))
		{
			Mega::Say("general", "the crosshair widget has no canvas at its root: notes, effect timers and the key list are only written to the log");
			return;
		}
		NotesText = Text(Host, Panel, n"MegaNotes");
		TimersText = Text(Host, Panel, n"MegaTimers");
		KeysText = Text(Host, Panel, n"MegaKeys");
		Ready = IsValid(NotesText) && IsValid(TimersText) && IsValid(KeysText);
	}

	UAlkRichTextBlock Text(UUserWidget Host, UCanvasPanel Panel, FName Name)
	{
		UAlkRichTextBlock Block = Cast<UAlkRichTextBlock>(Host.ConstructWidget(UAlkRichTextBlock, Name));
		if (!IsValid(Block))
			return nullptr;
		Block.SetTextStyleSet(FAssetPreload::BlockingLoad(TextStyle));
		Block.SetVisibility(ESlateVisibility::Collapsed);
		UCanvasPanelSlot Slot = Cast<UCanvasPanelSlot>(Panel.AddChild(Block));
		if (IsValid(Slot))
			Slot.SetAutoSize(true);
		return Block;
	}

	// Puts a text block into a corner: 1 top right, 2 top left, 3 bottom right, 4 bottom left, 5 bottom middle.
	void Place(UAlkRichTextBlock Block, int Corner, float X, float Y)
	{
		UCanvasPanelSlot Slot = Cast<UCanvasPanelSlot>(Block.Slot);
		if (!IsValid(Slot))
			return;
		float U = (Corner == 2 || Corner == 4) ? 0.0f : 1.0f;
		float V = (Corner == 1 || Corner == 2) ? 0.0f : 1.0f;
		if (Corner == 5)
			U = 0.5f;
		FAnchors Anchors;
		Anchors.Minimum = FVector2D(U, V);
		Anchors.Maximum = FVector2D(U, V);
		Slot.SetAnchors(Anchors);
		Slot.SetAlignment(FVector2D(U, V));
		float PX = U == 0.0f ? X : (U == 1.0f ? -X : 0.0f);
		float PY = V == 0.0f ? Y : -Y;
		Slot.SetPosition(FVector2D(PX, PY));
	}

	void Show(UAlkRichTextBlock Block, FString Content)
	{
		if (Content.IsEmpty())
		{
			Block.SetVisibility(ESlateVisibility::Collapsed);
			return;
		}
		Block.SetText(FText::FromString(Content));
		Block.SetVisibility(ESlateVisibility::HitTestInvisible);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		Elapsed += InDeltaTime;
		TakeNotes();
		if (!Ready)
			return;
		NotesTick();
		const UMegaSettings_Keys K = UMegaSettings_Keys.DefaultObject;
		if (Mega::On(K.Enabled) && Mega::Pressed(Mega::Int(K.ListKey)))
			KeysShown = !KeysShown;
		Place(KeysText, 2, 24.0f, 240.0f);
		Show(KeysText, KeysShown && Mega::On(K.Enabled) ? KeyList() : "");
		if (Elapsed >= TimersAt)
		{
			TimersAt = Elapsed + TIMER_LOOK_SECONDS;
			const UMegaSettings_Timers T = UMegaSettings_Timers.DefaultObject;
			int Corner = Mega::Int(T.Position);       // 1 bottom left, 2 top left, 3 bottom right, 4 top right
			int Mapped = Corner == 1 ? 4 : (Corner == 2 ? 2 : (Corner == 3 ? 3 : 1));
			Place(TimersText, Mapped, Mega::Int(T.DistanceX), Mega::Int(T.DistanceY));
			Show(TimersText, Mega::On(T.Enabled) ? Timers(T) : "");
		}
	}

	// ---- notes ----
	void TakeNotes()
	{
		UMegaNotes Pending = UMegaNotes::Get();
		if (!IsValid(Pending))
			return;
		const UMegaSettings_General G = UMegaSettings_General.DefaultObject;
		FString Note;
		while (Pending.Take(Note))
		{
			if (!Ready || Mega::Int(G.NoteStyle) == 3)
				continue;
			Notes.Add(Note);
			NoteUntil.Add(Elapsed + Mega::Int(G.NoteSeconds));
			if (Notes.Num() > NOTES_SHOWN)
			{
				Notes.RemoveAt(0);
				NoteUntil.RemoveAt(0);
			}
		}
	}

	void NotesTick()
	{
		while (NoteUntil.Num() > 0 && NoteUntil[0] <= Elapsed)
		{
			Notes.RemoveAt(0);
			NoteUntil.RemoveAt(0);
		}
		const UMegaSettings_General G = UMegaSettings_General.DefaultObject;
		int Style = Mega::Int(G.NoteStyle);      // 1 box, 2 subtitle, 3 off
		if (Style == 2)
			Place(NotesText, 5, 0.0f, 160.0f);
		else
			Place(NotesText, Mega::Int(G.NotePosition), 24.0f, 24.0f);     // 1 top right, 2 top left, 3 bottom right, 4 bottom left
		FString Content = "";
		if (Style != 3)
		{
			for (int i = 0; i < Notes.Num(); i++)
				Content += (i > 0 ? "\n" : "") + Notes[i];
		}
		Show(NotesText, Content);
	}

	// ---- effect timers ----
	bool Has(FString Name, FString Part)
	{
		return Name.Contains(Part);
	}

	// The line's label, or "" when the effect is not shown.
	FString Label(const UMegaSettings_Timers T, FString Name)
	{
		if (Has(Name, "Visual") || Has(Name, "Cooldown") || Has(Name, "Depletion") || Has(Name, "ManaBurn")
			|| Has(Name, "Mana_Channeling") || Has(Name, "Mana_Aiming") || Has(Name, "Removal") || Has(Name, "UnBurn")
			|| Has(Name, "EquipAbilities") || Has(Name, "NoElectrified") || Name.EndsWith("Stack"))
			return "";
		if (Has(Name, "Heal") && Has(Name, "Overtime"))
			return Mega::On(T.ShowFood) ? "Healing" : "";
		if (Has(Name, "Mana") && Has(Name, "Overtime"))
			return Mega::On(T.ShowFood) ? "Mana" : "";
		if (Has(Name, "Burn") || Has(Name, "Fire_Duration"))
			return Mega::On(T.ShowElements) ? "Burning" : "";
		if (Has(Name, "Freeze") || Has(Name, "Frozen"))
			return Mega::On(T.ShowElements) ? "Frozen" : "";
		if (Has(Name, "Electrified") || Has(Name, "Paralyz"))
			return Mega::On(T.ShowElements) ? "Electrified" : "";
		if (Has(Name, "Wind"))
			return Mega::On(T.ShowElements) ? "Wind" : "";
		if (Has(Name, "Slow"))
			return Mega::On(T.ShowElements) ? "Slowed" : "";
		if (Name == "GE_Defeated")
			return Mega::On(T.ShowMind) ? "Knocked out" : "";
		if (Name == "GE_Sleep")
			return Mega::On(T.ShowMind) ? "Asleep" : "";
		if (Name == "GE_Fear")
			return Mega::On(T.ShowMind) ? "Afraid" : "";
		if (Name == "GE_Charm")
			return Mega::On(T.ShowMind) ? "Charmed" : "";
		if (Has(Name, "Light"))
			return Mega::On(T.ShowLight) ? "Light" : "";
		if (Has(Name, "Alcohol") || Has(Name, "Booze") || Has(Name, "Drunk"))
			return Mega::On(T.ShowDrinks) ? "Alcohol" : "";
		if (Has(Name, "Swampweed") || Has(Name, "Joint"))
			return Mega::On(T.ShowDrinks) ? "Swampweed" : "";
		if (!Mega::On(T.ShowOthers))
			return "";
		FString Short = Name;
		Short.RemoveFromStart("GE_");
		return Short.Replace("_", " ");
	}

	FString Clock(float Seconds)
	{
		int S = Math::CeilToInt(Seconds);
		if (S < 60)
			return f"{S} s";
		int Rest = S % 60;
		FString Pad = Rest < 10 ? "0" : "";
		return f"{S / 60}:{Pad}{Rest}";
	}

	FString Timers(const UMegaSettings_Timers T)
	{
		AGothicPlayerState Hero = Mega::Player();
		if (!IsValid(Hero) || !IsValid(Hero.AbilitySystemComponent))
			return "";
		TArray<FActiveGameplayEffectHandle> Active = Hero.AbilitySystemComponent.GetActiveEffectsWithAllTags(FGameplayTagContainer());
		FString Lines = "";
		for (FActiveGameplayEffectHandle Handle : Active)
		{
			if (AbilitySystem::GetActiveGameplayEffectTotalDuration(Handle) <= 0.0f)
				continue;
			float Left = AbilitySystem::GetActiveGameplayEffectRemainingDuration(Handle);
			const UGameplayEffect Effect = AbilitySystem::GetGameplayEffectFromActiveEffectHandle(Handle);
			if (Left <= 0.0f || !IsValid(Effect))
				continue;
			FString Name = Effect.Class.GetName().ToString();
			Name.RemoveFromEnd("_C");
			FString L = Label(T, Name);
			if (L.IsEmpty())
				continue;
			Lines += (Lines.IsEmpty() ? "" : "\n") + L + " " + Clock(Left);
		}
		return Lines;
	}

	// ---- key list ----
	void KeyLine(FString& Lines, int Key, FString What)
	{
		if (Key > 0)
			Lines += f"\n{Mega::KeyName(Key)}  {What}";
	}

	FString KeyList()
	{
		const UMegaSettings_Wait W = UMegaSettings_Wait.DefaultObject;
		const UMegaSettings_Mount M = UMegaSettings_Mount.DefaultObject;
		const UMegaSettings_Keys K = UMegaSettings_Keys.DefaultObject;
		FString Lines = "MegaMod keys";
		KeyLine(Lines, Mega::Int(K.ListKey), "show / hide this list");
		if (Mega::On(W.Enabled))
		{
			KeyLine(Lines, Mega::Int(W.ShortKey), f"wait {Mega::Int(W.ShortMinutes)} minutes");
			KeyLine(Lines, Mega::Int(W.LongKey), f"wait {Mega::Int(W.LongMinutes)} minutes");
			KeyLine(Lines, Mega::Int(W.MorningKey), f"wait until {Mega::Int(W.MorningHour)}:00");
			KeyLine(Lines, Mega::Int(W.EveningKey), f"wait until {Mega::Int(W.EveningHour)}:00");
		}
		KeyLine(Lines, Mega::Int(M.FixKey), "put the scavenger right");
		return Lines;
	}
}
