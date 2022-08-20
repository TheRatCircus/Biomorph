extend class BIO_Weapon
{
	bool Uninitialised() const
	{
		return
			OpMode == null &&
			Pipelines.Size() < 1 &&
			Affixes.Size() < 1 &&
			ModGraph == null;
	}

	// Doesn't do much, but will ease refactoring if the condition needs to change.
	bool IsMutated() const
	{
		return ModGraph != null;
	}

	// Graph quality carried over successive downgrades/sidegrades.
	uint InheritedGraphQuality() const
	{
		if (ModGraph == null)
			return 0;

		return (ModGraph.Nodes.Size() - 1) - Default.GraphQuality;
	}

	bool HasAffixOfType(class<BIO_WeaponAffix> type) const
	{
		for (uint i = 0; i < Affixes.Size(); i++)
			if (Affixes[i].GetClass() == type)
				return true;

		return false;
	}

	BIO_WeaponAffix GetAffixByType(class<BIO_WeaponAffix> type) const
	{
		for (uint i = 0; i < Affixes.Size(); i++)
			if (Affixes[i].GetClass() == type)
				return Affixes[i];

		return null;
	}

	// Returns a valid result even if the weapon feeds from reserves,
	// or if the weapon doesn't consume ammo to fire.
	uint ShotsPerMagazine(bool secondary = false) const
	{
		float dividend = 0.0, divisor = 0.0;

		if (!secondary)
		{
			if (AmmoUse1 == 0)
				return uint.MAX;

			divisor = float(AmmoUse1);

			if (Magazine1 != null || MagazineType1 != null)
				dividend = float(MagazineSize1);
			else if (Ammo1 != null)
				dividend = float(Ammo1.MaxAmount);
			else if (AmmoType1 != null)
				dividend = float(GetDefaultByType(AmmoType1).MaxAmount);
		}
		else
		{
			if (AmmoUse2 == 0)
				return uint.MAX;

			divisor = float(AmmoUse2);

			if (Magazine2 != null || MagazineType2 != null)
				dividend = float(MagazineSize2);
			else if (Ammo2 != null)
				dividend = float(Ammo2.MaxAmount);
			else if (AmmoType2 != null)
				dividend = float(GetDefaultByType(AmmoType2).MaxAmount);
		}

		return Floor(dividend / divisor);
	}

	uint RealAmmoConsumption(bool secondary = false) const
	{
		if (!secondary)
		{
			if (Magazine1 != null)
			{
				return AmmoUse1 * uint(Ceil(
					double(ReloadCost1) / double(ReloadOutput1)
				));
			}
			else
			{
				return AmmoUse1;
			}
		}
		else
		{
			if (Magazine2 != null)
			{
				return AmmoUse2 * uint(Ceil(
					double(ReloadCost2) / double(ReloadOutput2)
				));
			}
			else
			{
				return AmmoUse2;
			}
		}
	}

	bool Ammoless() const { return Ammo1 == null && Ammo2 == null; }
	bool Magazineless() const { return Magazine1 == null && Magazine2 == null; }

	bool CanReload(bool secondary = false) const
	{
		if (!secondary)
			return Magazine1 != null && Magazine1.CanReload(self);
		else
			return Magazine2 != null && Magazine2.CanReload(self);
	}

	// i.e., to fire a round.
	bool SufficientAmmo(bool secondary = false, int multi = 1) const
	{
		if (CheckInfiniteAmmo())
			return true;

		if (!secondary)
		{
			if (Magazine1 != null)
				return Magazine1.Sufficient(self, AmmoUse1 * multi);
			else if (Ammo1 != null)
				return Ammo1.Amount >= (AmmoUse1 * multi);
			else
				return true;
		}
		else
		{
			if (Magazine2 != null)
				return Magazine2.Sufficient(self, AmmoUse2 * multi);
			else if (Ammo2 != null)
				return Ammo2.Amount >= (AmmoUse2 * multi);
			else
				return true;
		}
	}

	// Returns `false` if the request magazine is null.
	bool MagazineEmpty(bool secondary = false) const
	{
		if (!secondary)
			return Magazine1 != null && Magazine1.IsEmpty();
		else
			return Magazine2 != null && Magazine2.IsEmpty();
	}

	// Returns `false` if the request magazine is null.
	bool MagazineFull(bool secondary = false) const
	{
		if (!secondary)
			return Magazine1 != null && Magazine1.IsFull(MagazineSize1);
		else
			return Magazine2 != null && Magazine2.IsFull(MagazineSize2);
	}

	bool CheckInfiniteAmmo() const
	{
		return
			sv_infiniteammo ||
			Owner.FindInventory('PowerInfiniteAmmo', true) != null;
	}

	bool MagazineSizeMutable(bool secondary = false) const
	{
		if (!secondary)
			return Magazine1 != null && MagazineSize1 > 0;
		else
			return Magazine2 != null && MagazineSize2 > 0;
	}

	bool FireTimesReducible() const
	{
		// State sequences can't have all of their tic times reduced to 0.
		// Fire rate-affecting affixes must know in advance if
		// they can even have any effect, given this caveat.
		for (uint i = 0; i < OpMode.FireTimeGroups.Size(); i++)
			if (OpMode.FireTimeGroups[i].PossibleReduction() > 1)
				return true;

		return false;
	}

	bool FireTimesMutable() const
	{
		return OpMode.FireTimeGroups.Size() > 0 && FireTimesReducible();
	}

	bool ReloadTimesReducible() const
	{
		// State sequences can't have all of their tic times reduced to 0.
		// Reload speed-affecting affixes must know in advance if
		// they can even have any effect, given this caveat.
		for (uint i = 0; i < ReloadTimeGroups.Size(); i++)
			if (ReloadTimeGroups[i].PossibleReduction() > 1)
				return true;

		return false;
	}

	bool ReloadTimesMutable() const
	{
		return ReloadTimeGroups.Size() > 0 && ReloadTimesReducible();
	}

	bool DealsHitDamage() const
	{
		for (uint i = 0; i < Pipelines.Size(); i++)
			if (Pipelines[i].DealsHitDamage())
				return true;

		return false;
	}

	bool DealsAnySplashDamage() const
	{
		for (uint i = 0; i < Pipelines.Size(); i++)
			if (Pipelines[i].DealsAnySplashDamage())
				return true;

		return false;
	}

	bool AnyPipelineFiresPayload(class<Actor> payload, bool subclass = false)
	{
		for (uint i = 0; i < Pipelines.Size(); i++)
		{
			if (subclass)
			{
				if (Pipelines[i].Payload is payload)
					return true;
			}
			else
			{
				if (Pipelines[i].Payload == payload)
					return true;
			}
		}

		return false;
	}

	private bool ScavengingDestroys() const
	{
		return
			(AmmoType1 != null || AmmoType2 != null) &&
			AmmoGive1 <= 0 && AmmoGive2 <= 0 && !ScavengePersist &&
			!IsMutated();
	}

	string ColoredTag() const
	{
		string crEsc = "\c[White]";

		if (Unique)
			crEsc = "\c[Orange]";
		else if (IsMutated())
			crEsc = "\c[Cyan]";

		return String.Format("%s%s\c-", crEsc, Default.GetTag());
	}

	readOnly<BIO_Weapon> AsConst() const { return self; }
}

