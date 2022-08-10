class BIO_Bullet : BIO_Puff
{
	Default
	{
		Decal 'BulletChip';
		Tag "$BIO_BULLET_TAG";
		BIO_Puff.PluralTag "$BIO_BULLET_TAG_PLURAL";
		BIO_Puff.SizeClass BIO_PLSC_XSMALL;
	}
}

class BIO_ShotPellet : BIO_Bullet
{
	Default
	{
		Tag "$BIO_SHOTPELLET_TAG";
		BIO_Puff.PluralTag "$BIO_SHOTPELLET_TAG_PLURAL";
	}
}

class BIO_Slug : BIO_Bullet
{
	Default
	{
		Tag "$BIO_SLUG_TAG";
		BIO_Puff.PluralTag "$BIO_SLUG_TAG_PLURAL";
	}
}

class BIO_MeleeHit : BIO_Puff
{
	Default
	{
		Decal 'BulletChip';
		Tag "$BIO_MELEEHIT_TAG";
		BIO_Puff.PluralTag "$BIO_MELEEHIT_TAG_PLURAL";
	}
}

class BIO_DemoBullet : BIO_Bullet
{
	Default
	{
		+PUFFONACTORS
		Scale 0.2;
		Tag "$BIO_DEMOBULLET_TAG";
		BIO_Puff.PluralTag "$BIO_DEMOBULLET_TAG_PLURAL";
	}

	States
	{
	Spawn:
	Melee:
		MISL B 8 Bright;
		MISL C 6 Bright;
		MISL D 4 Bright;
		Stop;
	}
}

class BIO_DemoShotPellet : BIO_DemoBullet
{
	Default
	{
		Scale 0.1;
		Tag "$BIO_DEMOSHOTPELLET_TAG";
		BIO_Puff.PluralTag "$BIO_DEMOSHOTPELLET_TAG_PLURAL";
	}
}

class BIO_DemoSlug : BIO_DemoBullet
{
	Default
	{
		Tag "$BIO_DEMOSLUG_TAG";
		BIO_Puff.PluralTag "$BIO_DEMOSLUG_TAG_PLURAL";
	}
}

class BIO_CannonShell : BIO_DemoBullet
{
	Default
	{
		+PUFFONACTORS
		Scale 0.5;
		Tag "$BIO_CANNONSHELL_TAG";
		BIO_Puff.PluralTag "$BIO_CANNONSHELL_TAG_PLURAL";
		BIO_Puff.SizeClass BIO_PLSC_MEDIUM;
	}
}

class BIO_ElectricPuff : BIO_RailPuff
{
	Default
	{
		+ALWAYSPUFF
		+PUFFONACTORS

		Decal 'PlasmaScorchLower1';
		RenderStyle 'Add';
		Tag "$BIO_ELECTRICPUFF_TAG_PLURAL";
		VSpeed 0.0;
		BIO_Puff.PluralTag "$BIO_ELECTRICPUFF_TAG_PLURAL";
	}

	States
	{
	Spawn:
		RZAP A 2 Bright Light("BIO_ElecPuff");
		RZAP B 2 Bright Light("BIO_ElecPuff") A_StartSound(
			"bio/puff/lightning/hit",
			Random(0, 1) == 0 ? CHAN_6 : CHAN_7, volume: 0.5
		);
		RZAP CDEFGHI 2 Bright Light("BIO_ElecPuff");
		Stop;
	Melee:
		Goto Spawn;
	}
}

class BIO_Shrapnel : BulletPuff
{
	Default
	{
		+ALLOWTHRUFLAGS
		+MTHRUSPECIES
		+THRUSPECIES
		+THRUGHOST

		Species 'Player';
	}

	final override void PostBeginPlay()
	{
		super.PostBeginPlay();

		if (Deathmatch)
			bMThruSpecies = false;
	}
}

class BIO_PainPuff : BulletPuff
{
	Default
	{
		-ALLOWPARTICLES
		-SOLID
		+ALWAYSPUFF
		+BLOODLESSIMPACT
		+FORCEPAIN
		+MTHRUSPECIES
		+NODECAL
		+PUFFGETSOWNER
		+PUFFONACTORS

		DamageType 'BIO_NullDamage';
		Species 'Player';
	}

	States
	{
	Spawn:
		TNT1 A 0;
		TNT1 A 0 A_Jump(256, 'End');
		Goto End;
	XDeath:
		TNT1 A 0;
		TNT1 A 0 A_Jump(256, 'End');
		Goto End;
	Crash:
		TNT1 A 0;
		TNT1 A 0 A_Jump(256, 'End');
		Goto End;
	End:
		TNT1 A 8;
		Stop;
	}
}

// Miscellaneous ///////////////////////////////////////////////////////////////

class BIO_NullPuff : BulletPuff
{
	Default
	{
		+BLOODLESSIMPACT
		+NODAMAGETHRUST
		+NOTELEPORT
		+PAINLESS
		+THRUACTORS

		Decal '';
	}

	States
	{
	Spawn:
	Melee:
		TNT1 A 5;
		Stop;
	}
}

class BIO_ForceBlast : BIO_Bullet
{
	Default
	{
		+EXTREMEDEATH
		+PUFFONACTORS
		-ALLOWPARTICLES
		Alpha 0.0;
	}
}
