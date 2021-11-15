extend class BIO_EventHandler
{
	override void ConsoleProcess(ConsoleEvent event)
	{
		// Normal gameplay events
		if (ConEvent_PerkMenu(event)) return;

		// Debugging events
		if (ConEvent_Help(event)) return;
		if (ConEvent_PassiveDiag(event)) return;
		if (ConEvent_WeapDiag(event)) return;
		if (ConEvent_XPInfo(event)) return;
		if (ConEvent_WeapAfxCompat(event)) return;
	}

	private ui bool ConEvent_Help(ConsoleEvent event) const
	{
		if (!(event.Name ~== "bio_help"))
			return false;
		
		if (!event.IsManual)
		{
			Console.Printf(Biomorph.LOGPFX_ERR ..
				"Illegal attempt by a script to invoke `bio_help`.");
			return true;
		}

		Console.Printf(
			"\c[Gold]Console events:\c-\n"
			"bio_help_\n" ..
			"bio_weapdiag_\n" ..
			"bio_pasvdiag_\n" ..
			"bio_xpinfo_\n" ..
			"event bio_wafxcompat:Classname\n" ..
			"\c[Gold]Network events:\c-\n" ..
			"event bio_addpasv:Classname\n" ..
			"event bio_rmpasv:Classname\n" ..
			"event bio_addwafx:Classname\n" ..
			"event bio_rmwafx:Classname");

		return true;
	}

	private ui bool ConEvent_PassiveDiag(ConsoleEvent event) const
	{
		if (!(event.Name ~== "bio_pasvdiag"))
			return false;
		
		if (!event.IsManual)
		{
			Console.Printf(Biomorph.LOGPFX_INFO ..
				"`bio_pasvdiag`");
			return true;
		}

		let bioPlayer = BIO_Player(Players[ConsolePlayer].MO);
		if (bioPlayer == null)
		{
			Console.Printf(Biomorph.LOGPFX_INFO ..
				"This event can only be invoked on Biomorph-class players.");
			return true;
		}

		string output = "\c[Gold]Passives:\n";

		for (uint i = 0; i < bioPlayer.Passives.Size(); i++)
			output.AppendFormat("%s x %d\n",
				bioPlayer.Passives[i].GetClassName(),
				bioPlayer.Passives[i].Count);

		output.DeleteLastCharacter();
		Console.Printf(output);
		return true;
	}

	private ui bool ConEvent_PerkMenu(ConsoleEvent event) const
	{
		if (!(event.Name ~== "bio_perkmenu")) return false;

		if (GameState != GS_LEVEL) return true;
		if (Players[ConsolePlayer].Health <= 0) return true;
		if (!(Players[ConsolePlayer].MO is 'BIO_Player')) return true;
		if (Menu.GetCurrentMenu() is 'BIO_PerkMenu') return true;

		Menu.SetMenu('BIO_PerkMenu');
		return true;
	}

	private ui bool ConEvent_WeapDiag(ConsoleEvent event) const
	{
		if (!(event.Name ~== "bio_weapdiag")) return false;
		if (!event.IsManual)
		{
			Console.Printf(Biomorph.LOGPFX_INFO ..
				"Illegal attempt by a script to invoke `bio_weapdiag`.");
			return true;
		}

		let bioPlayer = BIO_Player(Players[ConsolePlayer].MO);
		if (bioPlayer == null) return true;

		let weap = BIO_Weapon(Players[ConsolePlayer].ReadyWeapon);
		if (weap == null)
		{
			Console.Printf(Biomorph.LOGPFX_INFO ..
				"This event can only be invoked on a Biomorph weapon.");
			return true;
		}

		string output = Biomorph.LOGPFX_INFO;
		output.AppendFormat("%s\n%s\n", weap.GetClassName(), weap.GetTag());

		string ft1, ft2;

		if (weap.FireType1 != null)
			ft1 = weap.FireType1.GetClassName();
		else
			ft1 = "null";

		if (weap.FireType2 != null)
			ft2 = weap.FireType2.GetClassName();
		else
			ft2 = "null";

		output = output .. "\c[Gold]Primary stats:\c-\n";
		output.AppendFormat("Fire data: %d x %s\n", weap.FireCount1, ft1);
		output.AppendFormat("Damage: [%d, %d]\n", weap.MinDamage1, weap.MaxDamage1);

		output = output .. "\c[Gold]Secondary stats:\c-\n";
		output.AppendFormat("Fire data: %d x %s\n", weap.FireCount2, ft2);
		output.AppendFormat("Damage: [%d, %d]\n", weap.MinDamage2, weap.MaxDamage2);

		Array<int> fireTimes;
		weap.GetFireTimes(fireTimes);
		if (fireTimes.Size() > 0)
		{
			output = output .. "\c[Gold]Fire times:\c-\n";
			for (uint i = 0; i < fireTimes.Size(); i++)
				output = output .. "\t" .. fireTimes[i] .. "\n";
		}

		Array<int> reloadTimes;
		weap.GetReloadTimes(reloadTimes);
		if (reloadTimes.Size() > 0)
		{
			output = output .. "\c[Gold]Reload times:\c-\n";
			for (uint i = 0; i < reloadTimes.Size(); i++)
				output = output .. "\t" .. reloadTimes[i] .. "\n";
		}

		output.AppendFormat("Switch speeds: %d lower, %d raise\n",
			weap.LowerSpeed, weap.RaiseSpeed);

		output.AppendFormat("Kickback: %d", weap.Kickback);

		if (weap.ImplicitAffixes.Size() > 0)
		{
			output = output .. "Implicit affixes:\n";
			for (uint i = 0; i < weap.ImplicitAffixes.Size(); i++)
				output.AppendFormat("\t%s\n", weap.ImplicitAffixes[i].GetClassName());
		}

		if (weap.Affixes.Size() > 0)
		{
			output = output .. "Affixes:\n";
			for (uint i = 0; i < weap.Affixes.Size(); i++)
				output.AppendFormat("\t%s\n", weap.Affixes[i].GetClassName());
		}

		if (weap.ProjTravelFunctors.Size() > 0)
		{
			output = output .. "Projectile travel functors:\n";
			for (uint i = 0; i < weap.ProjTravelFunctors.Size(); i++)
				output.AppendFormat("\t%s\n", weap.ProjTravelFunctors[i].GetClassName());
		}

		if (weap.ProjDamageFunctors.Size() > 0)
		{
			output = output .. "Projectile damage functors:\n";
			for (uint i = 0; i < weap.ProjDamageFunctors.Size(); i++)
				output.AppendFormat("\t%s\n", weap.ProjDamageFunctors[i].GetClassName());
		}

		if (weap.ProjDeathFunctors.Size() > 0)
		{
			output = output .. "Projectile death functors:\n";
			for (uint i = 0; i < weap.ProjDeathFunctors.Size(); i++)
				output.AppendFormat("\t%s\n", weap.ProjDeathFunctors[i].GetClassName());
		}

		Console.Printf(output);
		return true;
	}

	private ui bool ConEvent_WeapAfxCompat(ConsoleEvent event) const
	{
		Array<string> nameParts;
		event.Name.Split(nameParts, ":");

		if (!nameParts[0] || !(nameParts[0] ~== "bio_wafxcompat"))
			return false;

		if (!event.IsManual)
		{
			Console.Printf(Biomorph.LOGPFX_INFO ..
				"Illegal attempt by a script to invoke `bio_wafxcompat`.");
			return true;
		}

		let weap = BIO_Weapon(Players[ConsolePlayer].ReadyWeapon);
		if (weap == null)
		{
			Console.Printf(Biomorph.LOGPFX_INFO ..
				"This event can only be invoked on a Biomorph weapon.");
			return true;
		}

		if (nameParts.Size() < 2 || !nameParts[1])
		{
			Console.Printf(Biomorph.LOGPFX_INFO ..
				"Please provide a weapon affix class name.");
			return true;
		}
	
		Class<BIO_WeaponAffix> afx_t = nameParts[1];
		if (!afx_t)
		{
			Console.Printf(Biomorph.LOGPFX_INFO ..
				"%s is not a valid weapon affix class name.", nameParts[1]);
			return true;
		}

		bool compat = BIO_WeaponAffix(new(afx_t)).Compatible(weap);
		string output;
		
		if (compat)
			output.AppendFormat("\ck%s\c- is \cdcompatible\c- with this weapon.",
				afx_t.GetClassName());
		else
			output.AppendFormat("\ck%s\c- is \cgincompatible\c- with this weapon.",
				afx_t.GetClassName());
		
		Console.Printf(Biomorph.LOGPFX_INFO .. output);
		return true;
	}

	private ui bool ConEvent_XPInfo(ConsoleEvent event) const
	{
		if (!(event.Name ~== "bio_xp")) return false;
		if (!event.IsManual)
		{
			Console.Printf(Biomorph.LOGPFX_ERR ..
				"Illegal attempt by a script to invoke `bio_xp`.");
			return true;
		}

		Console.Printf(Biomorph.LOGPFX_INFO .. "Party XP and levelling info:\n");
		Console.Printf("Party level: %d", Globals.GetPartyLevel());
		Console.Printf("Current party XP: %d", Globals.GetPartyXP());
		Console.Printf("XP to next level: %d", Globals.XPToNextLevel());
		return true;
	}
}