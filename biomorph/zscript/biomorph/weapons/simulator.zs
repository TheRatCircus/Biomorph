// (Rat): My kingdom for some honest-to-god sum types

class BIO_WeaponModSimNode
{
	// This is a reflection of the real state of the weapon's mod graph.
	// Only gets altered when the simulation gets committed, so it and the graph
	// are always in perfect sync.
	BIO_WMGNode Basis;

	uint Multiplier;

	// Null if no gene is being simulated in this node.
	// Acts as a representative for what will end up in `Basis.GeneType`.
	BIO_WeaponModSimGene Gene;
	bool Valid;

	BIO_WeaponUpgradeRecipe Upgrade;

	// Accessors ///////////////////////////////////////////////////////////////

	bool IsOccupied() const { return Gene != null; }
	bool IsActive() const { return IsOccupied() || Basis.UUID == 0; }
	bool IsUpgrade() const { return Upgrade != null; }

	BIO_WeaponModifier GetModifier() const
	{
		return Gene == null ? null : Gene.Modifier;
	}

	bool HasModifier() const
	{
		return Gene != null && Gene.Modifier != null;
	}

	class<BIO_Gene> GetGeneType() const
	{
		return Gene == null ? null : Gene.GetType();
	}

	textureID GetIcon() const
	{
		textureID ret;
		ret.SetNull();

		if (Gene != null)
			ret = GetDefaultByType(Gene.GetType()).Icon;
		else if (Upgrade != null)
			ret = GetDefaultByType(Upgrade.GetOutput()).Icon;

		return ret;
	}

	bool Repeatable() const
	{
		let mod = GetModifier();

		if (mod == null)
			return false;

		return mod.RepeatRules() != BIO_WMODREPEATRULES_NONE;
	}

	bool Repeating() const
	{
		return Repeatable() && Multiplier > 1;
	}

	string GetTag() const
	{
		let gene_t = Gene.GetType();

		if (gene_t is 'BIO_ModifierGene')
		{
			return Gene.Modifier.GetTag();
		}
		else
		{
			let defs = GetDefaultByType(gene_t);
			return defs.GetTag();
		}
	}

	bool, string Compatible(readOnly<BIO_WeaponModSimulator> sim) const
	{
		if (Gene == null)
		{
			Console.Printf(
				Biomorph.LOGPFX_ERR ..
				"Attempted to check compatibility of node %d, which lacks a gene.",
				Basis.UUID
			);
			return false, "";
		}

		let gene_t = Gene.GetType();
		bool ret1 = false;
		string ret2 = "";

		if (gene_t is 'BIO_ModifierGene')
		{
			[ret1, ret2] = Gene.Modifier.Compatible(sim.GetWeapon(), Multiplier);
		}
		else if (gene_t is 'BIO_SupportGene')
		{
			let sgene_t = (class<BIO_SupportGene>)(gene_t);
			let defs = GetDefaultByType(sgene_t);
			[ret1, ret2] = defs.Compatible(sim, Basis.UUID);
		}
		else if (gene_t is 'BIO_ActiveGene')
		{
			let agene_t = (class<BIO_ActiveGene>)(gene_t);
			let defs = GetDefaultByType(agene_t);
			[ret1, ret2] = defs.Compatible(sim, Basis.UUID);
		}
		else
		{
			Console.Printf(
				Biomorph.LOGPFX_ERR ..
				"Attempted to check compatibility of node %d, with illegal gene type %s.",
				Basis.UUID, gene_t.GetClassName()
			);
			return false, "";
		}

		return ret1, ret2;
	}

	// Mutators ////////////////////////////////////////////////////////////////

	void Update()
	{
		if (Gene != null)
			Gene.UpdateModifier();
	}

