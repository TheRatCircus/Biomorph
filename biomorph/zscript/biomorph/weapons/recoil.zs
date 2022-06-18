class BIO_RecoilThinker : Thinker abstract
{
	protected BIO_Weapon Weapon;
	protected int Lifetime, TimeToLive;
	protected float Scale;

	abstract float GetPitch(int lifeTic) const;

	static BIO_RecoilThinker Create(
		class<BIO_RecoilThinker> type, BIO_Weapon weap,
		float scale = 1.0, bool invert = false)
	{
		let ret = BIO_RecoilThinker(new(type));
		ret.Weapon = weap;
		ret.Scale = scale;
		if (invert) ret.Scale = -ret.Scale;
		return ret;
	}

	override void Tick()
	{
		super.Tick();

		if (Lifetime >= TimeToLive || Weapon == null || Weapon.Owner == null)
		{
			if (!bDestroyed) Destroy();
			return;
		}

		Weapon.Owner.Pitch += (GetPitch(Lifetime++) * Scale);
	}
}

mixin class BIO_Recoil_Impl
{
	final override void PostBeginPlay()
	{
		super.PostBeginPlay();
		TimeToLive = PITCH_VALUES.Size();
	}

	final override float GetPitch(int lifeTic) const
	{
		return PITCH_VALUES[lifeTic];
	}
}

////////////////////////////////////////////////////////////////////////////////
// Assume all values henceforth have been stolen from Yholl's DRLA

class BIO_Recoil_Handgun : BIO_RecoilThinker
{
	static const float[] PITCH_VALUES = {
		-0.8, -0.1, 0.15, 0.3, 0.35, 0.07, 0.02, 0.01
	};

	mixin BIO_Recoil_Impl;
}

class BIO_Recoil_HandCannon : BIO_RecoilThinker
{
	static const float[] PITCH_VALUES = {
		-1.3, -0.1, 0.15, 0.3, 0.65, 0.27, 0.02, 0.01
	};

	mixin BIO_Recoil_Impl;
}

class BIO_Recoil_Shotgun : BIO_RecoilThinker
{
	static const float[] PITCH_VALUES = {
		-1.4, -0.1, 0.15, 0.65, 0.5, 0.17, 0.02, 0.01
	};

	mixin BIO_Recoil_Impl;
}

class BIO_Recoil_DoubleShotgun : BIO_RecoilThinker
{
	static const float[] PITCH_VALUES = {
		-2.3, -0.1, 0.05, 1.25, 0.7, 0.37, 0.03
	};

	mixin BIO_Recoil_Impl;
}

class BIO_Recoil_Autogun : BIO_RecoilThinker
{
	static const float[] PITCH_VALUES = {
		-0.45, 0.05, 0.35
	};

	mixin BIO_Recoil_Impl;
}

class BIO_Recoil_RapidFire : BIO_RecoilThinker
{
	static const float[] PITCH_VALUES = {
		-0.2, 0.2
	};

	mixin BIO_Recoil_Impl;
}

class BIO_Recoil_RocketLauncher : BIO_RecoilThinker
{
	static const float[] PITCH_VALUES = {
		-2.55, -0.45, 0.05, 1.04, 0.7, 0.39, 0.31, 0.25, 0.2, 0.07, 0.01
	};

	mixin BIO_Recoil_Impl;
}

class BIO_Recoil_BFG : BIO_RecoilThinker
{
	static const float[] PITCH_VALUES = {
		-2.75, -0.5, 0.05, 1.25, 0.7, 0.43, 0.3, 0.29, 0.18, 0.05
	};

	mixin BIO_Recoil_Impl;
}

class BIO_Recoil_VolleyGun : BIO_RecoilThinker
{
	static const float[] PITCH_VALUES = {
		-4.6, -0.2, 0.1, 2.5, 1.4, 0.74, 0.06
	};

	mixin BIO_Recoil_Impl;
}

class BIO_Recoil_ShotgunPump : BIO_RecoilThinker
{
	static const float[] PITCH_VALUES = {
		0.05, 0.23, 0.08, -0.06, -0.28, -0.02
	};

	mixin BIO_Recoil_Impl;
}

class BIO_Recoil_Reload : BIO_RecoilThinker
{
	static const float[] PITCH_VALUES = {
		-0.45, -0.1, -0.08, -0.05, 0.1, 0.05, 0.02, 0.01
	};

	mixin BIO_Recoil_Impl;
}

class BIO_Recoil_ReloadSSG : BIO_RecoilThinker
{
	static const float[] PITCH_VALUES = {
		0.25, 0.1, 0.05, -0.25, -0.1, -0.05
	};

	mixin BIO_Recoil_Impl;
}

class BIO_Recoil_HeavyReload : BIO_RecoilThinker
{
	static const float[] PITCH_VALUES = {
		-0.85, -0.1, -0.05, 0.3, 0.25, 0.15, 0.1, 0.05, 0.02, 0.01
	};

	mixin BIO_Recoil_Impl;
}

class BIO_Recoil_ChainsawIdle : BIO_RecoilThinker
{
	static const float[] PITCH_VALUES = {
		-0.05, -0.2, -0.05, -0.02, 0.05, 0.2, 0.05, 0.02
	};

	mixin BIO_Recoil_Impl;
}