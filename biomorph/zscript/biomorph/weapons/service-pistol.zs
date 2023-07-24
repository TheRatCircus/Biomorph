/// A Pistol counterpart.
/// Infinite ammo, 7-round magazine, highly damaging.
/// Abbreviation: `SVP`
class biom_ServicePistol : biom_Weapon
{
	protected biom_wdat_ServicePistol data;

	Default
	{
		Tag "$BIOM_SERVICEPISTOL_TAG";
		Obituary "$BIOM_SERVICEPISTOL_OB";

		Inventory.Icon 'SVPZZ0';
		Inventory.PickupMessage "$BIOM_SERVICEPISTOL_PKUP";

		Weapon.SelectionOrder SELORDER_PISTOL;
		Weapon.SlotNumber 2;

		biom_Weapon.DataClass 'biom_wdat_ServicePistol';
		biom_Weapon.Grade BIOM_WEAPGRADE_3;
	}

	States
	{
	Spawn:
		SVPZ Z -1;
		stop;
	Select:
		TNT1 A 0 A_Raise;
		loop;
	Deselect:
		SVPS ABCDEF 2 A_Lower;
		goto Deselect.Repeat;
	Deselect.Repeat:
		TNT1 A 1 A_Lower;
		loop;
	Ready:
		SVPS FEDCBA 2;
		goto Ready.Main;
	Ready.Main:
		// TODO: Diverge based on magazine state.
	Ready.Chambered:
		SVPA A 1 A_WeaponReady;
		loop;
	Ready.Empty:
		SVP1 D 1 A_WeaponReady;
		loop;
	Fire:
		// Baseline time: 10 tics; 9 fewer than the vanilla Pistol.
		SVPA A 1 offset(0 + 5, 32 + 5)
		{
			A_StartSound("biom/weap/servicepistol/fire", CHAN_AUTO);
			A_GunFlash();
			A_biom_Recoil('biom_recoil_Handgun');
		}
		SVP1 C 1 offset(0 + 3, 32 + 3);
		SVP1 D 1 offset(0 + 2, 32 + 2);
		SVP1 C 1 offset(0 + 1, 32 + 1);
		SVPA A 6 A_WeaponOffset(0.0, 32.0);
		goto Ready.Main;
	Dryfire:
		SVPA A 1 offset(0, 32 + 1);
		#### # 1 offset(0, 32 + 2);
		#### # 1 offset(0, 32 + 3) A_StartSound("biom/weap/dryfire/ballistic");
		#### # 1 offset(0, 32 + 2);
		#### # 1 offset(0, 32 + 1);
		goto Ready.Main;
	Flash:
		TNT1 A 0 A_Jump(256, 'Flash.A', 'Flash.B');
		TNT1 A 0 A_Unreachable;
	Flash.A:
		SVP1 A 1 bright offset(0 + 3, 32 + 5) A_Light(1);
		goto Flash.Finish;
	Flash.B:
		SVP1 B 1 bright offset(0 + 3, 32 + 5) A_Light(1);
		goto Flash.Finish;
	Flash.Finish:
		TNT1 A 0 A_Light(0);
		goto LightDone;
	}
}

class biom_wdat_ServicePistol : biom_WeaponData
{
	final override void Reset()
	{
		// ???
	}
}
