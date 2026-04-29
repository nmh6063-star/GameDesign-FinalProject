## Rank 1

* **Strike**

  * Immediately deal **1 damage to all enemies**.
  * This is direct damage and is not considered a status effect.

* **Mend**

  * Immediately restore **3 HP** to the player.
  * Healing cannot exceed max HP unless overheal exists elsewhere in the system.

* **Venom**

  * Apply **Poison** to all targeted enemies with:

	* **10 stacks**
	* **1 strength**
  * While Poison is active:

	* Enemy takes damage every second equal to current **Poison strength**.
	* Poison stacks are consumed over time during ticking.
  * If stacks reach 0, Poison ends.

* **Ember**

  * Apply **Burn** to all targeted enemies with:

	* **10 stacks**
	* **2 strength**
  * Burn only triggers when the enemy performs an attack.
  * Each trigger:

	* Enemy takes damage equal to Burn strength.
	* Consume Burn stack(s).
  * Burn ends when stacks reach 0.

* **Guard**

  * Gain **5 Shield**.
  * Shield acts as temporary HP.
  * Incoming damage is deducted from Shield before HP.
  * UI should visually display Shield separately on health bar.

* **Critical**

  * On use, roll 50% chance:

	* Success: deal **5 damage**
	* Failure: deal **1 damage**

* **Refresh**

  * Gain **+1 mana** immediately.

---

## Rank 2

* **Heavy Strike**

  * Immediately deal **10 damage** to one target enemy.

* **Recovery**

  * Heal **25% of missing HP**.
  * Example:

	* Max HP = 100
	* Current HP = 60
	* Missing HP = 40
	* Heal = 10

* **Frost Touch**

  * Apply **Freeze** with:

	* **5 stacks**
  * While Freeze is active:

	* Enemy action timer is paused.
  * Every time the player drops one ball:

	* Consume 1 Freeze stack.
  * Freeze ends when stacks reach 0.

* **Iron Guard**

  * Gain **20 Shield**.
  * Shield absorbs damage before HP.

* **Triple Shot**

  * Perform 3 separate hits.
  * Each hit:

	* Randomly choose an enemy.
	* Deal **5 damage**.
  * Same enemy may be chosen multiple times unless restricted by implementation.

* **Scatter Drop**

  * Spawn/drop **2 random balls** into the box.
  * Eligible ball ranks:

	* Rank 1
	* Rank 2
	* Rank 3

* **Critical Strike**

  * 50% chance:

	* Deal **5 damage to all enemies**
  * Otherwise:

	* Deal **5 damage to one enemy**

* **Pollution**

  * If target enemy currently has Poison:

	* Double current Poison **strength**
  * Poison stacks remain unchanged unless otherwise designed.

* **FireBurn**

  * Apply Burn with:

	* **10 stacks**
	* **5 strength**
  * Burn triggers whenever enemy attacks.

---

## Rank 3

* **Power Slash**

  * Deal **30 direct damage** to one target.

* **Toxic Burst**

  * Apply Poison:

	* **30 stacks**
	* **1 strength**

* **Fireball**

  * Deal **5 direct damage**
  * Apply Burn:

	* **5 stacks**
	* **10 strength**

* **Ice Lance**

  * Deal **5 direct damage**
  * Apply Freeze:

	* **5 stacks**

* **Reinforce**

  * Gain **+3 attack damage** for the rest of current battle.
  * Applies to future direct attacks unless otherwise limited.

* **いp** *(appears to be incomplete / placeholder text)*

  * No valid effect specified.
  * Recommend replacing or removing.

* **Echo Shot**

  * Repeat the most recently resolved damage + effect ability.
  * Should copy:

	* damage value
	* status effects
	* targeting logic if desired
  * If no previous valid ability exists:

	* either fail gracefully or do nothing.

* **Charm**

  * Apply Charm:

	* **5 stacks**
  * For enemy’s next 5 attacks:

	* Enemy attacks a random enemy unit instead of player.
  * If no other enemy exists:

	* Attack is redirected back to player.
  * Consume 1 Charm stack per enemy attack.

