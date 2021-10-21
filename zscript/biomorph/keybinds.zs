// Inventory items as proxies for key bindings to act upon the player.

class BIO_Keybind : Inventory abstract
{
	Default
	{
		Inventory.Icon "TNT1A0";
		Inventory.InterHubAmount 1;
		Inventory.MaxAmount 1;
		Inventory.Pickupmessage
			"If you're seeing this message, things might break.";

		-COUNTITEM
		+INVENTORY.KEEPDEPLETED
		+INVENTORY.UNDROPPABLE
		+INVENTORY.UNTOSSABLE
	}

	States
	{
	Spawn:
		TNT1 A -1;
		Loop;
	}
}

// Making weapons try to drop themselves leads to buggy behaviour.
class BIO_WeaponDrop : BIO_Keybind
{
	private bool Primed;

	override bool Use(bool pickup)
	{
		let bioPlayer = BIO_Player(Owner);
		if (bioPlayer == null) return false;

		let weap = BIO_Weapon(bioPlayer.Player.ReadyWeapon);
		if (weap == null || weap.Grade == BIO_GRADE_NONE) return false;

		if (!Primed)
		{
			int k1, k2;
			[k1, k2] = Bindings.GetKeysForCommand("bio_dropweap");
			string prompt = String.Format(
				StringTable.Localize("$BIO_WEAPDROP_CONFIRM"),
				Keybindings.NameKeys(k1, k2));
			bioPlayer.A_Print(prompt);
			Primed = true;
		}
		else
		{
			Owner.DropInventory(weap, 1);
			Primed = false;
		}

		return false;
	}
}
