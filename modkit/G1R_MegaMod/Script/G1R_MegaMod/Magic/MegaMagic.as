// MegaMod - magic balancing (port of the UE4SS module magic).
// This is an unofficial modification. It is not made, endorsed or supported by THQ Nordic.
//
// Damage is changed at the moment of a hit (MegaMagicRules.as). Everything else lives in the class defaults of the
// spells, which the game reads when a spell is cast: the levels of a spell config (mana, casting time, mana a second
// while held), its reach, a definition's flight speed and force against a foe's stance, the heal spell's amounts, the
// ice hits' freezing flag and the price of the magic circles. Every two seconds the module writes what the settings
// ask for, always from the game's own numbers (kept in UMegaMemory for the whole game); with a setting back at its
// neutral value the game's number is back.

class UMegaMagic : UGothicModExt_WorldSubsystem
{
	const float LOOK_SECONDS = 2.0f;

	FTimerHandle Timer;
	int Writes = 0;

	UFUNCTION(BlueprintOverride)
	void HandleReadyForPlay()
	{
		Timer = System::SetTimer(this, n"Look", LOOK_SECONDS, true);
		Look();
	}

	UFUNCTION()
	void Look()
	{
		const UMegaSettings_Magic S = UMegaSettings_Magic.DefaultObject;
		UMegaMemory Memory = UMegaMemory::Get();
		if (!IsValid(Memory))
			return;
		bool On = Mega::On(S.Enabled);
		int Before = Writes;

		for (int Spell = 0; Spell < MegaMagic::SPELLS; Spell++)
		{
			float ManaFactor = On ? Mega::Num(S.ManaCost) * MegaMagic::Mana(S, Spell) : 1.0f;
			float TimeFactor = On ? Mega::Num(S.CastTime) * MegaMagic::CastTime(S, Spell) : 1.0f;
			float RangeFactor = On ? Mega::Num(S.Range) : 1.0f;
			Config(Memory, MegaMagic::ConfigClass(Spell), ManaFactor, TimeFactor, RangeFactor, Mega::On(S.WholeMana));

			TArray<UClass> Definitions = MegaMagic::Definitions(Spell);
			for (UClass C : Definitions)
			{
				float SpeedFactor = 1.0f;
				float OwnSpeed = 0.0f;
				float StanceFactor = 1.0f;
				if (On)
				{
					if (MegaMagic::Flies(Spell))
						SpeedFactor = Mega::Num(S.ProjectileSpeed);
					if (Spell == MegaMagic::BALL_LIGHTNING)
						OwnSpeed = Mega::Int(S.BallLightningSpeed);
					StanceFactor = Mega::Num(S.Stagger) * (Spell == MegaMagic::WIND_FIST ? Mega::Num(S.WindFistStagger) : 1.0f);
				}
				Definition(Memory, C, SpeedFactor, OwnSpeed, StanceFactor);
			}
		}
		// spells without damage: the multipliers for all spells
		TArray<UClass> Others;
		Others.Add(UHealSpellConfig::StaticClass());
		Others.Add(ULightSpellConfig::StaticClass());
		Others.Add(USleepSpellConfig::StaticClass());
		Others.Add(UCharmSpellConfig::StaticClass());
		Others.Add(UTelekinesisSpellConfig::StaticClass());
		Others.Add(UControlSpellConfig::StaticClass());
		Others.Add(UFearSpellConfig::StaticClass());
		Others.Add(UShrinkSpellConfig::StaticClass());
		Others.Add(UInnosPraySpellConfig::StaticClass());
		for (UClass C : Others)
			Config(Memory, C, On ? Mega::Num(S.ManaCost) : 1.0f, On ? Mega::Num(S.CastTime) : 1.0f, On ? Mega::Num(S.Range) : 1.0f, Mega::On(S.WholeMana));

		Heal(Memory, On ? Mega::Num(S.HealAmount) : 1.0f);
		Freeze(Memory, UGE_IceBolt_Damage::StaticClass(), On && Mega::On(S.IceBoltFreeze));
		Freeze(Memory, UGE_IceBlock_Freeze_Damage::StaticClass(), On && Mega::On(S.IceBlockFreeze));
		Freeze(Memory, UGE_IceWave_Freeze_Damage::StaticClass(), On && Mega::On(S.IceWaveFreeze));

		bool Prices = On && Mega::On(S.CircleCosts);
		Price(Memory, UGE_Skill_Mage_Circle_Amateur::StaticClass(), Prices, Mega::Int(S.CircleCostBasics));
		Price(Memory, UGE_Skill_Mage_Circle_1::StaticClass(), Prices, Mega::Int(S.CircleCost1));
		Price(Memory, UGE_Skill_Mage_Circle_2::StaticClass(), Prices, Mega::Int(S.CircleCost2));
		Price(Memory, UGE_Skill_Mage_Circle_3::StaticClass(), Prices, Mega::Int(S.CircleCost3));
		Price(Memory, UGE_Skill_Mage_Circle_4::StaticClass(), Prices, Mega::Int(S.CircleCost4));
		Price(Memory, UGE_Skill_Mage_Circle_5::StaticClass(), Prices, Mega::Int(S.CircleCost5));
		Price(Memory, UGE_Skill_Mage_Circle_6::StaticClass(), Prices, Mega::Int(S.CircleCost6));

		if (Writes != Before && Mega::On(S.ShowMessage))
			Mega::Note("magic", "Magic: the changed settings are in the game");
	}

