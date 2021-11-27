class BIO_FireFunctor play abstract
{
	virtual void Init() {} // Use only for setting defaults.

	abstract Actor Invoke(BIO_NewWeapon weap, in out BIO_FireData fireData) const;

	// Output is fully localized.
	protected static string FireTypeTag(Class<Actor> fireType, int count)
	{
		if (fireType is 'BIO_Projectile')
		{
			let defs = GetDefaultByType((Class<BIO_Projectile>)(fireType));

			switch (count)
			{
			case -1:
			case 1: return defs.GetTag();
			default: return StringTable.Localize(defs.PluralTag);
			}
		}
		else if (fireType is 'BIO_FastProjectile')
		{
			let defs = GetDefaultByType((Class<BIO_FastProjectile>)(fireType));
		
			switch (count)
			{
			case -1:
			case 1: return defs.GetTag();
			default: return StringTable.Localize(defs.PluralTag);
			}
		}
		else if (fireType is 'BIO_RailPuff')
		{
			let defs = GetDefaultByType((Class<BIO_RailPuff>)(fireType));

			switch (count)
			{
			case -1:
			case 1: return defs.GetTag();
			default: return StringTable.Localize(defs.PluralTag);
			}
		}
		else if (fireType is 'BIO_RailSpawn')
		{
			let defs = GetDefaultByType((Class<BIO_RailSpawn>)(fireType));

			switch (count)
			{
			case -1:
			case 1: return defs.GetTag();
			default: return StringTable.Localize(defs.PluralTag);
			}
		}
		else
			return StringTable.Localize(GetDefaultByType(fireType).GetTag());
	}

	abstract string ToString(
		readOnly<BIO_WeaponPipeline> ppl,
		readOnly<BIO_WeaponPipeline> pplDef) const;

	readOnly<BIO_FireFunctor> AsConst() const { return self; }
}

class BIO_FireFunc_Default : BIO_FireFunctor
{
	override Actor Invoke(BIO_NewWeapon weap, in out BIO_FireData fireData) const
	{
		return weap.BIO_FireProjectile(fireData.FireType,
			angle: fireData.Angle + FRandom(-fireData.HSpread, fireData.HSpread),
			pitch: fireData.Pitch + FRandom(-fireData.VSpread, fireData.VSpread)
		);
	}

	override string ToString(
		readOnly<BIO_WeaponPipeline> ppl,
		readOnly<BIO_WeaponPipeline> pplDef) const
	{
		int fc = ppl.GetFireCount();
		Class<Actor> ft = ppl.GetFireType();
		let myDefs = BIO_FireFunc_Default(pplDef.GetFireFunctorConst());

		return String.Format(
			StringTable.Localize("$BIO_WEAP_FIREFUNC_DEFAULT"),
			BIO_Utils.StatFontColor(fc, pplDef.GetFireCount()), fc,
			ft != pplDef.GetFireType() ? CRESC_STATMODIFIED : CRESC_STATDEFAULT,
			FireTypeTag(ft, fc));
	}
}

class BIO_FireFunc_Bullet : BIO_FireFunctor
{
	int NumBullets, Flags;

	override void Init()
	{
		NumBullets = -1;
		Flags = FBF_NORANDOM | FBF_NOFLASH;
	}

	override Actor Invoke(BIO_NewWeapon weap, in out BIO_FireData fireData) const
	{
		weap.A_FireBullets(fireData.HSpread, fireData.VSpread,
			NumBullets, fireData.Damage, fireData.FireType, Flags);
		return null;
	}

	override string ToString(
		readOnly<BIO_WeaponPipeline> ppl,
		readOnly<BIO_WeaponPipeline> pplDef) const
	{
		int fc = ppl.GetFireCount();
		Class<Actor> ft = ppl.GetFireType();

		return String.Format(
			StringTable.Localize("$BIO_WEAP_FIREFUNC_DEFAULT"),
			BIO_Utils.StatFontColor(fc, pplDef.GetFireCount()), fc,
			ft != pplDef.GetFireType() ? CRESC_STATMODIFIED : CRESC_STATDEFAULT,
			FireTypeTag(ft, fc));
	}
}

class BIO_FireFunc_Rail : BIO_FireFunctor
{
	int Flags;
	color Color1, Color2;

	override Actor Invoke(BIO_NewWeapon weap, in out BIO_FireData fireData) const
	{
		Class<Actor> puff_t = null, spawnClass = null;

		if (fireData.FireType is 'BIO_RailPuff')
		{
			puff_t = fireData.FireType;
			spawnClass = GetDefaultByType(
				(Class<BIO_RailPuff>)(fireData.FireType)).SpawnClass;
		}
		else if (fireData.FireType is 'BIO_RailSpawn')
		{
			spawnClass = fireData.FireType;
			puff_t = GetDefaultByType(
				(Class<BIO_RailSpawn>)(fireData.FireType)).PuffType;
		}

		weap.A_RailAttack(fireData.Damage,
			spawnOfs_xy: fireData.Angle,
			useAmmo: false,
			color1: Color1,
			color2: Color2,
			flags: Flags,
			puffType: puff_t,
			spread_xy: fireData.HSpread,
			spread_z: fireData.VSpread,
			spawnClass: spawnClass,
			spawnOfs_z: fireData.Pitch
		);

		return null;
	}

