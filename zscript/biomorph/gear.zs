// Symbols common to weapons and equippables like armour.

// Used as a measure of the quality of the gear item at a baseline.
enum BIO_Grade : uint8
{
	BIO_GRADE_NONE,
	BIO_GRADE_SURPLUS, // Unused placeholder
	BIO_GRADE_STANDARD,
	BIO_GRADE_SPECIALTY,
	BIO_GRADE_CLASSIFIED
}

// Used to differentiate between a gear item with no affixes, a gear item
// with randomly-generated affixes, and a gear item with unique affixes.
enum BIO_Rarity : uint8
{
	BIO_RARITY_NONE,
	BIO_RARITY_COMMON,
	BIO_RARITY_MUTATED,
	BIO_RARITY_UNIQUE
}

mixin class BIO_Gear
{
	meta BIO_Grade Grade; property Grade: Grade;
	BIO_Rarity Rarity; property Rarity: Rarity;

	protected bool HitGround, PreviouslyPickedUp;

	// GetTag() only comes with color escape codes after BeginPlay(); use this
	// when derefencing defaults. Always comes with a '\c-' at the end.
	string GetColoredTag() const
	{
		return String.Format("%s%s\c-",
			BIO_Utils.RarityColorEscapeCode(Rarity), GetTag());
	}

	void RLMDangerLevel() const
	{
		// If the DoomRL Arsenal Monster Pack is loaded, rare 
		// gear pickups increase its danger level
		name mpt_tn = 'RLMonsterpackThingo';
		Class<Actor> mpt_t = mpt_tn;

		if (mpt_t != null)
		{
			uint danger = 0;

			switch (Rarity)
			{
			case BIO_RARITY_MUTATED: danger += 25; break;
			case BIO_RARITY_UNIQUE: danger += 50; break;
			default: break;
			}

			switch (Grade)
			{
			case BIO_GRADE_SPECIALTY: danger += 10; break;
			case BIO_GRADE_CLASSIFIED: danger += 20; break;
			default: break;
			}

			if (BIO_CVar.Debug() && danger > 0)
				Console.Printf(Biomorph.LOGPFX_DEBUG ..
					"Increasing DRLA danger level by %d.", danger);

			name rldl_tn = 'RLDangerLevel';
			A_GiveInventory(rldl_tn, danger, AAPTR_PLAYER1);
		}
	}
}
