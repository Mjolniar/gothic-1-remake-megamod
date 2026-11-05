// MegaMod - magic balancing: which spell a class belongs to, and the settings of each spell.
// This is an unofficial modification. It is not made, endorsed or supported by THQ Nordic.

namespace MegaMagic
{
	// the spells with damage, in the order of the settings
	const int FIRE_BOLT = 0;
	const int FIRE_BALL = 1;
	const int PYROKINESIS = 2;
	const int STORM_OF_FIRE = 3;
	const int FIRE_RAIN = 4;
	const int ICE_BOLT = 5;
	const int ICE_BLOCK = 6;
	const int ICE_WAVE = 7;
	const int BALL_LIGHTNING = 8;
	const int CHAIN_LIGHTNING = 9;
	const int URIZIEL = 10;
	const int DEATH_TO_THE_UNDEAD = 11;
	const int WIND_FIST = 12;
	const int STORM_FIST = 13;
	const int BREATH_OF_DEATH = 14;
	const int SPELLS = 15;

	// The definitions (what hits) of a spell. Exact classes: the orcs', demons' and companions' spells are other
	// classes and stay as they are.
	TArray<UClass> Definitions(int Spell)
	{
		TArray<UClass> Out;
		switch (Spell)
		{
			case FIRE_BOLT: Out.Add(UFireBoltProjectileDefinition::StaticClass()); break;
			case FIRE_BALL:
				Out.Add(UFireBallProjectileDefinition_Lvl1::StaticClass());
				Out.Add(UFireBallProjectileDefinition_Lvl2::StaticClass());
				Out.Add(UFireBallProjectileDefinition_Lvl3::StaticClass());
				break;
			case PYROKINESIS: Out.Add(UPyrokinesisProjectileDefinition::StaticClass()); break;
			case STORM_OF_FIRE: Out.Add(UStormOfFireDefinition::StaticClass()); break;
			case FIRE_RAIN: Out.Add(UFireRainDefinition::StaticClass()); break;
			case ICE_BOLT: Out.Add(UIceBoltProjectileDefinition::StaticClass()); break;
			case ICE_BLOCK: Out.Add(UIceBlockProjectileDefinition::StaticClass()); break;
			case ICE_WAVE: Out.Add(UIceWaveProjectileDefinition::StaticClass()); break;
			case BALL_LIGHTNING:
				Out.Add(UBallLightningDefinition_Lvl1::StaticClass());
				Out.Add(UBallLightningDefinition_Lvl2::StaticClass());
				Out.Add(UBallLightningDefinition_Lvl3::StaticClass());
				Out.Add(UBallLightningDefinition_Lvl4::StaticClass());
				break;
			case CHAIN_LIGHTNING:
				Out.Add(ULightningRayDefinition_Base::StaticClass());
				Out.Add(ULightningRayDefinition_WithParalysis::StaticClass());
				Out.Add(ULightningRayDefinition_WithoutParalysis::StaticClass());
				break;
			case URIZIEL: Out.Add(UUrizielWaveOfDeathVisualDefinition::StaticClass()); break;
			case DEATH_TO_THE_UNDEAD: Out.Add(UDeathToTheUndeadDefinition::StaticClass()); break;
			case WIND_FIST: Out.Add(UWindFistDefinition::StaticClass()); break;
			case STORM_FIST: Out.Add(UStormFistDefinition::StaticClass()); break;
			case BREATH_OF_DEATH: Out.Add(UBreathOfDeathDefinition::StaticClass()); break;
		}
		return Out;
	}

	UClass ConfigClass(int Spell)
	{
		switch (Spell)
		{
			case FIRE_BOLT: return UProjectileSpellConfig_FireBolt::StaticClass();
			case FIRE_BALL: return UProjectileSpellConfig_FireBall::StaticClass();
			case PYROKINESIS: return UPyrokinesisSpellConfig::StaticClass();
			case STORM_OF_FIRE: return UStormOfFireSpellConfig::StaticClass();
			case FIRE_RAIN: return UFireRainSpellConfig::StaticClass();
			case ICE_BOLT: return UProjectileSpellConfig_IceBolt::StaticClass();
			case ICE_BLOCK: return UIceBlockSpellConfig::StaticClass();
			case ICE_WAVE: return UIceWaveSpellConfig::StaticClass();
			case BALL_LIGHTNING: return UProjectileSpellConfig_BallLightning::StaticClass();
			case CHAIN_LIGHTNING: return UChainLightningSpellConfig::StaticClass();
			case URIZIEL: return UUrizielWaveOfDeathSpellConfig::StaticClass();
			case DEATH_TO_THE_UNDEAD: return UDeathToTheUndeadSpellConfig::StaticClass();
			case WIND_FIST: return UFistOfWindSpellConfig::StaticClass();
			case STORM_FIST: return UStormFistSpellConfig::StaticClass();
			case BREATH_OF_DEATH: return UBreathOfDeathSpellConfig::StaticClass();
		}
		return nullptr;
	}

