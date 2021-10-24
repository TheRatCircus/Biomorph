class BIO_SuperShotgun : BIO_Weapon replaces SuperShotgun
{
	int FireTime1, FireTime2; property FireTimes: FireTime1, FireTime2;
	int ReloadTime1, ReloadTime2, ReloadTime3;
	property ReloadTimes: ReloadTime1, ReloadTime2, ReloadTime3;

	Default
	{
		Obituary "$OB_MPSSHOTGUN";
		Tag "$TAG_SUPERSHOTGUN";

		Inventory.Icon "SGN2A0";

		Weapon.AmmoGive 8;
		Weapon.AmmoType1 "Shell";
		Weapon.AmmoUse1 1;
		Weapon.SelectionOrder 400;
		Weapon.SlotNumber 3;
		Weapon.UpSound "weapons/gunswap";

		BIO_Weapon.AffixMask BIO_WAM_SECONDARY;
		BIO_Weapon.Grade BIO_GRADE_STANDARD;
		BIO_Weapon.DamageRange 5, 15;
		BIO_Weapon.FireCount 7;
		BIO_Weapon.FireType "BIO_ShotPellet";
		BIO_Weapon.MagazineSize 2;
		BIO_Weapon.MagazineType "BIO_Magazine_SuperShotgun";
		BIO_Weapon.Spread 12.0, 7.5;

		BIO_SuperShotgun.FireTimes 3, 7;
		BIO_SuperShotgun.ReloadTimes 7, 6, 5;
	}

	States
	{
	Ready:
		SHT2 A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Loop;
	Deselect.Loop:
		SHT2 A 1 A_BIO_Lower;
		Loop;
	Select.Loop:
		SHT2 A 1 A_BIO_Raise;
		Loop;
	Fire:
		TNT1 A 0
		{
			if (BIO_CVar.MultiBarrelPrimary(Player))
				return ResolveState("Fire.Double");
			else
				return ResolveState("Fire.Single");
		}
	AltFire:
		TNT1 A 0
		{
			invoker.bAltFire = false;
			if (BIO_CVar.MultiBarrelPrimary(Player))
				return ResolveState("Fire.Single");
			else
				return ResolveState("Fire.Double");
		}
	Fire.Single:
		TNT1 A 0 A_JumpIf(invoker.Magazine1.Amount < 1, "Reload");
		SHT2 A 3 A_SetTics(invoker.FireTime1);
		SHT2 A 7
		{
			A_SetTics(invoker.FireTime2);
			A_BIO_Fire();
			// TODO: Replace with a smaller sound
			A_StartSound("weapons/sshotf", CHAN_WEAPON);
		}
		Goto Ready;
	Fire.Double:
		TNT1 A 0 A_JumpIf(invoker.Magazine1.Amount < 2, "Reload");
		SHT2 A 3 A_SetTics(invoker.FireTime1);
		SHT2 A 7
		{
			A_SetTics(invoker.FireTime2);
			A_BIO_Fire(factor: 2);
			A_StartSound("weapons/sshotf", CHAN_WEAPON);
		}
		Goto Ready;
	Reload:
		TNT1 A 0 A_JumpIf(!invoker.CanReload(), "Ready");
		SHT2 B 7 A_SetTics(invoker.ReloadTime1);
		SHT2 C 7
		{
			A_SetTics(invoker.ReloadTime1);
			A_CheckReload();
		}
		SHT2 D 7
		{
			A_SetTics(invoker.ReloadTime1);
			A_OpenShotgun2();
		}
		SHT2 E 7 A_SetTics(invoker.ReloadTime1);
		SHT2 F 7
		{
			A_LoadMag();
			A_SetTics(invoker.ReloadTime1);
			A_LoadShotgun2();
		}
		SHT2 G 6 A_SetTics(invoker.ReloadTime2);
		SHT2 H 6
		{
			A_SetTics(invoker.ReloadTime2);
			A_CloseShotgun2();
		}
		SHT2 A 5
		{
			A_SetTics(invoker.ReloadTime3);
			A_ReFire();
		}
		Goto Ready;
	Flash:
		SHT2 I 4 Bright A_Light(1);
		SHT2 J 3 Bright A_Light(2);
		Goto LightDone;
	Spawn:
		SGN2 A -1;
		Stop;
	}

	override void GetFireTimes(in out Array<int> fireTimes, bool _) const
	{
		fireTimes.PushV(FireTime1, FireTime2);
	}

	override void SetFireTimes(Array<int> fireTimes, bool _)
	{
		FireTime1 = fireTimes[0];
		FireTime2 = fireTimes[1];
	}

	override void GetReloadTimes(in out Array<int> reloadTimes, bool _) const
	{
		reloadTimes.PushV(ReloadTime1, ReloadTime2, ReloadTime3);
	}

	override void SetReloadTimes(Array<int> reloadTimes, bool _)
	{
		ReloadTime1 = reloadTimes[0];
		ReloadTime2 = reloadTimes[1];
		ReloadTime3 = reloadTimes[2];
	}

	override void ResetStats()
	{
		super.ResetStats();
		let defs = GetDefaultByType(GetClass());

		FireTime1 = defs.FireTime1;
		FireTime2 = defs.FireTime2;

		ReloadTime1 = defs.ReloadTime1;
		ReloadTime2 = defs.ReloadTime2;
		ReloadTime3 = defs.ReloadTime3;
	}

	override void StatsToString(in out Array<string> stats) const
	{
		stats.Push(String.Format(StringTable.Localize("$BIO_WEAPSTAT_FIREDATA"),
			DamageFontColor(),
			MinDamage1, MaxDamage1,
			FireCountFontColor(),
			FireCount1 == -1 ? 1 : FireCount1,
			FireTypeFontColor(),
			GetDefaultByType(FireType1).GetTag()));
		
		stats.Push(String.Format(StringTable.Localize("$BIO_WEAPSTAT_FIRETIME"),
			FireTimeModified() ? CRESC_STATMODIFIED : CRESC_STATUNMODIFIED,
			float(FireTime1 + FireTime2) / 35.0));

		stats.Push(String.Format(StringTable.Localize("$BIO_WEAPSTAT_SPREAD"),
			HSpread1, VSpread1));
	}

	protected bool FireTimeModified() const
	{
		let defs = GetDefaultByType(GetClass());
		return (FireTime1 + FireTime2) != (defs.FireTime1 + defs.FireTime2);
	}
}

class BIO_Magazine_SuperShotgun : Ammo
{
	mixin BIO_Magazine;

	Default
	{
		Inventory.Amount 2;
	}
}
