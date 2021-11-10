// Abstract and detail classes =================================================

// For details about projectiles that can't be expressed any other way.
enum BIO_ProjectileMetaFlags : uint
{
	BIO_PMF_NONE = 0,
	BIO_PMF_BALLISTIC = 1 << 0,
	BIO_PMF_ENERGY = 1 << 1
}

mixin class BIO_ProjectileCommon
{
	meta string PluralTag; property PluralTag: PluralTag;
	meta BIO_ProjectileMetaFlags MetaFlags; property MetaFlags: MetaFlags;

	int BFGRays; property BFGRays: BFGRays;
	int SplashDamage, SplashRadius; property Splash: SplashDamage, SplashRadius;
	int Shrapnel; property Shrapnel: Shrapnel;

	// These are set by the firing weapon to point to that 
	// weapon's own counterparts of these arrays.
	Array<BIO_ProjDamageFunctor> ProjDamageFunctors;
	Array<BIO_ProjDeathFunctor> ProjDeathFunctors;

	Default
	{
		+BLOODSPLATTER
		+FORCEXYBILLBOARD
		+THRUSPECIES
		+THRUGHOST

		Damage -1;
		Species 'Player';
	}
}

class BIO_Projectile : Actor abstract
{
	mixin BIO_ProjectileCommon;

	float Acceleration; property Acceleration: Acceleration;
	bool Seek; property Seek: Seek;

	// Set by the firing weapon to point to that 
	// weapon's own counterpart of this arrays.
	Array<BIO_ProjTravelFunctor> ProjTravelFunctors;

	Default
	{
		Projectile;

		Tag "$BIO_PROJ_TAG_ROUND";
		
		BIO_Projectile.MetaFlags BIO_PMF_NONE;
		BIO_Projectile.Acceleration 1.0;
		BIO_Projectile.BFGRays 0;
		BIO_Projectile.PluralTag "$BIO_PROJ_TAG_ROUNDS";
		BIO_Projectile.Splash 0, 0;
		BIO_Projectile.Shrapnel 0;
		BIO_Projectile.Seek false;
	}

	// Overriden so projectiles live long enough to receive their data from the
	// weapon which fired them. If `Damage` is still at the default of -1,
	// don't expire quite yet.
	override int SpecialMissileHit(Actor victim)
	{
		// (a.k.a. the part which keeps half this mod from toppling over)
		if (Damage <= -1)
			return 1; // Ignored for now
		else
			return super.SpecialMissileHit(victim);
	}

	// Don't multiply damage by Random(1, 8).
	override int DoSpecialDamage(Actor target, int dmg, name dmgType)
	{
		int ret = Damage;

		for (uint i = 0; i < ProjDamageFunctors.Size(); i++)
			ProjDamageFunctors[i].InvokeTrue(BIO_Projectile(self),
				target, ret, dmgType);

		return ret;
	}

	action void A_Travel()
	{
		for (uint i = 0; i < invoker.ProjTravelFunctors.Size(); i++)
			invoker.ProjTravelFunctors[i].Invoke(BIO_Projectile(self));

		A_ScaleVelocity(invoker.Acceleration);

		if (invoker.Seek) A_SeekerMissile(4.0, 4.0, SMF_LOOK);
	}

	// Invoked before A_ProjectileDeath() does anything else.
	// Note that you never need to call `super.OnProjectileDeath()`.
	virtual void OnProjectileDeath() {}

	action void A_ProjectileDeath()
	{
		invoker.OnProjectileDeath();

		for (uint i = 0; i < invoker.ProjDeathFunctors.Size(); i++)
			invoker.ProjDeathFunctors[i].InvokeTrue(BIO_Projectile(self));

		// TODO: Subtle sound if Shrapnel is >0
		if (invoker.Shrapnel > 0)
		{
			A_Explode(invoker.SplashDamage, invoker.SplashRadius,
				nails: invoker.Shrapnel,
				nailDamage: Max(((invoker.Damage * 3) / invoker.Shrapnel), 0),
				puffType: 'BIO_Shrapnel');
		}
		else
		{
			A_Explode(invoker.SplashDamage, invoker.SplashRadius);
		}
	}
}

class BIO_FastProjectile : FastProjectile abstract
{
	mixin BIO_ProjectileCommon;

	Default
	{
		Tag "$BIO_PROJ_TAG_ROUND";

		BIO_FastProjectile.MetaFlags BIO_PMF_NONE;
		BIO_FastProjectile.BFGRays 0;
		BIO_FastProjectile.PluralTag "$BIO_PROJ_TAG_ROUNDS";
		BIO_FastProjectile.Splash 0, 0;
		BIO_FastProjectile.Shrapnel 0;
	}