	void Apply(
		BIO_Weapon weap,
		BIO_WeaponModSimulator sim,
		in out Array<BIO_WeaponModSimNode> nodes
	) const
	{
		if (Gene == null)
		{
			Console.Printf(
				Biomorph.LOGPFX_ERR ..
				"Attempted to apply node %d, which lacks a gene.",
				Basis.UUID
			);
			return;
		}

		let gene_t = Gene.GetType();

		if (gene_t is 'BIO_ModifierGene')
		{
			let mod = Gene.Modifier;

			switch (mod.RepeatRules())
			{
			case BIO_WMODREPEATRULES_NONE:
				mod.Apply(weap, 1);
				break;
			case BIO_WMODREPEATRULES_INTERNAL:
				mod.Apply(weap, Multiplier);
				break;
			case BIO_WMODREPEATRULES_EXTERNAL:
				for (uint i = 0; i < Multiplier; i++)
					mod.Apply(weap, 1);

				break;
			default:
				Console.Printf(
					Biomorph.LOGPFX_ERR ..
					"Invalid repeat rules returned by modifier: %s",
					mod.GetClassName()
				);
				break;
			}
		}
		else if (gene_t is 'BIO_SupportGene')
		{
			let sgene_t = (class<BIO_SupportGene>)(gene_t);
			let defs = GetDefaultByType(sgene_t);
			defs.Apply(sim.AsConst(), Basis.UUID);
		}
		else if (gene_t is 'BIO_ActiveGene')
		{
			let agene_t = (class<BIO_ActiveGene>)(gene_t);
			let defs = GetDefaultByType(agene_t);
			defs.Apply(weap, sim, Basis.UUID);
		}
	}
}

class BIO_WeaponModSimGene abstract
{
	BIO_WeaponModifier Modifier;

	abstract void UpdateModifier();
	abstract class<BIO_Gene> GetType() const;

	string GetSummaryTooltip() const
	{
		let gene_t = GetType();

		let ret = String.Format(
			"\c[White]%s\n",
			gene_t is 'BIO_ModifierGene' ?
			 	StringTable.Localize(Modifier.GetTag()) :
				StringTable.Localize(GetDefaultByType(GetType()).GetTag())
		);

		Array<string> summary;

		if (gene_t is 'BIO_ModifierGene')
			Modifier.Summary(summary);
		else if (gene_t is 'BIO_SupportGene')
			GetDefaultByType((class<BIO_SupportGene>)(gene_t)).Summary(summary);
		else if (gene_t is 'BIO_ActiveGene')
			GetDefaultByType((class<BIO_ActiveGene>)(gene_t)).Summary(summary);

		for (uint i = 0; i < summary.Size(); i++)
			ret.AppendFormat("\n%s", StringTable.Localize(summary[i]));

		return ret;
	}

	string GetDescriptionTooltip(readOnly<BIO_Weapon> weap, uint count) const
	{
		let gene_t = GetType();

		if (gene_t is 'BIO_ModifierGene')
		{
			let ret = String.Format(
				"\c[White]%s\n",
				StringTable.Localize(GetDefaultByType(gene_t).GetTag())
			);

			Array<string> desc;
			Modifier.Description(desc, weap, count);

			for (uint i = 0; i < desc.Size(); i++)
				ret.AppendFormat("\n%s", StringTable.Localize(desc[i]));

			return ret;
		}
		else
		{
			return GetSummaryTooltip();
		}
	}
}

// When representing genes that can be moved around the simulated graph, this
// is used for genes which were in the player's inventory at simulation start.
class BIO_WeaponModSimGeneReal : BIO_WeaponModSimGene
{
	BIO_Gene Gene;

	final override void UpdateModifier()
	{
		if (Gene == null)
		{
			Console.Printf(
				Biomorph.LOGPFX_ERR ..
				"A weapon mod sim gene object has a null internal pointer."
			);
			return;
		}

		if (Gene is 'BIO_ModifierGene')
		{
			Modifier = BIO_WeaponModifier(new(BIO_ModifierGene(Gene).ModType));
		}
	}

	final override class<BIO_Gene> GetType() const { return Gene.GetClass(); }
}

// When representing genes that can be moved around the simulated graph, this
// is used for genes which were slotted into the tree at simulation start,
// since those genes have no associated items.
class BIO_WeaponModSimGeneVirtual : BIO_WeaponModSimGene
{
	class<BIO_Gene> Type;

	final override void UpdateModifier()
	{
		if (Type == null)
		{
			Console.Printf(
				Biomorph.LOGPFX_ERR ..
				"A weapon mod sim gene object has a null internal class."
			);
			return;
		}

		if (Type is 'BIO_ModifierGene')
		{
			let mgene_t = (class<BIO_ModifierGene>)(Type);
			let defs = GetDefaultByType(mgene_t);
			Modifier = BIO_WeaponModifier(new(defs.ModType));
		}
	}

	final override class<BIO_Gene> GetType() const { return Type; }
}

class BIO_WeaponModSimulator : Thinker
{
	const STATNUM = Thinker.STAT_STATIC + 1;

