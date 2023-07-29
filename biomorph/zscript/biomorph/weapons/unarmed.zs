class biom_Unarmed : biom_Weapon
{
	flagdef rightHand: DynFlags, 31;

	protected biom_wdat_Unarmed data;

	Default
	{
		+WEAPON.MELEEWEAPON

		Tag "$BIOM_UNARMED_TAG";
		Obituary "$BIOM_UNARMED_OB";

		Inventory.Icon 'H2HCZ0';

		Weapon.SelectionOrder SELORDER_FIST;
		Weapon.SlotNumber 1;

		biom_Weapon.DataClass 'biom_wdat_Unarmed';
		biom_Weapon.Grade BIOM_WEAPGRADE_1;
	}

	States
	{
	Ready:
		H2HC A 1 A_WeaponReady;
		loop;
	Deselect:
		H2HC A 1 A_Lower;
		loop;
	Select:
		H2HC A 1 A_Raise;
		loop;
	Fire:
		TNT1 A 0 A_JumpIf(invoker.bRightHand, 'Rake.Right');
		goto Rake.Left;
	Rake.Left:
		H2HC B 4 { invoker.bRightHand = true; }
		H2HC C 1;
		H2HC D 2;
		H2HC E 1;
		H2HC F 1;
		H2HC G 2;
		H2HC H 3;
		H2HC I 4;
		TNT1 A 4;
		H2HC A 1 offset(0, 44);
		H2HC A 1 offset(0, 36);
		H2HC A 1 offset(0, 34);
		H2HC A 1 offset(0, 32);
		goto Ready;
	Rake.Right:
		H2HC J 4 { invoker.bRightHand = false; }
		H2HC K 1;
		H2HC L 2;
		H2HC M 1;
		H2HC N 1;
		H2HC O 2;
		H2HC P 3;
		H2HC Q 4;
		TNT1 A 4;
		H2HC A 1 offset(0, 44);
		H2HC A 1 offset(0, 36);
		H2HC A 1 offset(0, 34);
		H2HC A 1 offset(0, 32);
		goto Ready;
	}
}

class biom_wdat_Unarmed : biom_WeaponData
{
	final override void Reset()
	{
		// ???
	}
}