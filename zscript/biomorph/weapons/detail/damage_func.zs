class BIO_DamageFunctor play abstract
{
	abstract int Invoke() const;

	virtual void GetValues(in out Array<int> vals) const {}
	virtual void SetValues(in out Array<int> vals) {}

	uint ValueCount() const
	{
		Array<int> vals;
		GetValues(vals);
		return vals.Size();
	}

	// Output should be full localized.
	abstract string ToString(BIO_DamageFunctor def) const;

	readOnly<BIO_DamageFunctor> AsConst() const { return self; }
}

// Emits a random number between a minimum and a maximum.
class BIO_DmgFunc_Default : BIO_DamageFunctor
{
	private int Minimum, Maximum;

	override int Invoke() const { return Random(Minimum, Maximum); }

	override void GetValues(in out Array<int> vals) const
	{
		vals.PushV(Minimum, Maximum);
	}

	override void SetValues(in out Array<int> vals)
	{
		Minimum = vals[0];
		Maximum = vals[1];
	}

	void CustomSet(int minDmg, int maxDmg)
	{
		Minimum = minDmg;
		Maximum = maxDmg;
	}

	override string ToString(BIO_DamageFunctor def) const
	{
		let myDefs = BIO_DmgFunc_Default(def);
		string crEsc_min = "", crEsc_max = "";

		if (myDefs != null)
		{
			crEsc_min = BIO_Utils.StatFontColor(Minimum, myDefs.Minimum);
			crEsc_max = BIO_Utils.StatFontColor(Maximum, myDefs.Maximum);
		}
		else
		{
			crEsc_min = crEsc_max = CRESC_STATMODIFIED;
		}

		return String.Format(
			StringTable.Localize("$BIO_WEAP_DMGFUNC_DEFAULT"),
			crEsc_min, Minimum, crEsc_max, Maximum);
	}
}

class BIO_DmgFunc_1DX : BIO_DamageFunctor
{
	private int Baseline, MaxFactor;

	override int Invoke() const
	{
		return Baseline * Random(1, MaxFactor);
	}

	void CustomSet(int base, int maxFac)
	{
		Baseline = base;
		MaxFactor = maxFac;
	}

	override void GetValues(in out Array<int> vals) const
	{
		vals.PushV(Baseline);
	}

	override void SetValues(in out Array<int> vals)
	{
		Baseline = vals[0];
	}

	override string ToString(BIO_DamageFunctor def) const
	{
		let myDefs = BIO_DmgFunc_1DX(def);
		string crEsc = "";
		
		if (myDefs != null)
			crEsc = BIO_Utils.StatFontColor(Baseline, myDefs.Baseline);
		else
			crEsc = CRESC_STATMODIFIED;

		return String.Format(
			StringTable.Localize("$BIO_WEAP_DMGFUNC_1DX"),
			crEsc, Baseline, MaxFactor);
	}
}

class BIO_DmgFunc_Single : BIO_DamageFunctor
{
	private int Value;

	override int Invoke() const { return Value; }

	override void GetValues(in out Array<int> vals) const
	{
		vals.PushV(Value);
	}

	override void SetValues(in out Array<int> vals)
	{
		Value = vals[0];
	}

	void CustomSet(int val) { Value = val; }

	override string ToString(BIO_DamageFunctor def) const
	{
		let myDefs = BIO_DmgFunc_Single(def);
		string crEsc = "";

		if (myDefs != null)
			crEsc = BIO_Utils.StatFontColor(Value, myDefs.Value);
		else
			crEsc = CRESC_STATMODIFIED;

		return String.Format(
			StringTable.Localize("$BIO_WEAP_DMGFUNC_SINGLE"),
			crEsc, Value);
	}
}