	private BIO_Weapon Weap;
	private bool Valid;

	// Representation for the state of the player's gene inventory. Upon commit,
	// genes are given to/taken away from the player according to this.
	// Is sized against `BIO_Player::MaxGenesHeld`.
	Array<BIO_WeaponModSimGene> Genes;
	// Upon commit, the weapon's mod graph is rebuilt to reflect this.
	Array<BIO_WeaponModSimNode> Nodes;

	// Operations //////////////////////////////////////////////////////////////

	static BIO_WeaponModSimulator Create(BIO_Weapon weap)
	{
		if (weap.ModGraph == null)
		{
			Console.Printf(
				Biomorph.LOGPFX_ERR ..
				"Attempted illegal creation of a weapon mod simulator "
				"for a weapon with no mod graph (%s).", weap.GetClassName()
			);
			return null;
		}

		let ret = new('BIO_WeaponModSimulator');
		ret.ChangeStatNum(STATNUM);
		ret.Weap = weap;
		let graph = ret.Weap.ModGraph;

		for (uint i = 0; i < graph.Nodes.Size(); i++)
		{
			let simNode = new('BIO_WeaponModSimNode');
			simNode.Basis = graph.Nodes[i].Copy();

			if (simNode.Basis.GeneType != null)
			{
				let g = new('BIO_WeaponModSimGeneVirtual');
				g.Type = simNode.Basis.GeneType;
				simNode.Gene = g;
			}

			simNode.Multiplier = 1;
			simNode.Valid = true;
			simNode.Update();
			ret.Nodes.Push(simNode);
		}

		let globals = BIO_Global.Get();
		Array<BIO_WeaponUpgradeRecipe> upgrades;
		globals.GetUpgradesFromWeaponType(Weap.GetClass(), upgrades);

		for (uint i = 0; i < upgrades.Size(); i++)
		{
			let simNode = new('BIO_WeaponModSimNode');
			simNode.Basis = new('BIO_WMGNode');
			[simNode.Basis.PosX, simNode.Basis.PosY] =
				graph.RandomAvailableAdjacency();
			simNode.Upgrade = upgrades[i];
			simNode.Basis.UUID = ret.Nodes.Push(simNode);
		}

		ret.RebuildGeneInventory();

		// Simulators are created when opening the weapon mod menu,
		// at which point the graph is necessarily in a valid state
		ret.Valid = true;
		return ret;
	}

	static clearscope BIO_WeaponModSimulator Get(
		BIO_Weapon weap, bool fallible = false)
	{
		let iter = ThinkerIterator.Create('BIO_WeaponModSimulator', STATNUM);
		BIO_WeaponModSimulator ret = null;

		while (ret = BIO_WeaponModSimulator(iter.Next(true)))
		{
			if (ret.Weap == weap)
				return ret;
		}

		if (!fallible)
		{
			Console.Printf(
				Biomorph.LOGPFX_ERR ..
				"Failed to find weapon modification simulator for weapon: %p (%s)",
				weap, weap.GetClassName()
			);
		}

		return null;
	}

	// Take a gene out of the inventory and put it into a node.
	void InsertGene(uint node, uint slot)
	{
		if (Nodes[node].IsOccupied())
		{
			Console.Printf(
				Biomorph.LOGPFX_ERR ..
				"Illegal attempt to add gene to occupied node %d.",
				node
			);
			return;
		}

		if (Genes[slot] == null)
		{
			Console.Printf(
				Biomorph.LOGPFX_ERR ..
				"Illegal attempt to add gene from empty slot %d.",
				slot
			);
			return;
		}

		Nodes[node].Gene = Genes[slot];
		Genes[slot] = null;
	}

	// Move a gene from one node to another.
	void NodeMove(uint fromNode, uint toNode)
	{
		if (!Nodes[fromNode].IsOccupied())
		{
			Console.Printf(
				Biomorph.LOGPFX_ERR ..
				"Illegal attempt to move gene from unfilled node %d.",
				fromNode
			);
			return;
		}

		if (Nodes[toNode].IsOccupied())
		{
			Console.Printf(
				Biomorph.LOGPFX_ERR ..
				"Illegal attempt to move gene to occupied node %d.",
				toNode
			);
			return;
		}

		let temp = Nodes[toNode].Gene;
		Nodes[toNode].Gene = Nodes[fromNode].Gene;
		Nodes[fromNode].Gene = temp;
	}

