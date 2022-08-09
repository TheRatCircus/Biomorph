// Console event handling.
extend class BIO_EventHandler
{
	final override void ConsoleProcess(ConsoleEvent event)
	{
		if (event.Name.Length() < 5 || !(event.Name.Left(4) ~== "bio_"))
			return;

		// Normal gameplay events

		ConEvent_WeapModMenu(event);

		// Debugging events

		ConEvent_Help(event);
		ConEvent_WeapDiag(event);
		ConEvent_LootDiag(event);
		ConEvent_MonsVal(event);
		ConEvent_LootSim(event);
		ConEvent_WeapSerialize(event);
	}

	private static ui void ConEvent_Help(ConsoleEvent event)
	{
		if (!(event.Name ~== "bio_help"))
			return;

		if (!event.IsManual)
		{
			Console.Printf(
				Biomorph.LOGPFX_ERR ..
				"Illegal attempt by a script to invoke `bio_help`."
			);
			return;
		}

		Console.Printf(
			Biomorph.LOGPFX_INFO .. "\n"
			"\c[Gold]Console events:\c-\n"
			"\tbio_help_\n"
			"\tbio_lootdiag_\n"
			"\tbio_weapdiag_\n"
			"\tbio_monsval_\n"
			"\tbio_lootsim_\n"
			"\tbio_weapserialize_\n"
			"\c[Gold]Network events:\c-\n"
			"\tbio_weaplootregen_\n"
			"\tbio_mutalootregen_\n"
			"\tbio_genelootregen_\n"
			"\tbio_morphregen_"
		);
	}

	private ui void ConEvent_LootDiag(ConsoleEvent event) const
	{
		if (!(event.Name ~== "bio_lootdiag"))
			return;

		if (!event.IsManual)
		{
			Console.Printf(
				Biomorph.LOGPFX_ERR ..
				"Illegal attempt by a script to invoke `bio_lootdiag`."
			);
			return;
		}

		Globals.PrintLootDiag();
	}

	private static ui void ConEvent_WeapDiag(ConsoleEvent event)
	{
		if (!(event.Name ~== "bio_weapdiag"))
			return;

		if (!event.IsManual)
		{
			Console.Printf(
				Biomorph.LOGPFX_ERR ..
				"Illegal attempt by a script to invoke `bio_weapdiag`."
			);
			return;
		}

		let weap = BIO_Weapon(Players[ConsolePlayer].ReadyWeapon);

		if (weap == null)
		{
			Console.Printf(
				Biomorph.LOGPFX_INFO ..
				"This event can only be invoked on a Biomorph weapon."
			);
			return;
		}

		string output = String.Format(
			"%sWeapon diagnostics for: %s\n",
			Biomorph.LOGPFX_INFO, weap.GetTag()
		);

		output.AppendFormat("\c[Yellow]Class:\c- `%s`\n", weap.GetClassName());

		output.AppendFormat(
			"\c[Yellow]Switch speeds\c-: %d lower, %d raise\n",
			weap.LowerSpeed, weap.RaiseSpeed
		);

		// Pipelines

		output = output .. "\n";

		if (weap.Pipelines.Size() > 0)
			output.AppendFormat("\c[Yellow]Pipelines\c-:\n");

		for (uint i = 0; i < weap.Pipelines.Size(); i++)
		{
			let ppl = weap.Pipelines[i];

			if (ppl.Tag.Length() > 0)
				output.AppendFormat("\t-> \c[Green]Pipeline: %s\c-\n", ppl.Tag);
			else
				output.AppendFormat("\t-> \c[Green]Pipeline: %d\c-\n", i);

			output.AppendFormat(
				"\t\tUses secondary ammo: %s\n",
				ppl.SecondaryAmmo ? "yes" : "no"
			);
			output.AppendFormat(
				"\t\tFiring functor: %s\n",
				ppl.FireFunctor.GetClassName()
			);
			output.AppendFormat(
				"\t\tPayload: %s\n",
				ppl.Payload.GetClassName()
			);
			output.AppendFormat(
				"\t\tDamage functor: %s\n",
				ppl.Damage.GetClassName()
			);
		}

		// Timings

		output = output .. "\n";

		if (weap.FireTimeGroups.Size() > 0)
			output.AppendFormat("\c[Yellow]Fire time groups:\c-\n");

		for (uint i = 0; i < weap.FireTimeGroups.Size(); i++)
		{
			let ftg = weap.FireTimeGroups[i];
			string tag = ftg.Tag.Length() > 0 ? ftg.Tag : "num. " .. i;
			output.AppendFormat("\t-> \c[Green]Group %s\c-\n", tag);

			for (uint j = 0; j < ftg.Times.Size(); j++)
				output.AppendFormat("\t\t%d, min. %d\n", ftg.Times[j], ftg.Minimums[j]);
		}

		if (weap.ReloadTimeGroups.Size() > 0)
			output.AppendFormat("\c[Yellow]Reload time groups:\c-\n");

		for (uint i = 0; i < weap.ReloadTimeGroups.Size(); i++)
		{
			let rtg = weap.ReloadTimeGroups[i];
			string tag = rtg.Tag.Length() > 0 ? rtg.Tag : "num. " .. i;
			output.AppendFormat("\t-> \c[Green]Group %s\c-\n", tag);

			for (uint j = 0; j < rtg.Times.Size(); j++)
				output.AppendFormat("\t\t%d, min. %d\n", rtg.Times[j], rtg.Minimums[j]);
		}

		Console.Printf(output);
	}

	private static ui void ConEvent_WeapModMenu(ConsoleEvent event)
	{
		if (!(event.Name ~== "bio_weapmodmenu"))
			return;

		if (GameState != GS_LEVEL)
			return;

		if (Players[ConsolePlayer].Health <= 0)
			return;

		if (!(Players[ConsolePlayer].MO is 'BIO_Player'))
			return;

		if (Menu.GetCurrentMenu() is 'BIO_WeaponModMenu')
			return;

		if (!(Players[ConsolePlayer].ReadyWeapon is 'BIO_Weapon'))
			return;

		Menu.SetMenu('BIO_WeaponModMenu');
	}

	private ui void ConEvent_MonsVal(ConsoleEvent event) const
	{
		if (!(event.Name ~== "bio_monsval"))
			return;

		if (!event.IsManual)
		{
			Console.Printf(
				Biomorph.LOGPFX_INFO ..
				"Illegal attempt by a script to invoke `bio_monsval`."
			);
			return;
		}

		let val = MapTotalMonsterValue();
		let loot = val / BIO_Global.LOOT_VALUE_THRESHOLD;

		Console.Printf(
			Biomorph.LOGPFX_INFO .. "\n"
			"\tTotal monster value in this level: %d\n"
			"\tLoot value multiplier: %.2f\n"
			"\tNumber of times loot value threshold was crossed: %d",
			val, Globals.GetLootValueMultiplier(), loot
		);
	}

	private ui void ConEvent_LootSim(ConsoleEvent event) const
	{
		if (!(event.Name ~== "bio_lootsim"))
			return;

		if (!event.IsManual)
		{
			Console.Printf(
				Biomorph.LOGPFX_INFO ..
				"Illegal attempt by a script to invoke `bio_lootsim`."
			);
			return;
		}

		string output = Biomorph.LOGPFX_INFO .. "running loot simulation...\n";

		Array<class<BIO_Mutagen> > mTypes;
		Array<class<BIO_Gene> > gTypes;
		Array<uint> mCounters, gCounters;

		let val = MapTotalMonsterValue();
		let loot = val / BIO_Global.LOOT_VALUE_THRESHOLD;

		for (uint i = 0; i < loot; i++)
		{
			if (Random[BIO_Loot](1, GENE_CHANCE_DENOM) == 1)
			{
				let gene_t = Globals.RandomGeneType();
				let idx = gTypes.Find(gene_t);

				if (idx == gTypes.Size())
				{
					idx = gTypes.Push(gene_t);
					gCounters.Push(1);
				}
				else
				{
					gCounters[idx]++;
				}
			}
			else
			{
				let muta_t = Globals.RandomMutagenType();
				let idx = mTypes.Find(muta_t);

				if (idx == mTypes.Size())
				{
					idx = mTypes.Push(muta_t);
					mCounters.Push(1);
				}
				else
				{
					mCounters[idx]++;
				}
			}
		}

		output = output .. "\c[Yellow]Mutagen loot results:\c-\n";

		for (uint i = 0; i < mTypes.Size(); i++)
		{
			let defs = GetDefaultByType(mTypes[i]);

			output.AppendFormat(
				"\t%s (wt. \c[Green]%d\c-): %d\n",
				mTypes[i].GetClassName(), defs.LootWeight, mCounters[i]
			);
		}

		output = output .. "\c[Yellow]Gene loot results:\c-\n";

		for (uint i = 0; i < gTypes.Size(); i++)
		{
			let defs = GetDefaultByType(gTypes[i]);

			output.AppendFormat(
				"\t%s (wt. \c[Green]%d\c-): %d\n",
				gTypes[i].GetClassName(), defs.LootWeight, gCounters[i]
			);
		}

		output.DeleteLastCharacter();
		Console.Printf(output);
	}

	private static ui void ConEvent_WeapSerialize(ConsoleEvent event)
	{
		if (!(event.Name ~== "bio_weapserialize"))
			return;

		if (!event.IsManual)
		{
			Console.Printf(
				Biomorph.LOGPFX_INFO ..
				"Illegal attempt by a script to invoke `bio_weapserialize`."
			);
			return;
		}

		let weap = BIO_Weapon(Players[ConsolePlayer].ReadyWeapon);

		if (weap == null)
		{
			Console.Printf(
				Biomorph.LOGPFX_INFO ..
				"This event can only be invoked on a Biomorph weapon."
			);
			return;
		}

		Console.Printf(weap.Serialize().ToString());
	}
}