class biom_Biter : Actor
{
	Default
	{
		Projectile;

		+RANDOMIZE
		+ZDOOMTRANS

		DamageFunction 30;
		DeathSound "weapons/plasmax";
		Decal 'BulletChip';
		Height 8.0;
		Obituary "$BIOM_BITERIFLE_OB";
		Radius 13.0;
		Speed 25.0;
	}

	States
	{
	Spawn:
		BITE A 6;
		loop;
	Death:
		BITE BCDE 2;
		stop;
	}
}

class biom_CasterCannonRailSpawn : Actor
{
	Default
	{
		+NOCLIP
		+NOGRAVITY
		+NOINTERACTION
		+THRUACTORS

		Alpha 0.75;
		Height 4.0;
		RenderStyle 'Add';
		Radius 4.0;
		Scale 0.25;
		Translation "biom_Pink";
	}

	States
	{
	Spawn:
		BFS1 AB 1 bright;
		BFE1 AB 1 bright;
		BFE1 C 1 bright;
		BFE1 DEF 1 bright;
		stop;
	}
}

class biom_CasterCannonRayEmitter : Actor
{
	Default
	{
		Projectile;

		Damage 0;
		Speed 25.0;
		Height 4.0;
		Radius 4.0;
		Species 'Player';

		+NOCLIP
		+THRUACTORS
		+THRUSPECIES
	}

	States
	{
	Death:
	Spawn:
		TNT1 A 1;
		TNT1 A 10
		{
			A_BFGSpray('BFGExtra');
			A_StartSound("biom/particlecast/die", volume: 1.0, attenuation: 0.1);
		}
		stop;
	}
}

class biom_Grenade40mm : Grenade
{
	Default
	{
		-GRENADETRAIL
		+FORCEXYBILLBOARD
		+NOGRAVITY
		+THRUSPECIES
		+THRUGHOST
		+USEBOUNCESTATE

		BounceCount 2;
		BounceFactor 0.25;
		WallBounceFactor 0.5;

		DamageFunction 100;
		DeathSound "weapons/rocklx";
		Decal 'Scorch';
		Gravity 0.65;
		Height 4.0;
		Obituary "$BIOM_MULTIGL_OB";
		Radius 6.0;
		Scale 0.7;
		SeeSound "";
		Speed 35.0;
	}

	States
	{
	Bounce:
		TNT1 A 0 { invoker.bNoGravity = false; }
		goto Spawn;
	Death:
		MISL B 8 bright
		{
			invoker.bNoGravity = true;
			invoker.scale *= 2.0;
			A_Explode(128, 128);
		}
		MISL C 6 bright;
		MISL D 4 bright;
		stop;
	}
}