---

## Rank 4

* **Cleave**

  * Deal **20 damage to all enemies**.

* **Greater Heal**

  * Heal **50% of missing HP**.

* **Bomb Orb**

  * Create delayed effect.
  * After **10 seconds**:

	* Deal **50 damage to all enemies**.

* **Chain Spark**

  * Hit enemies sequentially 3 times.
  * First hit damage = **10**
  * Second hit damage = **20**
  * Third hit damage = **40**
  * Each next target must be different from immediately previous target.

* **Mirror Shield**

  * Reflect next incoming damage instance.
  * Reflect only numeric damage.
  * Does **not** reflect debuffs/status effects.

* **Corrupt Field**

  * Create hazard zone inside box.
  * Any ball passing through / shot from zone gains:

	* Poison:

	  * **10 stacks**
	  * **2 strength**

---

## Rank 5

* **Critical Edge**

  * Randomly choose one damage value:

	* 5
	* 10
	* 20
	* 100
  * Deal chosen damage to target.

* **Freeze Wave**

  * Apply Freeze:

	* **5 stacks**
  * Affect all enemies.

* **Giant Orb**

  * Randomly choose one ball currently inside box.
  * Chosen ball gains:

	* **x2 attack multiplier**
	* On hit, damage/effects trigger **2 times**
	* Visual size becomes **x3**

* **Consume Core**

  * Destroy one ball currently inside box.
  * Then deal **100 damage**.

* **Upgrade Pulse**

  * In a small area inside box:

	* Upgrade random ball(s) by +1 rank.

* **Poison Rain**

  * Apply Poison to all enemies:

	* **20 stacks**
	* **1 strength**

* **Time Drift**

  * Slow game time for **10 seconds**.
  * Recommended to affect:

	* enemy timers
	* movement speed
	* projectile speed

---

## Rank 6

* **Meteor Crash**

  * Deal **100 damage to all enemies**.

* **Full Recovery**

  * Restore HP to full.
  * Remove all negative debuffs from player.

* **Chaos Rain**

  * Spawn **5 random balls** into box.
  * Eligible ranks:

	* Rank 1
	* Rank 2
	* Rank 3
  * Consume **1 mana**.

* **Overcharge**

  * Gain **+10 attack damage** for current battle.

* **Mass Morph**

  * Upgrade all Rank 1 and Rank 2 balls by +1 rank.

* **Reflect Wall**

  * For next **20 seconds**:

	* Reflect all enemy direct damage.
  * Does not reflect status effects unless explicitly added.

* **Giant Core**

  * Choose one ball inside box.
  * Ball gains:

	* **x3 attack**
	* Damage/effect triggers twice
	* Visual size x3

---

## Rank 7

* **Final Judgment**

  * Deal **1000 damage** to one target enemy.

* **Apocalypse**

  * Deal **100 damage to all enemies**.

* **Resurrection**

  * Passive or instant-use depending system design.
  * If player dies:

	* Revive with low HP.
  * Cannot stack multiple Resurrection effects.

* **Time Stop**

  * Immediately remove/delete **50% of balls currently in box**.
  * Freeze all enemy timers for **20 seconds**.

* **Magic Flood**

  * Fill box with water.

  * Balls inside water float upward due to buoyancy.

  * Apply one random enchantment to each ball:

  * Poison enchant:

	* 10 stacks
	* 2 strength

  * Fire enchant:

	* 5 stacks
	* 5 strength

  * Ice enchant:

	* 5 Freeze stacks

* **Miracle Cascade**

  * Trigger random effects based on Rank:

	* Rank 3 effect
	* Rank 4 effect
	* Rank 5 effect
  * Can include damage and status effects.

* **Sacrifice Nova**

  * Immediately lose **50% current HP**.
  * After **10 seconds**:

	* Deal **500 damage to all enemies**.

* **1 Shower**

  * For **30 seconds**:

	* Continuously spawn Rank 1 balls into box at intervals.
