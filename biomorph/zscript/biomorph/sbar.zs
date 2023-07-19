class BIOM_StatusBar : BaseStatusBar
{
	private CVar invBarSlots, notifyLineCount;
	private BIOM_Player pawn;
	private InventoryBarState invBarState;

	private HUDFont fontBig, fontIndex, fontSmall;
	private HUDFont fontDoomBig, fontDoomIndex, fontDoomAmount;

	/// Resource acquisition.
	final override void Init()
	{
		if (developer >= 1)
			Console.PrintF(Biomorph.LOGPFX_DEBUG .. "Initialising status bar...");

		super.Init();
		self.SetSize(32, 320, 200);

		Font fnt = 'JENOBIG';
		self.fontBig = HUDFont.Create(fnt, fnt.GetCharWidth("0"), MONO_CELLLEFT, 1, 1);
		self.fontIndex = HUDFont.Create('INDEXFONT');
		self.fontSmall = HUDFont.Create('JenocideFontRed');

		Font fntd = 'HUDFONT_DOOM';
		self.fontDoomBig = HUDFont.Create(fntd, fntd.GetCharWidth("0"), MONO_CELLLEFT, 1, 1);
		fntd = 'INDEXFONT_DOOM';
		self.fontDoomIndex = HUDFont.Create(fntd, fntd.GetCharWidth("0"), MONO_CELLLEFT);
		self.fontDoomAmount = HUDFont.Create('INDEXFONT');

		self.invBarState = InventoryBarState.Create();
	}

	/// Acquire a pre-downcast player pawn pointer and CVar handles.
	final override void AttachToPlayer(PlayerInfo player)
	{
		super.AttachToPlayer(player);

		self.pawn = BIOM_Player(self.cPlayer.mo);

		if (self.cPlayer.mo != null && self.pawn == null)
		{
			ThrowAbortException(
				Biomorph.LOGPFX_ERR ..
				"\nFailed to attach HUD to a Biomorph-class player."
				"\nTry the PawnPatch."
				"\nIf errors continue after that, report a bug to RatCircus."
			);
		}

		self.notifyLineCount = CVar.GetCVar("con_notifylines", self.cPlayer);
		self.invBarSlots = CVar.GetCVar("BIOM_invbarslots", self.cPlayer);
	}

	final override void Draw(int state, double ticFrac)
	{
		super.Draw(state, ticFrac);

		if (state == HUD_StatusBar)
		{
			self.BeginStatusBar();
			DrawMainBar(ticFrac);
			return;
		}

		self.BeginHUD();

		let berserk = self.pawn.FindInventory('PowerStrength', true) != null;

		self.DrawImage('graphics/pulse_small.png', (20, -2));

		self.DrawString(
			self.fontBig,
			String.Format(
				"%s / %s",
				FormatNumber(self.cPlayer.Health, 3, 5),
				FormatNumber(self.pawn.GetMaxHealth(true), 3, 5)
			),
			(44, -18),
			0,
			!berserk ? Font.CR_WHITE : Font.CR_DARKRED
		);

		if (berserk)
			self.DrawImage('graphics/bang_small.png', (36, -2));

		let armor = self.cPlayer.mo.FindInventory('BasicArmor');

		if (armor != null && armor.Amount > 0)
		{
			self.DrawInventoryIcon(armor, (20, -22));

			self.DrawString(
				self.fontBig,
				FormatNumber(armor.Amount, 3),
				(44, -36), 0, Font.CR_DARKGREEN
			);
			self.DrawString(
				self.fontSmall,
				FormatNumber(self.GetArmorSavePercent(), 3) .. "%",
				(14, -30), 0, Font.CR_WHITE
			);
		}
	}

	/// Draw powerup icons at top left, along with the
	/// durations remaining on their effects in seconds.
	final override void DrawPowerups()
	{
		int yPos = 0;

		for (Inventory i = self.cPlayer.mo.Inv; i != null; i = i.Inv)
		{
			int yOffs = self.notifyLineCount.GetInt() * 16;
			let powup = Powerup(i);

			if (powup == null || !powup.Icon || powup is 'PowerStrength')
				continue;

			self.DrawInventoryIcon(powup, (20, yOffs + yPos));
			yPos += 8;
			int secs = powup.EffectTics / GameTicRate;

			self.DrawString(
				self.fontSmall,
				FormatNumber(secs, 1, 3),
				(19, yOffs + yPos),
				DI_TEXT_ALIGN_CENTER,
				Font.CR_WHITE
			);

			yPos += 32;
		}
	}
}