extend class BIO_Weapon
{
	BIO_StateTimeGroup StateTimeGroupFrom(
		statelabel label,
		string tag = "",
		BIO_StateTimeGroupFlags flags = BIO_STGF_NONE
	) const
	{
		state s = FindState(label);

		if (s == null)
		{
			Console.Printf(
				Biomorph.LOGPFX_ERR ..
				"`BIO_Weapon::StateTimeGroupFrom()` "
				"failed to find a state by label. (%s)",
				GetClassName()
			);
			return null;
		}

		return BIO_StateTimeGroup.FromState(s, tag, flags);
	}

	BIO_StateTimeGroup StateTimeGroupFromRange(
		statelabel start,
		statelabel end,
		string tag = "",
		BIO_StateTimeGroupFlags flags = BIO_STGF_NONE
	) const
	{
		state s = FindState(start);

		if (s == null)
		{
			Console.Printf(
				Biomorph.LOGPFX_ERR ..
				"`BIO_Weapon::StateTimeGroupFromRange()` "
				"failed to find a state given a `start` label. (%s)",
				GetClassName()
			);
			return null;
		}

		state e = FindState(end);

		if (e == null)
		{
			Console.Printf(
				Biomorph.LOGPFX_ERR ..
				"`BIO_Weapon::StateTimeGroupFromRange()` "
				"failed to find a state given an `end` label. (%s)",
				GetClassName()
			);
			return null;
		}

		return BIO_StateTimeGroup.FromStateRange(s, e, tag, flags);
	}

	BIO_StateTimeGroup StateTimeGroupFromArray(
		Array<statelabel> labels,
		string tag = "",
		BIO_StateTimeGroupFlags flags = BIO_STGF_NONE
	) const
	{
		Array<state> stateptrs;

		for (uint i = 0; i < labels.Size(); i++)
		{
			state s = FindState(labels[i]);

			if (s == null)
			{
				Console.Printf(
					Biomorph.LOGPFX_ERR ..
					"`BIO_Weapon::StateTimeGroupFromArray()` "
					"failed to find state at index %d. (%s)",
					i, GetClassName()
				);
			}
			else
			{
				stateptrs.Push(s);
			}
		}

		return BIO_StateTimeGroup.FromStates(stateptrs, tag, flags);
	}
}