	// The spell a definition class belongs to (-1: none of the hero's spells).
	int SpellOf(UClass DefinitionClass)
	{
		for (int Spell = 0; Spell < SPELLS; Spell++)
		{
			TArray<UClass> Classes = Definitions(Spell);
			for (UClass C : Classes)
			{
				if (C == DefinitionClass)
					return Spell;
			}
		}
		return -1;
	}

	bool Flies(int Spell)
	{
		return Spell == FIRE_BOLT || Spell == FIRE_BALL || Spell == STORM_OF_FIRE || Spell == ICE_BOLT || Spell == BALL_LIGHTNING;
	}

	float School(const UMegaSettings_Magic S, int Spell)
	{
		if (Spell <= FIRE_RAIN)
			return Mega::Num(S.SchoolFire);
		if (Spell <= ICE_WAVE)
			return Mega::Num(S.SchoolIce);
		if (Spell <= DEATH_TO_THE_UNDEAD)
			return Mega::Num(S.SchoolEnergy);
		return Mega::Num(S.SchoolWind);
	}

	float Damage(const UMegaSettings_Magic S, int Spell)
	{
		switch (Spell)
		{
			case FIRE_BOLT: return Mega::Num(S.FireBoltDamage);
			case FIRE_BALL: return Mega::Num(S.FireBallDamage);
			case PYROKINESIS: return Mega::Num(S.PyrokinesisDamage);
			case STORM_OF_FIRE: return Mega::Num(S.StormOfFireDamage);
			case FIRE_RAIN: return Mega::Num(S.FireRainDamage);
			case ICE_BOLT: return Mega::Num(S.IceBoltDamage);
			case ICE_BLOCK: return Mega::Num(S.IceBlockDamage);
			case ICE_WAVE: return Mega::Num(S.IceWaveDamage);
			case BALL_LIGHTNING: return Mega::Num(S.BallLightningDamage);
			case CHAIN_LIGHTNING: return Mega::Num(S.ChainLightningDamage);
			case URIZIEL: return Mega::Num(S.UrizielDamage);
			case DEATH_TO_THE_UNDEAD: return Mega::Num(S.DeathToTheUndeadDamage);
			case WIND_FIST: return Mega::Num(S.WindFistDamage);
			case STORM_FIST: return Mega::Num(S.StormFistDamage);
			case BREATH_OF_DEATH: return Mega::Num(S.BreathOfDeathDamage);
		}
		return 1.0f;
	}

	float Mana(const UMegaSettings_Magic S, int Spell)
	{
		switch (Spell)
		{
			case FIRE_BOLT: return Mega::Num(S.FireBoltMana);
			case FIRE_BALL: return Mega::Num(S.FireBallMana);
			case PYROKINESIS: return Mega::Num(S.PyrokinesisMana);
			case STORM_OF_FIRE: return Mega::Num(S.StormOfFireMana);
			case FIRE_RAIN: return Mega::Num(S.FireRainMana);
			case ICE_BOLT: return Mega::Num(S.IceBoltMana);
			case ICE_BLOCK: return Mega::Num(S.IceBlockMana);
			case ICE_WAVE: return Mega::Num(S.IceWaveMana);
			case BALL_LIGHTNING: return Mega::Num(S.BallLightningMana);
			case CHAIN_LIGHTNING: return Mega::Num(S.ChainLightningMana);
			case URIZIEL: return Mega::Num(S.UrizielMana);
			case DEATH_TO_THE_UNDEAD: return Mega::Num(S.DeathToTheUndeadMana);
			case WIND_FIST: return Mega::Num(S.WindFistMana);
			case STORM_FIST: return Mega::Num(S.StormFistMana);
			case BREATH_OF_DEATH: return Mega::Num(S.BreathOfDeathMana);
		}
		return 1.0f;
	}