	override string ToString(
		readOnly<BIO_WeaponPipeline> ppl,
		readOnly<BIO_WeaponPipeline> pplDef) const
	{
		Class<Actor> ft = ppl.GetFireType(), puff_t = null, spawnClass = null;
		bool defaultPuff = true, defaultSpawn = true;
		int fc = ppl.GetFireCount();

		if (ft is 'BIO_RailPuff')
		{
			puff_t = ft;
			spawnClass = GetDefaultByType((Class<BIO_RailPuff>)(ft)).SpawnClass;
			defaultPuff = puff_t == pplDef.GetFireType();
		}
		else if (ft is 'BIO_RailSpawn')
		{
			spawnClass = ft;
			puff_t = GetDefaultByType((Class<BIO_RailSpawn>)(ft)).PuffType;
			defaultSpawn = spawnClass == pplDef.GetFireType();
		}

		if (puff_t != null && spawnClass != null)
		{
			return String.Format(
				StringTable.Localize("$BIO_WEAP_FIREFUNC_RAIL"),
				BIO_Utils.StatFontColor(fc, pplDef.GetFireCount()), fc,
				defaultPuff ? CRESC_STATDEFAULT : CRESC_STATMODIFIED,
				FireTypeTag(puff_t, fc),
				defaultSpawn ? CRESC_STATDEFAULT : CRESC_STATMODIFIED,
				FireTypeTag(spawnClass, fc));
		}
		else if (puff_t == null)
		{
			return String.Format(
				StringTable.Localize("$BIO_WEAP_FIREFUNC_RAIL_NOPUFF"),
				BIO_Utils.StatFontColor(fc, pplDef.GetFireCount()), fc,
				defaultSpawn ? CRESC_STATDEFAULT : CRESC_STATMODIFIED,
				FireTypeTag(spawnClass, fc));
		}
		else if (spawnClass == null)
		{
			return String.Format(
				StringTable.Localize("$BIO_WEAP_FIREFUNC_RAIL_NOSPAWN"),
				BIO_Utils.StatFontColor(fc, pplDef.GetFireCount()), fc,
				defaultPuff ? CRESC_STATDEFAULT : CRESC_STATMODIFIED,
				FireTypeTag(puff_t, fc));
		}
		else
		{
			return String.Format(
				StringTable.Localize("$BIO_WEAP_FIREFUNC_RAIL_NOTHING"),
				BIO_Utils.StatFontColor(fc, pplDef.GetFireCount()), fc);
		}
	}
}

class BIO_FireFunc_Melee : BIO_FireFunctor abstract
{
	float Range, Lifesteal;
}

class BIO_FireFunc_Fist : BIO_FireFunc_Melee
{
	override Actor Invoke(BIO_NewWeapon weap, in out BIO_FireData fireData) const
	{
		FTranslatedLineTarget t;

		if (weap.Owner.FindInventory('PowerStrength', true))
			fireData.Damage *= 10;
		
		double ang = weap.Owner.Angle + Random2[Punch]() * (5.625 / 256);
		double ptch = weap.AimLineAttack(ang, Range, null, 0.0, ALF_CHECK3D);

		Actor puff = null;
		int actualDmg = -1;

		[puff, actualDmg] = weap.LineAttack(ang, Range, ptch, fireData.Damage,
			'Melee', fireData.FireType, LAF_ISMELEEATTACK, t);

		// Turn to face target
		if (t.LineTarget)
		{
			weap.Owner.A_StartSound("*fist", CHAN_WEAPON);
			weap.Owner.Angle = t.AngleFromSource;
			if (!t.lineTarget.bDontDrain)
				weap.ApplyLifeSteal(Lifesteal, actualDmg);
		}

		return null;
	}

	override string ToString(
		readOnly<BIO_WeaponPipeline> ppl,
		readOnly<BIO_WeaponPipeline> pplDef) const
	{
		return StringTable.Localize("$BIO_WEAP_FIREFUNC_FIST");
	}
}

class BIO_FireFunc_Chainsaw : BIO_FireFunc_Melee
{
	override Actor Invoke(BIO_NewWeapon weap, in out BIO_FireData fireData) const
	{
		weap.BIO_Saw(fireData.FireType, fireData.Damage,
			Range, fireData.Angle, Lifesteal);

		return null;
	}

	override string ToString(
		readOnly<BIO_WeaponPipeline> ppl,
		readOnly<BIO_WeaponPipeline> pplDef) const
	{
		return StringTable.Localize("$BIO_WEAP_FIREFUNC_CHAINSAW");
	}
}