	// A number written only when it differs (no write, no count otherwise).
	float Wanted(float Original, float Factor, bool Whole)
	{
		float V = Original * Factor;
		if (Whole)
		{
			float R = Math::RoundToInt(V);
			if (R == 0.0f && V > 0.0f)
				R = 1.0f;            // only a multiplier of 0 makes a spell free
			return R;
		}
		return V;
	}

	void Note(FString Place, float From, float To)
	{
		Writes++;
		if (Mega::On(UMegaSettings_Magic.DefaultObject.LogChanges))
			Mega::Say("magic", f"{Place}: {From} -> {To}");
	}

	void Config(UMegaMemory Memory, UClass C, float ManaFactor, float TimeFactor, float RangeFactor, bool WholeMana)
	{
		if (C == nullptr)
			return;
		USpellConfig Cfg = Cast<USpellConfig>(C.GetDefaultObject());
		if (!IsValid(Cfg))
			return;
		FString Name = C.GetName().ToString();
		for (int i = 0; i < Cfg.m_SpellLevels.Num(); i++)
		{
			float Mana = Memory.Original(f"{Name}.mana{i}", Cfg.m_SpellLevels[i].CastManaCost);
			float Time = Memory.Original(f"{Name}.time{i}", Cfg.m_SpellLevels[i].CastTime);
			float Held = Memory.Original(f"{Name}.held{i}", Cfg.m_SpellLevels[i].ManaCostSc);
			float WantMana = Wanted(Mana, ManaFactor, WholeMana && ManaFactor != 1.0f);
			float WantTime = Wanted(Time, TimeFactor, false);
			float WantHeld = Wanted(Held, ManaFactor, WholeMana && ManaFactor != 1.0f);
			if (Math::Abs(Cfg.m_SpellLevels[i].CastManaCost - WantMana) > 0.0001f)
			{
				Note(f"{Name} mana{i}", Cfg.m_SpellLevels[i].CastManaCost, WantMana);
				Cfg.m_SpellLevels[i].CastManaCost = WantMana;
			}
			if (Math::Abs(Cfg.m_SpellLevels[i].CastTime - WantTime) > 0.0001f)
			{
				Note(f"{Name} time{i}", Cfg.m_SpellLevels[i].CastTime, WantTime);
				Cfg.m_SpellLevels[i].CastTime = WantTime;
			}
			if (Math::Abs(Cfg.m_SpellLevels[i].ManaCostSc - WantHeld) > 0.0001f)
			{
				Note(f"{Name} held{i}", Cfg.m_SpellLevels[i].ManaCostSc, WantHeld);
				Cfg.m_SpellLevels[i].ManaCostSc = WantHeld;
			}
		}
		if (Reach(C))
		{
			float Range = Memory.Original(f"{Name}.range", Cfg.m_AreaRange);
			float WantRange = Range * RangeFactor;
			if (Math::Abs(Cfg.m_AreaRange - WantRange) > 0.01f)
			{
				Note(f"{Name} range", Cfg.m_AreaRange, WantRange);
				Cfg.m_AreaRange = WantRange;
			}
		}
	}