	// Move a gene from one inventory slot to another.
	void InventoryMove(uint fromSlot, uint toSlot)
	{
		if (Genes[fromSlot] == null)
		{
			Console.Printf(
				Biomorph.LOGPFX_ERR ..
				"Illegal attempt to move gene from empty slot %d.",
				fromSlot
			);
			return;
		}

		if (Genes[toSlot] != null)
		{
			Console.Printf(
				Biomorph.LOGPFX_ERR ..
				"Illegal attempt to move gene to occupied slot %d.",
				toSlot
			);
			return;
		}

		Genes[toSlot] = Genes[fromSlot];
		Genes[fromSlot] = null;
	}

	// Take a gene out of a node and put it back into the inventory.
	// If `slot >= Genes.Size()`, the first available slot is used.
	void ExtractGene(uint node, uint slot)
	{
		if (!Nodes[node].IsOccupied())
		{
			Console.Printf(
				Biomorph.LOGPFX_ERR ..
				"Illegal attempt to remove gene from gene-less node %d.",
				node
			);
			return;
		}

		if (slot >= Genes.Size())
		{
			for (uint i = 0; i < Genes.Size(); i++)
			{
				if (Genes[i] != null)
					continue;

				Genes[i] = Nodes[node].Gene;
				Nodes[node].Gene = null;
				return;
			}

			Console.Printf(
				Biomorph.LOGPFX_ERR ..
				"Found no open inventory slot for gene extracted from node %d.",
				node
			);
		}

		// User specified a slot to return the gene to
		if (Genes[slot] != null)
		{
			Console.Printf(
				Biomorph.LOGPFX_ERR ..
				"Illegal attempt to extract gene into occupied slot %d.",
				slot
			);
			return;
		}

		Genes[slot] = Nodes[node].Gene;
		Nodes[node].Gene = null;
	}

	void Simulate()
	{
		Valid = true;

		Weap.Reset();
		Weap.SetDefaults();

		// First pass sets node defaults

		for (uint i = 0; i < Nodes.Size(); i++)
		{
			Nodes[i].Multiplier = 1;
			Nodes[i].Valid = true;
		}

		// Second pass invokes supports

		for (uint i = 1; i < Nodes.Size(); i++)
		{			
			if (!(Nodes[i].GetGeneType() is 'BIO_SupportGene'))
				continue;

			let node = Nodes[i];

			string _ = "";
			[node.Valid, _] = node.Compatible(AsConst());

			if (!node.Valid)
			{
				Valid = false;
				continue;
			}

			node.Apply(Weap, self, Nodes);
		}

		// Third pass applies modifiers

		for (uint i = 1; i < Nodes.Size(); i++)
		{
			if (!(Nodes[i].GetGeneType() is 'BIO_ModifierGene'))
				continue;

			let node = Nodes[i];
			string _ = "";

			[node.Valid, _] = node.Compatible(AsConst());

			if (!node.Valid)
			{
				Valid = false;
				continue;
			}

			node.Apply(Weap, self, Nodes);
		}
	}

	void Commit()
	{
		if (!IsValid())
		{
			Console.Printf(
				Biomorph.LOGPFX_ERR ..
				"Attempted to commit a weapon mod simulator in an invalid state."
			);
			return;
		}

		weap.ModGraph.Nodes.Clear();

		for (uint i = 0; i < Nodes.Size(); i++)
		{
			if (Nodes[i].IsUpgrade())
				break;

			Nodes[i].Basis.GeneType = Nodes[i].GetGeneType();
			weap.ModGraph.Nodes.Push(Nodes[i].Basis.Copy());
		}

		Simulate();
		Weap.SetupMagazines();
	}

	void PostCommit()
	{
		RebuildGeneInventory();

		// Nodes which contained a pointer to a real gene item will have had
		// their data invalidated by whoever manipulates the player's inventory
		// after calling `Commit()`. Convert them to virtual genes

		for (uint i = 0; i < Nodes.Size(); i++)
		{
			let rGene = BIO_WeaponModSimGeneReal(Nodes[i].Gene);

			if (rGene == null)
				continue;

			if (rGene.Gene == null)
			{
				rGene = null;
				let g = new('BIO_WeaponModSimGeneVirtual');
				g.Type = Nodes[i].Basis.GeneType;
				Nodes[i].Gene = g;
				Nodes[i].Update();
			}
		}
	}

	// Accessibility checker ///////////////////////////////////////////////////

