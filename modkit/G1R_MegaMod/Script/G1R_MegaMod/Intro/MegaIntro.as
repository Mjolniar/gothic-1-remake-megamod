// MegaMod - the film of a new game (port of the UE4SS module intro).
// This is an unofficial modification. It is not made, endorsed or supported by THQ Nordic.
//
// The film plays as a loading screen: the game's loading screen setup takes the screens whose type is the loading
// screen helper's current type, and the intro screen (type GameIntro) plays G1R_Intro and sets the type back to
// Default (SOURCE LoadingScreen/LoadingScreenSetupTest.as, LoadingScreens/LoadingScreen_Intro.as). With the setting on,
// the intro screen says it does not fit and sets the type back itself: the setup then takes the game's usual
// loading screen.
// The logos at the start play before any script runs; the settings app writes that line into Game.ini.

UCLASS(meta=(ReplaceParentClass))
class ULoadingScreen_Intro_MegaMod : ULoadingScreen_Intro
{
	bool IsRelevant() override
	{
		const UMegaSettings_Intro S = UMegaSettings_Intro.DefaultObject;
		if (!Mega::On(S.Enabled) || !Mega::On(S.SkipNewGameFilm) || GetCurrentLoadingScreenType() != ELoadingScreenType::GameIntro)
			return Super::IsRelevant();
		ULoadingScreenHelperSubsystem Helper = ULoadingScreenHelperSubsystem::Get();
		if (IsValid(Helper))
			Helper.SetCurrentLoadingScreenType(ELoadingScreenType::Default);
		Mega::Say("intro", "the film of a new game is skipped");
		return false;
	}
}
