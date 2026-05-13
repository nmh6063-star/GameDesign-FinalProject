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

  * If the **current enemy** has **no** poison: apply **10** poison stacks.
  * If they **already** have poison: **that enemy** loses **half** of their poison stacks (rounded down).

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

  * Freeze **all** enemies for **8** seconds (8 freeze stacks).
  * While frozen, enemies **cannot attack** (their attack turn is not executed until they thaw or break free early).
  * Each second they may **break free** early: chance = (current HP%) × 60% + 5% per elapsed second (no damage over time).
  * Gain **50 Shield** immediately.

* **Giant Orb**

  * Randomly choose one ball currently inside box.
  * Chosen ball gains:

    * **x2 attack multiplier**
    * On hit, damage/effects trigger **2 times**
    * Visual size becomes **x3**

* **Consume Core**

  * Destroy one ball currently inside box.
  * Then deal **50 damage**.

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

  * Deal **12 damage** to the current enemy **6 times** (72 total).

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

* **Shower**

  * For **30 seconds**:

    * Continuously spawn Rank 1 balls into box at intervals.

* **Baator's Flame** *(R7)*

  * Convert all DoT on every enemy to Burn: Poison ×1.5, Thunder ×2, Freeze ×10 stacks.

* **Thunder Strike** *(R7)*

  * If **no** enemy has thunder stacks: give the **current enemy** **15** thunder stacks (no damage this cast).
  * Otherwise: each enemy with thunder takes **2% × stacks** of their current HP as damage.

* **Elbaph's Power** *(R7)*

  * 15s: ball sizes grow 0→+100% and direct damage scales 50→150%.

* **Tide Turner** *(R4)*

  * Shot alongside X other balls: deal X × total damage dealt by those balls this turn.

* **Thunder Fang** *(R3)*

  * 5% current HP to target + 5% to others. Apply 5/3 ⚡ thunder stacks.

* **Storm Surge** *(R6)*

  * 10% max HP to all enemies + 20 ⚡ thunder stacks to each.

* **Gatekeeper** *(R6)*

  * Next 3 damage instances: convert 50% of each hit into Shield.

* **Chaos Slash** *(R5)*

  * 5 random hits for 15 (can hit player). Player hits apply Fragile (+20% dmg taken) until next shoot.

* **Decay** *(R3)*

  * Permanently reduce active enemy's max HP by 10 (5×2) this battle.

* **Regeneration** *(R3)*

  * Heal 3 HP/s for 10 seconds.

* **Weakness Brand** *(R4)*

  * Active enemy takes +30% direct damage for 3 shoots (🔻 Brand ×N).

* **Lifesteal Field** *(R4)*

  * This battle: heal 10% of all direct damage dealt (🩸 Lifesteal).

* **Fortress** *(R4)*

  * Gain 50 Shield. Take 15 raw HP damage (bypasses shield, HP floored at 1).

* **Guillotine** *(R5)*

  * Deal 25% of active enemy's MISSING HP.

* **Second Wind** *(R6)*

  * When HP drops below 30%: heal 40% max HP (first use) or 10% missing HP (repeat).

* **Overkill** *(R6)*

  * Deal 40 damage. For rest of battle: excess damage on kills spills to next enemy.