	bool NodeAccessible(uint node) const
	{
		if (node >= Nodes.Size())
		{
			Console.Printf(Biomorph.LOGPFX_ERR ..
				"Queried accessibility of illegal node %d.", node);
			return false;
		}

		if (node == 0) // Home node
			return true;

		// Completely unconnected nodes are permanently accessible
		if (Nodes[node].Basis.Neighbors.Size() < 1 ||
			Nodes[node].Basis.FreeAccess)
			return true;

		Array<uint> visited;

		if (NodeAccessibleViaFreeAccess(node, visited))
			return true;

		return NodeAccessibleImpl(node, 0, visited);
	}

	private bool NodeAccessibleImpl(uint tgt, uint cur,
		in out Array<uint> visited) const
	{
		if (cur == tgt)
			return true;

		visited.Push(cur);
		bool curActive = Nodes[cur].IsActive();

		for (uint i = 0; i < Nodes[cur].Basis.Neighbors.Size(); i++)
		{
			uint ndx = Nodes[cur].Basis.Neighbors[i];

			if (visited.Find(ndx) != visited.Size())
				continue;

			for (uint j = 0; j < Nodes[ndx].Basis.Neighbors.Size(); j++)
			{
				let nb = Nodes[ndx].Basis.Neighbors[j];

				if (Nodes[nb].IsActive() && curActive &&
					NodeAccessibleImpl(tgt, ndx, visited))
					return true;
			}
		}

		return false;
	}

	private bool NodeAccessibleViaFreeAccess(uint tgt,
		in out Array<uint> visited) const
	{
		for (uint i = 0; i < Nodes.Size(); i++)
		{
			if (!Nodes[i].Basis.FreeAccess) continue;

			for (uint j = 0; j < Nodes[i].Basis.Neighbors.Size(); j++)
			{
				let nb = Nodes[i].Basis.Neighbors[j];

				if (NodeAccessibleImpl(tgt, i, visited))
					return true;
			}
		}

		return false;
	}

	// Extended accessibility checker //////////////////////////////////////////

	bool NodeAccessibleEx(uint node, in out Array<uint> active) const
	{
		if (node >= Nodes.Size())
		{
			Console.Printf(Biomorph.LOGPFX_ERR ..
				"Queried accessibility of illegal node %d.", node);
			return false;
		}

		if (node == 0) // Home node
			return true;

		// Completely unconnected nodes are permanently accessible
		if (Nodes[node].Basis.Neighbors.Size() < 1 ||
			Nodes[node].Basis.FreeAccess)
			return true;

		Array<uint> visited;

		if (NodeAccessibleViaFreeAccessEx(node, active, visited))
			return true;

		return NodeAccessibleExImpl(node, 0, active, visited);
	}

	private bool NodeAccessibleExImpl(uint tgt, uint cur,
		in out Array<uint> active, in out Array<uint> visited) const
	{
		if (cur == tgt)
			return true;

		visited.Push(cur);
		bool curActive = active.Find(cur) != active.Size();

		for (uint i = 0; i < Nodes[cur].Basis.Neighbors.Size(); i++)
		{
			uint ndx = Nodes[cur].Basis.Neighbors[i];

			if (visited.Find(ndx) != visited.Size())
				continue;

			for (uint j = 0; j < Nodes[ndx].Basis.Neighbors.Size(); j++)
			{
				let nb = Nodes[ndx].Basis.Neighbors[j];

				if (active.Find(nb) != active.Size() && curActive &&
					NodeAccessibleExImpl(tgt, ndx, active, visited))
					return true;
			}
		}

		return false;
	}

	private bool NodeAccessibleViaFreeAccessEx(uint tgt,
		in out Array<uint> active, in out Array<uint> visited) const
	{
		for (uint i = 0; i < Nodes.Size(); i++)
		{
			if (!Nodes[i].Basis.FreeAccess) continue;

			for (uint j = 0; j < Nodes[i].Basis.Neighbors.Size(); j++)
			{
				let nb = Nodes[i].Basis.Neighbors[j];

				if (NodeAccessibleExImpl(tgt, i, active, visited))
					return true;
			}
		}

		return false;
	}

	// Helpers specifically for the weapon mod. menu ///////////////////////////

