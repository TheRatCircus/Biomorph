// Doubled effect of Health Bonuses ============================================

class BIO_Perk_HealthBonusX2 : BIO_Perk
{
	final override void Apply(BIO_Player bioPlayer) const
	{
		bioPlayer.PushFunctor('BIO_PkupFunc_HealthBonusX2');
	}
}

class BIO_PkupFunc_HealthBonusX2 : BIO_ItemPickupFunctor
{
	final override void OnHealthPickup(BIO_Player bioPlayer, Inventory item) const
	{
		if (item.GetClass() != 'BIO_HealthBonus') return;
		bioPlayer.GiveBody(1, bioPlayer.GetMaxHealth(true) + 100);
	}
}

// `BonusHealth` increases (all minor nodes) ===================================

class BIO_Perk_MaxBonusHealth : BIO_Perk
{
	final override void Apply(BIO_Player bioPlayer) const
	{
		bioPlayer.BonusHealth += 2;
	}
}