	// The configs whose reach the game's scripts use for the spell itself (target spells; the radius of storm fist,
	// death to the undead and Uriziel's wave). Other spells take their area from what they spawn.
	bool Reach(UClass C)
	{
		return C == UPyrokinesisSpellConfig::StaticClass() || C == UChainLightningSpellConfig::StaticClass()
			|| C == UHealSpellConfig::StaticClass() || C == USleepSpellConfig::StaticClass()
			|| C == UCharmSpellConfig::StaticClass() || C == UShrinkSpellConfig::StaticClass()
			|| C == UTelekinesisSpellConfig::StaticClass() || C == UControlSpellConfig::StaticClass()
			|| C == UStormFistSpellConfig::StaticClass() || C == UDeathToTheUndeadSpellConfig::StaticClass()
			|| C == UUrizielWaveOfDeathSpellConfig::StaticClass();
	}

	void Definition(UMegaMemory Memory, UClass C, float SpeedFactor, float OwnSpeed, float StanceFactor)
	{
		UWeaponDefinition Def = Cast<UWeaponDefinition>(C.GetDefaultObject());
		if (!IsValid(Def))
			return;
		FString Name = C.GetName().ToString();
		float Stance = Memory.Original(f"{Name}.stance", Def.m_SuperArmorDamageBase);
		float WantStance = Stance * StanceFactor;
		if (Math::Abs(Def.m_SuperArmorDamageBase - WantStance) > 0.001f)
		{
			Note(f"{Name} stance", Def.m_SuperArmorDamageBase, WantStance);
			Def.m_SuperArmorDamageBase = WantStance;
		}
		USpellProjectileDefinition Projectile = Cast<USpellProjectileDefinition>(Def);
		if (!IsValid(Projectile))
			return;
		float Speed = Memory.Original(f"{Name}.speed", Projectile.m_Speed);
		float WantSpeed = (OwnSpeed > 0.0f ? OwnSpeed : Speed) * SpeedFactor;
		if (Math::Abs(Projectile.m_Speed - WantSpeed) > 0.01f)
		{
			Note(f"{Name} speed", Projectile.m_Speed, WantSpeed);
			Projectile.m_Speed = WantSpeed;
		}
	}

	void Heal(UMegaMemory Memory, float Factor)
	{
		UHealSpellConfig Cfg = Cast<UHealSpellConfig>(UHealSpellConfig::StaticClass().GetDefaultObject());
		if (!IsValid(Cfg))
			return;
		TArray<FGameplayTag> Circles;
		for (auto Entry : Cfg.m_HealAmountByMagicCircle)
			Circles.Add(Entry.Key);
		for (FGameplayTag Circle : Circles)
		{
			float Have = Cfg.m_HealAmountByMagicCircle[Circle];
			float Want = Memory.Original(f"HealSpellConfig.heal.{Circle.ToString()}", Have) * Factor;
			if (Math::Abs(Have - Want) > 0.001f)
			{
				Note(f"heal {Circle.ToString()}", Have, Want);
				Cfg.m_HealAmountByMagicCircle.Add(Circle, Want);
			}
		}
	}

	void Freeze(UMegaMemory Memory, UClass C, bool Always)
	{
		UGE_Damage Effect = Cast<UGE_Damage>(C.GetDefaultObject());
		if (!IsValid(Effect))
			return;
		FString Name = C.GetName().ToString();
		for (int i = 0; i < Effect.m_ElementalEffectStacks.Num(); i++)
		{
			bool Game = Memory.OriginalFlag(f"{Name}.force{i}", Effect.m_ElementalEffectStacks[i].ForceOverflowElementalEffectStack);
			bool Want = Always || Game;
			if (Effect.m_ElementalEffectStacks[i].ForceOverflowElementalEffectStack != Want)
			{
				Writes++;
				Effect.m_ElementalEffectStacks[i].ForceOverflowElementalEffectStack = Want;
			}
		}
	}

	void Price(UMegaMemory Memory, UClass C, bool Own, int Points)
	{
		UGameplayEffect_SkillGeneric Skill = Cast<UGameplayEffect_SkillGeneric>(C.GetDefaultObject());
		if (!IsValid(Skill))
			return;
		FString Name = C.GetName().ToString();
		float Game = Memory.Original(f"{Name}.price", Skill.m_SPCost);
		float Want = Own ? Points : Game;
		if (Math::Abs(Skill.m_SPCost - Want) > 0.001f)
		{
			Note(f"{Name} price", Skill.m_SPCost, Want);
			Skill.m_SPCost = Want;
		}
	}
}
