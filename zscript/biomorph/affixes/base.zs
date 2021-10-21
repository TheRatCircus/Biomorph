class BIO_Affix play abstract
{
	const CRESC_POSITIVE = "\cd"; // Green
	const CRESC_NEGATIVE = "\cg"; // Red
	const CRESC_NEUTRAL = "\cc"; // Grey
	const CRESC_MIXED = "\cf"; // Gold

	// Output should be fully localized.
	abstract string ToString() const;
}

class BIO_WeaponAffix : BIO_Affix abstract
{
	abstract void Init(BIO_Weapon weap);
	abstract bool Compatible(BIO_Weapon weap) const;

	virtual void ApplyToWeapon(BIO_Weapon weap) const {}
	virtual void OnBulletFired(BIO_Weapon weap) const {}
	virtual void OnProjectileFired(BIO_Weapon weap, Actor proj) const {}
}

class BIO_EquipmentAffix : BIO_Affix abstract
{
	abstract void Init(BIO_Armor armor);
	abstract bool Compatible(BIO_Armor armor) const;

	virtual void OnArmorEquip(BIO_Armor armor, BIO_ArmorStats stats) const {}
}