	// Don't multiply damage by Random(1, 8).
	override int DoSpecialDamage(Actor target, int dmg, name dmgType)
	{
		int ret = Damage;

		for (uint i = 0; i < ProjDamageFunctors.Size(); i++)
			ProjDamageFunctors[i].InvokeFast(BIO_FastProjectile(self),
				target, ret, dmgType);

		return ret;
	}

	// Invoked before the A_ProjectileDeath does anything else.
	// Note that you never need to call `super.OnProjectileDeath()`.
	virtual void OnProjectileDeath() {}

	action void A_ProjectileDeath()
	{
		invoker.OnProjectileDeath();
		
		for (uint i = 0; i < invoker.ProjDeathFunctors.Size(); i++)
			invoker.ProjDeathFunctors[i].InvokeFast(BIO_FastProjectile(self));

		// TODO: Subtle sound if Shrapnel is >0
		if (invoker.Shrapnel > 0)
		{
			A_Explode(invoker.SplashDamage, invoker.SplashRadius,
				nails: invoker.Shrapnel,
				nailDamage: Max(((invoker.Damage * 3) / invoker.Shrapnel), 0),
				puffType: 'BIO_Shrapnel');
		}
		else
		{
			A_Explode(invoker.SplashDamage, invoker.SplashRadius);
		}
	}
}

class BIO_ProjTravelFunctor abstract
{
	abstract void Invoke(BIO_Projectile proj);
}

class BIO_ProjDamageFunctor abstract
{
	virtual void InvokeTrue(BIO_Projectile proj,
		Actor target, in out int damage, name dmgType) const {}
	virtual void InvokeFast(BIO_FastProjectile proj,
		Actor target, in out int damage, name dmgType) const {}
}

class BIO_ProjDeathFunctor abstract
{
	virtual void InvokeTrue(BIO_Projectile proj) const {}
	virtual void InvokeFast(BIO_FastProjectile proj) const {}
}

// Fast projectiles (used like puffs) ==========================================

class BIO_Bullet : BIO_FastProjectile
{
	Default
	{
		Alpha 1.0;
		Decal 'BulletChip';
		Height 1;
		Radius 1;
		Speed 400;
		Tag "$BIO_PROJ_TAG_BULLET";

		BIO_FastProjectile.MetaFlags BIO_PMF_BALLISTIC;
		BIO_FastProjectile.PluralTag "$BIO_PROJ_TAG_BULLETS";
	}

	States
	{
	Spawn:
		TNT1 A 1;
		Loop;
	Death:
		TNT1 A 1 A_ProjectileDeath;
		Stop;
	}

	override void OnProjectileDeath()
	{
		A_SpawnItemEx('BulletPuff', flags: SXF_NOCHECKPOSITION);
	}
}

class BIO_ShotPellet : BIO_Bullet
{
	Default
	{
		Tag "$BIO_PROJ_TAG_SHOTPELLET";
		BIO_FastProjectile.PluralTag "$BIO_PROJ_TAG_SHOTPELLETS";
	}
}

class BIO_Slug : BIO_Bullet
{
	Default
	{
		Tag "$BIO_PROJ_TAG_SLUG";
		BIO_FastProjectile.PluralTag "$BIO_PROJ_TAG_SLUGS";
	}
}

// True projectiles ============================================================

class BIO_Rocket : BIO_Projectile
{
	Default
	{
		+DEHEXPLOSION
		+RANDOMIZE
		+ROCKETTRAIL
		+ZDOOMTRANS

		DeathSound "weapons/rocklx";
		Height 8;
		Obituary "$OB_MPROCKET";
		Radius 11;
		SeeSound "weapons/rocklf";
		Speed 20;
		Tag "$BIO_PROJ_TAG_ROCKET";

		BIO_Projectile.PluralTag "$BIO_PROJ_TAG_ROCKETS";
		BIO_Projectile.Splash 128, 128;
	}

	States
	{
	Spawn:
		MISL A 1 Bright A_Travel;
		Loop;
	Death:
		MISL B 8 Bright A_ProjectileDeath;
		MISL C 6 Bright;
		MISL D 4 Bright;
		Stop;
	BrainExplode:
		MISL BC 10 Bright;
		MISL D 10 A_BrainExplode;
		Stop;
	}
}