	string GetNodeTooltip(uint node) const
	{
		if (Nodes[node].IsUpgrade())
		{
			let upgr = Nodes[node].Upgrade;

			return String.Format(
				StringTable.Localize("$BIO_MENU_WEAPMOD_UPGRADE"),
				GetDefaultByType(upgr.GetOutput()).ColoredTag(),
				upgr.MutagenCost(),
				GetDefaultByType('BIO_Muta_General').GetTag()
			);
		}

		let n = Nodes[node];

		if (!n.Valid)
		{
			bool _ = false;
			string reason = "";
			[_, reason] = n.Compatible(AsConst());

			return String.Format(
				StringTable.Localize("$BIO_WMOD_INCOMPAT_TEMPLATE"),
				StringTable.Localize(n.GetTag()),
				StringTable.Localize(reason)
			);
		}

		return Nodes[node].Gene.GetDescriptionTooltip(Weap.AsConst(), n.Multiplier);
	}

	string GetGeneSlotTooltip(uint slot) const
	{
		return Genes[slot].GetSummaryTooltip();
	}

	// Other introspective helpers /////////////////////////////////////////////

	class<BIO_Gene> GetGeneType(uint gene, bool node) const
	{
		class<BIO_Gene> ret = null;

		if (node)
			ret = Nodes[gene].Gene.GetType();
		else
			ret = Genes[gene].GetType();

		return ret;
	}

	// If `node` is `false`, test `Genes[gene]` instead of `Nodes[gene]`.
	bool TestDuplicateAllowance(uint gene, bool node) const
	{
		BIO_WeaponModSimGene toTest;

		if (node)
		{
			if (!Nodes[node].IsOccupied())
			{
				Console.Printf(
					Biomorph.LOGPFX_ERR ..
					"Attempted to test duplicate allowance of gene at unoccupied node %d.",
					gene
				);
				return false;
			}

			toTest = Nodes[gene].Gene;
		}
		else
		{
			if (Genes[gene] == null)
			{
				Console.Printf(
					Biomorph.LOGPFX_ERR ..
					"Attempted to test duplicate allowance of gene at empty slot %d.",
					gene
				);
				return false;
			}

			toTest = Genes[gene];
		}

		for (uint i = 0; i < Nodes.Size(); i++)
		{
			let mod = Nodes[i].GetModifier();

			if (mod == null)
				continue;

			if (mod.AllowMultiple())
				continue;

			if (mod.GetClass() == toTest.Modifier.GetClass())
				return false;
		}

		return true;
	}

	// Returns `false` if there's no gene to remove, or if removing the gene
	// would render other nodes inaccessible.
	bool CanRemoveGeneFrom(uint node) const
	{
		if (!Nodes[node].IsOccupied())
			return false;

		Array<uint> active;
		active.Push(0);

		for (uint i = 1; i < Nodes.Size(); i++)
			if (Nodes[i].IsActive() && i != node)
				active.Push(i);

		for (uint i = 1; i < active.Size(); i++)
		{
			if (!NodeAccessibleEx(active[i], active))
				return false;
		}

		return true;
	}

	BIO_WeaponModSimNode GetNodeByPosition(int x, int y, bool includeFake = false)
	{
		for (uint i = 0; i < Nodes.Size(); i++)
		{
			if (!includeFake && Nodes[i].IsUpgrade())
				continue;

			if (Nodes[i].Basis.PosX == x && Nodes[i].Basis.PosY == y)
				return Nodes[i];
		}
	
		return null;
	}

	bool IsFull() const
	{
		for (uint i = 1; i < Nodes.Size(); i++)
		{
			if (Nodes[i].IsUpgrade())
				continue;

			if (!Nodes[i].IsOccupied())
				return false;
		}

		return true;
	}

	bool IsValid() const { return Valid; }

	// Other internal implementation details ///////////////////////////////////

	private void RebuildGeneInventory()
	{
		Genes.Clear();

		for (Inventory i = weap.Owner.Inv; i != null; i = i.Inv)
		{
			let gene = BIO_Gene(i);

			if (gene == null)
				continue;

			let simGene = new('BIO_WeaponModSimGeneReal');
			simGene.Gene = gene;
			simGene.UpdateModifier();
			Genes.Push(simGene);
		}

		while (Genes.Size() < BIO_Player(weap.Owner).MaxGenesHeld)
			Genes.Push(null);
	}

	// Miscellaneous ///////////////////////////////////////////////////////////

	readOnly<BIO_Weapon> GetWeapon() const { return Weap.AsConst(); }
	readOnly<BIO_WeaponModSimulator> AsConst() const { return self; }
}