	float CastTime(const UMegaSettings_Magic S, int Spell)
	{
		switch (Spell)
		{
			case FIRE_BOLT: return Mega::Num(S.FireBoltCastTime);
			case FIRE_BALL: return Mega::Num(S.FireBallCastTime);
			case PYROKINESIS: return Mega::Num(S.PyrokinesisCastTime);
			case STORM_OF_FIRE: return Mega::Num(S.StormOfFireCastTime);
			case FIRE_RAIN: return Mega::Num(S.FireRainCastTime);
			case ICE_BOLT: return Mega::Num(S.IceBoltCastTime);
			case ICE_BLOCK: return Mega::Num(S.IceBlockCastTime);
			case ICE_WAVE: return Mega::Num(S.IceWaveCastTime);
			case BALL_LIGHTNING: return Mega::Num(S.BallLightningCastTime);
			case CHAIN_LIGHTNING: return Mega::Num(S.ChainLightningCastTime);
			case URIZIEL: return Mega::Num(S.UrizielCastTime);
			case DEATH_TO_THE_UNDEAD: return Mega::Num(S.DeathToTheUndeadCastTime);
			case STORM_FIST: return Mega::Num(S.StormFistCastTime);
			case BREATH_OF_DEATH: return Mega::Num(S.BreathOfDeathCastTime);
		}
		return 1.0f;
	}

	// The caster's magic circle as a number (0 = below the first).
	int Circle(UGothicAbilitySystemComponent Caster)
	{
		if (!IsValid(Caster))
			return 0;
		if (Caster.HasGameplayTag(GameplayTag::Skill_Mage_Circle_Sixth)) return 6;
		if (Caster.HasGameplayTag(GameplayTag::Skill_Mage_Circle_Fifth)) return 5;
		if (Caster.HasGameplayTag(GameplayTag::Skill_Mage_Circle_Fourth)) return 4;
		if (Caster.HasGameplayTag(GameplayTag::Skill_Mage_Circle_Third)) return 3;
		if (Caster.HasGameplayTag(GameplayTag::Skill_Mage_Circle_Second)) return 2;
		if (Caster.HasGameplayTag(GameplayTag::Skill_Mage_Circle_First)) return 1;
		return 0;
	}

	// A bolt's own damage by the caster's circle (below the 2nd, from the 2nd, the 4th, the 6th).
	float Step(int CasterCircle, int Below2, int From2, int From4, int From6)
	{
		if (CasterCircle >= 6) return From6;
		if (CasterCircle >= 4) return From4;
		if (CasterCircle >= 2) return From2;
		return Below2;
	}

	// The damage of one kind of damage of a hit, as the module wants it.
	float HitDamage(float GameDamage, UGothicAbilitySystemComponent Caster, UWeaponDefinition Weapon)
	{
		const UMegaSettings_Magic S = UMegaSettings_Magic.DefaultObject;
		if (!Mega::On(S.Enabled) || !IsValid(Weapon))
			return GameDamage;
		int Spell = SpellOf(Weapon.Class);
		if (Spell < 0)
			return GameDamage;
		float Base = GameDamage;
		if (Spell == FIRE_BOLT && Mega::On(S.FireBoltSteps))
			Base = Step(Circle(Caster), Mega::Int(S.FireBoltStep0), Mega::Int(S.FireBoltStep2), Mega::Int(S.FireBoltStep4), Mega::Int(S.FireBoltStep6));
		else if (Spell == ICE_BOLT && Mega::On(S.IceBoltSteps))
			Base = Step(Circle(Caster), Mega::Int(S.IceBoltStep0), Mega::Int(S.IceBoltStep2), Mega::Int(S.IceBoltStep4), Mega::Int(S.IceBoltStep6));
		return Base * Mega::Num(S.Damage) * School(S, Spell) * Damage(S, Spell);
	}
}

// The game's damage of a hit, with the spells' damage as the settings want it (the official way to change a game
// class: inheritance injection, ModKit "Script Hooking"). Everything else of the calculation stays the game's.
UCLASS(meta=(ReplaceParentClass))
class UGE_Ex_Damage_MegaMagic : UGE_Ex_Damage
{
	float GetCalculatedDamage(UGothicAbilitySystemComponent SourceAbComp, UGothicAbilitySystemComponent TargetAbComp, TMapIterator<FGameplayTag, float32> Entry, FGameplayEffectSpec Spec, UWeaponDefinition WeaponUsed) const override
	{
		float GameDamage = Super::GetCalculatedDamage(SourceAbComp, TargetAbComp, Entry, Spec, WeaponUsed);
		return MegaMagic::HitDamage(GameDamage, SourceAbComp, WeaponUsed);
	}
}
