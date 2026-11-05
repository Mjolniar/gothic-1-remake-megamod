// MegaMod for Gothic 1 Remake - shared helpers of all modules.
// This is an unofficial modification. It is not made, endorsed or supported by THQ Nordic.
//
// Every module reads its settings from its own settings class (Settings/*.as, generated from the module's
// schema.lua): the values live on the class's default object and change when the player edits them in the game's
// options. Nothing here keeps state; the notes on screen are a world subsystem (MegaNotes) that the notes widget
// (General/MegaNotesWidget.as) shows.

namespace Mega
{
	// ---- settings (one place that knows the fields of the game's settings structs) ----
	bool On(FModUserSettingsBool Setting)
	{
		return Setting.Value;
	}
	int Int(FModUserSettingsInt Setting)
	{
		return Setting.Value;
	}
	float Num(FModUserSettingsFloat Setting)
	{
		return Setting.Value;
	}

	// ---- the hero ----
	AGothicPlayerState Player()
	{
		AGothicPlayerState State = AGothicPlayerState::MainPlayerState;
		if (!IsValid(State))
			return nullptr;
		return State;
	}

	// ---- the log (the game's own log file, Saved/Logs) ----
	void Say(FString Module, FString Text)
	{
		Log(f"[MegaMod {Module}] {Text}");
	}

	// ---- a short note on screen (shown by the notes widget; also written to the log) ----
	void Note(FString Module, FString Text)
	{
		Say(Module, Text);
		UMegaNotes Notes = UMegaNotes::Get();
		if (IsValid(Notes))
			Notes.Add(Text);
	}

	// ---- keys: the number a key setting holds -> the key (0 = none) ----
	// 1-26 A-Z, 27-36 the digits 0-9, 37-48 F1-F12, 49-58 the number pad 0-9.
	FKey KeyOf(int Number)
	{
		switch (Number)
		{
			case 1: return EKeys::A;
			case 2: return EKeys::B;
			case 3: return EKeys::C;
			case 4: return EKeys::D;
			case 5: return EKeys::E;
			case 6: return EKeys::F;
			case 7: return EKeys::G;
			case 8: return EKeys::H;
			case 9: return EKeys::I;
			case 10: return EKeys::J;
			case 11: return EKeys::K;
			case 12: return EKeys::L;
			case 13: return EKeys::M;
			case 14: return EKeys::N;
			case 15: return EKeys::O;
			case 16: return EKeys::P;
			case 17: return EKeys::Q;
			case 18: return EKeys::R;
			case 19: return EKeys::S;
			case 20: return EKeys::T;
			case 21: return EKeys::U;
			case 22: return EKeys::V;
			case 23: return EKeys::W;
			case 24: return EKeys::X;
			case 25: return EKeys::Y;
			case 26: return EKeys::Z;
			case 27: return EKeys::Zero;
			case 28: return EKeys::One;
			case 29: return EKeys::Two;
			case 30: return EKeys::Three;
			case 31: return EKeys::Four;
			case 32: return EKeys::Five;
			case 33: return EKeys::Six;
			case 34: return EKeys::Seven;
			case 35: return EKeys::Eight;
			case 36: return EKeys::Nine;
			case 37: return EKeys::F1;
			case 38: return EKeys::F2;
			case 39: return EKeys::F3;
			case 40: return EKeys::F4;
			case 41: return EKeys::F5;
			case 42: return EKeys::F6;
			case 43: return EKeys::F7;
			case 44: return EKeys::F8;
			case 45: return EKeys::F9;
			case 46: return EKeys::F10;
			case 47: return EKeys::F11;
			case 48: return EKeys::F12;
			case 49: return EKeys::NumPadZero;
			case 50: return EKeys::NumPadOne;
			case 51: return EKeys::NumPadTwo;
			case 52: return EKeys::NumPadThree;
			case 53: return EKeys::NumPadFour;
			case 54: return EKeys::NumPadFive;
			case 55: return EKeys::NumPadSix;
			case 56: return EKeys::NumPadSeven;
			case 57: return EKeys::NumPadEight;
			case 58: return EKeys::NumPadNine;
		}
		return FKey();
	}

	// Whether the key of a key setting was pressed since the last frame (false for 0 = none).
	bool Pressed(int Number)
	{
		if (Number <= 0)
			return false;
		APlayerController Controller = Gameplay::GetPlayerController(0);
		if (!IsValid(Controller))
			return false;
		return Controller.WasInputKeyJustPressed(KeyOf(Number));
	}

	// The key's name for texts ("Y", "F3"; "" for none).
	FString KeyName(int Number)
	{
		if (Number <= 0)
			return "";
		return KeyOf(Number).ToString();
	}
}

// The notes waiting to be shown, oldest first. The notes widget takes them; with no widget they only go to the log.
class UMegaNotes : UScriptWorldSubsystem
{
	TArray<FString> Pending;

	void Add(FString Text)
	{
		if (Pending.Num() >= 8)
			Pending.RemoveAt(0);
		Pending.Add(Text);
	}

	bool Take(FString& Out)
	{
		if (Pending.Num() == 0)
			return false;
		Out = Pending[0];
		Pending.RemoveAt(0);
		return true;
	}
}

// What the game had in its class defaults before a module changed them. Class defaults live as long as the game runs
// (a map load does not reset them), so the originals are kept here, for the whole game, not in a world subsystem:
// a module that starts again on the next map must not take its own numbers for the game's.
class UMegaMemory : UScriptGameInstanceSubsystem
{
	TMap<FString, float> Numbers;
	TMap<FString, bool> Flags;
	TMap<FString, TSubclassOf<UCameraShakeBase>> Shakes;

	TSubclassOf<UCameraShakeBase> OriginalShake(FString Place, TSubclassOf<UCameraShakeBase> Current)
	{
		if (Shakes.Contains(Place))
			return Shakes[Place];
		Shakes.Add(Place, Current);
		return Current;
	}

	// The game's number of a place: the first value ever seen there (the module has not written it yet then).
	float Original(FString Place, float Current)
	{
		if (Numbers.Contains(Place))
			return Numbers[Place];
		Numbers.Add(Place, Current);
		return Current;
	}

	bool OriginalFlag(FString Place, bool Current)
	{
		if (Flags.Contains(Place))
			return Flags[Place];
		Flags.Add(Place, Current);
		return Current;
	}
}