class BIO_MiniMissile : BIO_Rocket
{
	Default
	{
		Tag "$BIO_PROJ_TAG_MINIMISSILE";

		Height 2;
		Radius 3;
		Scale 0.3;
		Speed 50;

		BIO_Projectile.PluralTag "$BIO_PROJ_TAG_MINIMISSILES";
		BIO_Projectile.Splash 32, 32;
	}
}

class BIO_PlasmaBall : BIO_Projectile
{
	Default
	{
		+RANDOMIZE
		+ZDOOMTRANS

		Alpha 0.75;
		DeathSound "weapons/plasmax";
		Height 8;
		Obituary "$OB_MPPLASMARIFLE";
		Radius 13;
		RenderStyle 'Add';
		SeeSound "weapons/plasmaf";
		Speed 25;
		Tag "$BIO_PROJ_TAG_PLASMABALL";

		BIO_Projectile.PluralTag "$BIO_PROJ_TAG_PLASMABALLS";
		BIO_Projectile.MetaFlags BIO_PMF_ENERGY;
	}

	States
	{
	Spawn:
		PLSS A 3 Bright A_Travel;
		#### # 3 Bright A_Travel;
		PLSS B 3 Bright A_Travel;
		#### # 3 Bright A_Travel;
		Loop;
	Death:
		TNT1 A 0 A_ProjectileDeath;
		PLSE ABCDE 4 Bright;
		Stop;
	}
}

class BIO_BFGBall : BIO_Projectile
{
	int MinRayDamage, MaxRayDamage;
	property RayDamageRange: MinRayDamage, MaxRayDamage;

	Default
	{
		+RANDOMIZE
		+ZDOOMTRANS

		Alpha 0.75;
		DeathSound "weapons/bfgx";
		Height 8;
		Obituary "$OB_MPBFG_BOOM";
		Radius 13;
		RenderStyle 'Add';
		Speed 25;
		Tag "$BIO_PROJ_TAG_BFGBALL";

		BIO_Projectile.PluralTag "$BIO_PROJ_TAG_BFGBALLS";
		BIO_Projectile.MetaFlags BIO_PMF_ENERGY;
		BIO_BFGBall.RayDamageRange 15, 120;
	}

	States
	{
	Spawn:
		BFS1 A 3 Bright A_Travel;
		#### # 3 Bright A_Travel;
		BFS1 B 3 Bright A_Travel;
		#### # 3 Bright A_Travel;
		Loop;
	Death:
		BFE1 AB 8 Bright;
		BFE1 C 8 Bright A_ProjectileDeath;
		BFE1 DEF 8 Bright;
		Stop;
	}

	override void OnProjectileDeath()
	{
		A_BFGSpray(numRays: BFGRays, defDamage: Random(MinRayDamage, MaxRayDamage));
	}
}

class BIO_PlasmaGlobule : BIO_PlasmaBall
{
	Default
	{
		Tag "$BIO_PROJ_TAG_PLASMAGLOBULE";
		Scale 0.4;

		BIO_Projectile.PluralTag "$BIO_PROJ_TAG_PLASMAGLOBULES";
		BIO_Projectile.Splash 48, 48;
	}

	States
	{
	Spawn:
		GLOB A 3 Bright
		{
			A_Travel();
			A_SpawnItemEx('BIO_PlasmaGlobuleTrail');
		}
		Loop;
	Death:
		TNT1 A 0 A_ProjectileDeath;
		GLOB BCDE 4 Bright;
		Stop;
	}
}

// Projectile-adjacent actors ==================================================

class BIO_MeleeHit : BulletPuff
{
	Default
	{
		Tag "$BIO_MELEE_HIT";
	}

	string CountBasedTag(int count) const
	{
		switch (count)
		{
		case -1:
		case 1: return GetTag();
		default: return StringTable.Localize("$BIO_MELEE_HITS");
		}
	}
}

class BIO_Shrapnel : BulletPuff
{
	Default
	{
		+ALLOWTHRUFLAGS
		+MTHRUSPECIES
		+THRUGHOST
	}

	override void PostBeginPlay()
	{
		super.PostBeginPlay();
		if (Deathmatch) bMTHRUSPECIES = false;
	}
}

class BIO_BFGExtra : BFGExtra
{
	Default
	{
		Tag "$BIO_PROJEXTRA_TAG_BFGRAY";
	}
}

class BIO_PlasmaGlobuleTrail : Actor
{
	Default
	{
		+NOINTERACTION

		Alpha 0.6;
		RenderStyle 'Add';
		Scale 0.4;
	}

	States
	{
	Spawn:
		GLOT A 6 Bright;
		GLOT B 4 Bright;
		GLOT C 2 Bright;
		Stop;
	}
}