/// The Doom status bar is left as-is; this code is a nearly-verbatim copy-paste
/// from gzdoom.pk3/zscript/ui/statusbar/doom_sbar.zs.
extend class BIOM_StatusBar
{
	private void DrawMainBar(double ticFrac)
	{
		self.DrawImage('STBAR', (0, 168), DI_ITEM_OFFSETS);
		self.DrawImage('STTPRCNT', (90, 171), DI_ITEM_OFFSETS);
		self.DrawImage('STTPRCNT', (221, 171), DI_ITEM_OFFSETS);

		Inventory a1 = self.GetCurrentAmmo();

		if (a1 != null)
		{
			self.DrawString(
				self.fontDoomBig,
				FormatNumber(a1.amount, 3),
				(44, 171),
				DI_TEXT_ALIGN_RIGHT | DI_NOSHADOW
			);
		}

		self.DrawString(
			self.fontDoomBig,
			FormatNumber(self.cPlayer.health, 3),
			(90, 171),
			DI_TEXT_ALIGN_RIGHT | DI_NOSHADOW
		);

		self.DrawString(
			self.fontDoomBig,
			FormatNumber(self.GetArmorAmount(), 3),
			(221, 171),
			DI_TEXT_ALIGN_RIGHT | DI_NOSHADOW
		);

		self.DrawBarKeys();
		self.DrawBarAmmo();

		if (deathmatch || teamplay)
		{
			DrawString(
				self.fontDoomBig,
				FormatNumber(self.cPlayer.fragCount, 3),
				(138, 171),
				DI_TEXT_ALIGN_RIGHT
			);
		}
		else
		{
			DrawBarWeapons();
		}

		if (multiplayer)
		{
			DrawImage(
				'STFBANY',
				(143, 168),
				DI_ITEM_OFFSETS | DI_TRANSLATABLE
			);
		}

		if (self.cPlayer.mo.invSel != null && !Level.noInventoryBar)
		{
			self.DrawInventoryIcon(self.cPlayer.mo.invSel, (160, 198), DI_DIMDEPLETED);

			if (self.cPlayer.mo.invSel.amount > 1)
			{
				self.DrawString(
					self.fontDoomAmount,
					FormatNumber(self.cPlayer.mo.invSel.amount),
					(175, 198 - self.fontDoomIndex.mFont.GetHeight()),
					DI_TEXT_ALIGN_RIGHT,
					Font.CR_GOLD
				);
			}
		}
		else
		{
			self.DrawTexture(GetMugShot(5), (143, 168), DI_ITEM_OFFSETS);
		}
		if (self.IsInventoryBarVisible())
		{
			self.DrawInventoryBar(self.invBarState, (48, 169), 7, DI_ITEM_LEFT_TOP);
		}
	}

	private void DrawBarKeys() const
	{
		bool locks[6];
		string image;

		for(int i = 0; i < 6; i++)
			locks[i] = self.cPlayer.mo.CheckKeys(i + 1, false, true);

		if (locks[1] && locks[4])
			image = 'STKEYS6';
		else if (locks[1])
			image = 'STKEYS0';
		else if (locks[4])
			image = 'STKEYS3';

		self.DrawImage(image, (239, 171), DI_ITEM_OFFSETS);

		if (locks[2] && locks[5])
			image = 'STKEYS7';
		else if (locks[2])
			image = 'STKEYS1';
		else if (locks[5])
			image = 'STKEYS4';
		else
			image = "";

		self.DrawImage(image, (239, 181), DI_ITEM_OFFSETS);

		if (locks[0] && locks[3])
			image = 'STKEYS8';
		else if (locks[0])
			image = 'STKEYS2';
		else if (locks[3])
			image = 'STKEYS5';
		else
			image = "";

		self.DrawImage(image, (239, 191), DI_ITEM_OFFSETS);
	}

	private void DrawBarAmmo() const
	{
		int amt1 = 0, maxamt = 0;

		[amt1, maxamt] = self.GetAmount('BIOM_Slot4Ammo');
		self.DrawString(
			self.fontDoomIndex,
			FormatNumber(amt1, 3),
			(288, 173),
			DI_TEXT_ALIGN_RIGHT
		);
		self.DrawString(
			self.fontDoomIndex,
			FormatNumber(maxamt, 3),
			(314, 173),
			DI_TEXT_ALIGN_RIGHT
		);

		[amt1, maxamt] = self.GetAmount('BIOM_Slot3Ammo');
		self.DrawString(
			self.fontDoomIndex,
			FormatNumber(amt1, 3),
			(288, 179),
			DI_TEXT_ALIGN_RIGHT
		);
		self.DrawString(
			self.fontDoomIndex,
			FormatNumber(maxamt, 3),
			(314, 179),
			DI_TEXT_ALIGN_RIGHT
		);

		[amt1, maxamt] = self.GetAmount('BIOM_Slot5Ammo');
		self.DrawString(
			self.fontDoomIndex,
			FormatNumber(amt1, 3),
			(288, 185),
			DI_TEXT_ALIGN_RIGHT
		);
		self.DrawString(
			self.fontDoomIndex,
			FormatNumber(maxamt, 3),
			(314, 185),
			DI_TEXT_ALIGN_RIGHT
		);

		[amt1, maxamt] = self.GetAmount('BIOM_Slot67Ammo');
		self.DrawString(
			self.fontDoomIndex,
			FormatNumber(amt1, 3),
			(288, 191),
			DI_TEXT_ALIGN_RIGHT
		);
		self.DrawString(
			self.fontDoomIndex,
			FormatNumber(maxamt, 3),
			(314, 191),
			DI_TEXT_ALIGN_RIGHT
		);
	}

	protected virtual void DrawBarWeapons()
	{
		self.DrawImage('STARMS', (104, 168), DI_ITEM_OFFSETS);

		self.DrawImage(
			self.cPlayer.HasWeaponsInSlot(2) ? 'STYSNUM2' : 'STGNUM2',
			(111, 172),
			DI_ITEM_OFFSETS
		);
		self.DrawImage(
			self.cPlayer.HasWeaponsInSlot(3) ? 'STYSNUM3' : 'STGNUM3',
			(123, 172),
			DI_ITEM_OFFSETS
		);
		self.DrawImage(
			self.cPlayer.HasWeaponsInSlot(4) ? 'STYSNUM4' : 'STGNUM4',
			(135, 172),
			DI_ITEM_OFFSETS
		);
		self.DrawImage(
			self.cPlayer.HasWeaponsInSlot(5) ? 'STYSNUM5' : 'STGNUM5',
			(111, 182),
			DI_ITEM_OFFSETS
		);
		self.DrawImage(
			self.cPlayer.HasWeaponsInSlot(6) ? 'STYSNUM6' : 'STGNUM6',
			(123, 182),
			DI_ITEM_OFFSETS
		);
		self.DrawImage(
			self.cPlayer.HasWeaponsInSlot(7) ? 'STYSNUM7' : 'STGNUM7',
			(135, 182),
			DI_ITEM_OFFSETS
		);
	}
}
