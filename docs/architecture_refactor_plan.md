# Roguelike Project Architecture Refactor Plan (Revised)

## 1. Project Summary

This project is a Godot roguelike built around four core gameplay pillars:

1. **Box / playfield**: the player drops balls into a box-like physics space.
2. **Balls**: every ball owns its own effect and merge behavior.
3. **Enemies**: every enemy owns its own attack/effect package.
4. **Map / run progression**: after each battle, the player chooses rewards or modifiers, advances through a branching map, and eventually reaches a boss.

The main design constraint is content growth. This project will eventually have many more:

- ball types
- enemy types
- modifiers
- encounters
- bosses

So the architecture should optimize for one thing above all else:

> **Adding a new ball or enemy should usually mean creating or configuring data, not editing a large central script.**

---

## 2. Current Code Snapshot

Current important scripts:

- `script/ball/game_ball.gd`
- `script/ball/behaviors/ball_behavior.gd`
- `script/ball/resolve/merge_resolver.gd`
- `script/ball/resolve/special_ball_resolver.gd`
- `script/entities/enemy.gd`
- `script/session/game_manager.gd`
- `script/map/map_generator.gd`
- `script/core/global.gd`
- scene-embedded battle orchestration inside `scenes/main.tscn`

The project already has a useful start:

- some behavior separation for balls
- dedicated resolver scripts for merge/combat/special effects
- a map scene separated from the battle scene
- some UI scripts already split out

That said, the current structure still makes content scaling harder than it needs to be.

---

## 3. Current Maintainability Problems

### 3.1 Responsibilities are mixed

Examples:

- `game_ball.gd` handles physics, aiming, drop input, rendering, sizing, and behavior checks.
- `enemy.gd` handles health, attack timing, movement, player damage, and UI bar updates.
- `game_manager.gd` handles turn flow, merge results, special effects, combat, shoot ammo, target visibility, player energy, and battle-end flow.
- `main.tscn` contains inline script logic for spawning balls, wiring signals, randomizing balls, and updating battle UI.

This makes the code harder to reason about and harder to extend safely.

### 3.2 Hard coupling to scene paths

There are direct references such as:

- `/root/Main/Target`
- `/root/Main/PlayerHolder/Player`
- `/root/Main/GameManager`

This is fragile. Renaming nodes or moving scenes can silently break gameplay.

### 3.3 Global state is overloaded

`script/core/global.gd` currently stores things like:

- battle phase
- player HP
- player energy
- map generation state
- current tile
- current ball in play

This turns `Global` into a dependency sink.

### 3.4 Ball and enemy behavior is too coordinator-driven

Right now, behavior is still too dependent on runtime branching in central scripts.

That becomes painful once the game has:

- many ball effects
- many enemy actions
- unique merge exceptions
- status effects
- boss-only mechanics
- modifiers that alter existing content

The bigger the content pool becomes, the worse a central switch-based coordinator gets.

### 3.5 Runtime logic and presentation are tightly coupled

Entity scripts directly update UI nodes, health bars, and visuals while also handling gameplay logic.

This reduces reuse and makes testing harder.

---

## 4. Refactor Goals

The refactor should optimize for:

- **high cohesion**: each script has one clear job
- **low coupling**: systems communicate through narrow interfaces, signals, and state/context objects
- **content-owned behavior**: each ball owns its own effect setup, and each enemy owns its own action/effect setup
- **data-driven expansion**: new balls and enemies should mostly be added through resources
- **small meaningful files**: focused scripts, but not unnecessary file explosion
- **scene-safe code**: avoid hard-coded root paths
- **clear battle orchestration**: one place decides resolution order, but not the concrete logic of every content type
- **easy content scaling**: adding a new ball or enemy should usually avoid changing existing battle code

---

## 5. Core Design Principles

### 5.1 Composition over inheritance

Do not create deep subclass trees such as:

- `FireBall`
- `PoisonBall`
- `HealBall`
- `BossBall`
- `UltraBossPoisonBall`

Likewise, do not create deep enemy inheritance trees like:

- `SlimeEnemy`
- `PoisonSlimeEnemy`
- `BossPoisonSlimeEnemy`

Instead, define balls and enemies through composition:

- a **data resource**
- a **node script**
- a small set of **effect/action resources**

### 5.2 Ball effects belong to the ball

Every ball should own its effect configuration.

That means the ball definition decides:

- what merge rule it uses
- what effects it has
- what tags it carries
- how often it appears
- how it should look

The battle system should not need a giant `match` for every ball type.

### 5.3 Enemy effects/actions belong to the enemy

Every enemy should own its own behavior package through data.

That means the enemy definition decides:

- what actions it can perform
- what effect resources it has
- what timing/cooldown rules apply
- what tags and rewards it has

The battle system should decide **when** an enemy acts, but the enemy resource should decide **what** that action does.

### 5.4 Use interface-style resources as contracts

Godot/GDScript does not have strong interfaces in the same way as some other languages, so the practical version is:

- a base `Resource` script that defines the contract
- concrete resources/scripts that implement the behavior

Recommended contracts:

- `MergeRule`
- `BallEffect`
- `EnemyAction`
- `ModifierEffect`

These are the main extensibility points for content.

### 5.5 Data-driven content

Use `Resource` assets for content definitions:

- `ball_data.gd`
- `enemy_data.gd`
- `modifier_data.gd`

Optional later:

- encounter data
- map node data

This makes adding new content much cheaper.

### 5.6 Keep state and orchestration separate

Keep a clear distinction between:

- **definition**: design-time static data
- **runtime state**: mutable battle/run data
- **orchestration**: turn order, resolution order, and shared combat flow
- **presentation**: visuals and UI only

### 5.7 Split late, not early

Keep the default structure simple.

Recommended default for gameplay content:

- one node script
- one data resource
- reusable effect/action resources

Only split further when a concept becomes clearly overloaded.

---

## 6. Proposed Target Structure

```text
res://
  scenes/
    battle/
      battle_scene.tscn
    map/
      map_scene.tscn
    shared/

  script/
    core/
      run_state.gd
      scene_router.gd

    battle/
      battle_controller.gd
      battle_state.gd
      battle_rules.gd
      battle_context.gd
      contracts/
        merge_rule.gd
        ball_effect.gd
        enemy_action.gd
        modifier_effect.gd

    ball/
      ball.gd
      ball_data.gd
      effects/
        heal_touching_effect.gd
        duplicate_touching_effect.gd
        multiply_touching_effect.gd
      merge_rules/
        level_merge_rule.gd
        no_merge_rule.gd

    enemy/
      enemy.gd
      enemy_data.gd
      actions/
        direct_attack_action.gd
        apply_status_action.gd
        summon_action.gd
        shield_self_action.gd

    modifier/
      modifier_data.gd
      effects/
      modifier_rules.gd

    map/
      map_controller.gd
      map_generator.gd
      map_state.gd

    ui/
      damage_floater.gd
      line_indicator.gd
      shoot_ammo_hud.gd
```

Recommended content layout:

```text
res://content/
  balls/
    basic_attack_ball.tres
    heal_ball.tres
    duplicate_ball.tres
    multiply_ball.tres

  enemies/
    slime.tres
    poison_slime.tres
    boss_slime.tres

  modifiers/
    extra_merge_damage.tres
    start_with_shot.tres
```

### Why this structure is easier to scale

Because it gives a simple default rule:

- to add a **new ball**, create a new `ball_data` resource and reuse existing merge/effect resources when possible
- to add a **new enemy**, create a new `enemy_data` resource and reuse existing action/effect resources when possible
- only add a new script when the mechanic itself is genuinely new

That keeps content growth cheap.

---

## 7. Recommended Responsibility Split

## 7.1 Battle layer

### `battle_controller.gd`

Owns scene wiring only:

- references to playfield, target, UI, player, and active enemy nodes
- battle start/end flow
- spawn requests
- signal wiring
- applying queued results from the battle context

It should **not** contain concrete ball logic or concrete enemy behavior logic.

### `battle_state.gd`

Stores battle-level mutable state such as:

- player HP
- player energy
- turn phase
- ammo state
- active modifiers
- queued results/events

### `battle_rules.gd`

Owns shared gameplay flow:

- merge resolution order
- turn resolution order
- when ball effects may trigger
- when enemy actions may trigger
- how shared combat phases resolve

Important boundary:

- `battle_rules.gd` decides **when** behaviors run
- ball effects decide **what ball effects do**
- enemy actions decide **what enemy actions do**

This is the most important separation in the whole plan.

### `battle_context.gd`

Provides a narrow API to behaviors so they do not need to know scene structure.

Example responsibilities:

- get active balls
- get active enemy
- find touching balls
- queue ball removal
- queue ball spawn
- change level/value
- heal player
- damage enemy
- damage player
- apply status
- add ammo
- read battle state

This lets effect/action resources stay reusable and low-coupling.

---

## 7.2 Ball layer

### `ball_data.gd`

This is the core definition of a ball.

Recommended fields:

- `id`
- `display_name`
- `icon`
- `sprite`
- `base_size`
- `tags`
- `spawn_weight`
- `rarity`
- `merge_rule: MergeRule`
- `effects: Array[BallEffect]`

This should be a `Resource`.

### `ball.gd`

This is the runtime node for an individual ball.

Recommended responsibilities:

- physics body and collision shape
- level / ball-local runtime state
- setup/drop state
- movement and collision callbacks
- visuals owned by the ball node
- local signals
- helper methods needed by effects

The key point is:

> `ball.gd` owns the runtime ball node, but `ball_data.gd` owns the ball's behavior package.

---

## 7.3 Ball behavior model

Each ball should carry its own effect configuration through `ball_data.gd`.

Recommended pattern:

- `ball_data.merge_rule`
- `ball_data.effects`

Example:

- normal attack ball  
  - `merge_rule = LevelMergeRule`
  - `effects = []`

- heal ball  
  - `merge_rule = NoMergeRule`
  - `effects = [HealTouchingEffect]`

- duplicate ball  
  - `merge_rule = NoMergeRule`
  - `effects = [DuplicateTouchingEffect]`

- multiply ball  
  - `merge_rule = NoMergeRule`
  - `effects = [MultiplyTouchingEffect]`

This means the ball owns its effect package directly.

### `BallEffect` contract

```gdscript
extends Resource
class_name BallEffect

func can_trigger(ctx: BattleContext, source: Ball) -> bool:
	return true

func apply(ctx: BattleContext, source: Ball) -> void:
	push_error("BallEffect.apply() must be implemented")
```

### `MergeRule` contract

```gdscript
extends Resource
class_name MergeRule

func can_merge(ctx: BattleContext, a: Ball, b: Ball) -> bool:
	return false

func resolve(ctx: BattleContext, a: Ball, b: Ball) -> void:
	push_error("MergeRule.resolve() must be implemented")
```

### Ball resolution flow

1. `battle_controller.gd` gathers active balls.
2. `battle_controller.gd` builds `BattleContext`.
3. `battle_rules.gd` checks merge candidates.
4. For each ball, `battle_rules.gd` delegates merge behavior to `ball.data.merge_rule`.
5. Then `battle_rules.gd` runs all `ball.data.effects`.
6. Effects modify battle outcome through `BattleContext`.
7. `battle_controller.gd` applies queued scene/UI updates.

This is how each ball keeps its own effect while the battle layer stays generic.

---

## 7.4 How to add a new ball

There should be two normal cases.

### Case A: reuse existing behavior

This should be the common case.

Steps:

1. Create a new `.tres` under `content/balls/`.
2. Fill in:
   - id
   - display name
   - visuals
   - spawn values
   - merge rule
   - effects
3. Add it to the spawn pool or reward pool.
4. Test it.

Example:

- a stronger heal ball can reuse `HealTouchingEffect`
- a rare duplicate variant can reuse `DuplicateTouchingEffect`

This should require **no new coordinator code**.

### Case B: add one new effect

Steps:

1. Implement one new `BallEffect`.
2. Create a `.tres` ball resource using that effect.
3. Add it to the pool.
4. Test it.

Example:

- `bomb_touching_effect.gd`
- `bomb_ball.tres`

This is the right expansion path because it adds one reusable effect, not one more branch in central battle logic.

---

## 7.5 Enemy layer

### `enemy_data.gd`

This is the core definition of an enemy.

Recommended fields:

- `id`
- `display_name`
- `max_hp`
- `sprite`
- `tags`
- `reward_table`
- `attack_interval`
- `actions: Array[EnemyAction]`

Optional later:

- phase data
- resistances
- loot tiers
- move behavior config

### `enemy.gd`

This is the runtime enemy node.

Recommended responsibilities:

- current HP
- attack timer / cooldown tracking
- local animation hooks
- local signals
- health bar updates
- local movement if needed

The key point is:

> `enemy.gd` owns the enemy node, but `enemy_data.gd` owns the enemy's behavior package.

---

## 7.6 Enemy behavior model

Each enemy should carry its own actions through `enemy_data.gd`.

Examples:

- slime  
  - `actions = [DirectAttackAction]`

- poison slime  
  - `actions = [DirectAttackAction, ApplyStatusAction]`

- summoner enemy  
  - `actions = [SummonAction]`

- defensive boss  
  - `actions = [ShieldSelfAction, DirectAttackAction]`

### `EnemyAction` contract

```gdscript
extends Resource
class_name EnemyAction

func can_use(ctx: BattleContext, enemy: Enemy) -> bool:
	return true

func execute(ctx: BattleContext, enemy: Enemy) -> void:
	push_error("EnemyAction.execute() must be implemented")
```

### Enemy resolution flow

1. `battle_rules.gd` checks whether the enemy may act this turn.
2. It iterates through `enemy.data.actions`.
3. Each action decides if it can be used.
4. The chosen action executes through `BattleContext`.

This keeps enemy behavior attached to the enemy instead of burying it in one big battle script.

---

## 7.7 How to add a new enemy

### Case A: reuse existing actions

This should be the common case.

Steps:

1. Create a new `.tres` under `content/enemies/`.
2. Fill in:
   - id
   - stats
   - visuals
   - tags
   - reward data
   - action list
3. Place it in encounters.
4. Test it.

Example:

- a stronger slime can reuse `DirectAttackAction`
- a poison variant can reuse `DirectAttackAction + ApplyStatusAction`

This should require **no new battle coordinator code**.

### Case B: add one new action

Steps:

1. Implement one new `EnemyAction`.
2. Create an enemy resource that references it.
3. Add the enemy to encounter content.
4. Test it.

Example:

- `drain_energy_action.gd`
- `mana_thief_enemy.tres`

Again, the new mechanic expands the action library, not the central coordinator.

---

## 7.8 Modifier layer

Modifiers should follow the same pattern.

Recommended model:

- `modifier_data.gd` defines the modifier
- `modifier_data.gd` references one or more `ModifierEffect` resources
- `modifier_rules.gd` decides when modifier hooks may run
- active modifiers live in `RunState` or `BattleState`

Possible hook points:

- on battle start
- on ball spawn
- on merge
- on player attack
- on enemy turn
- on reward generation
- on map node enter

---

## 7.9 Map layer

Recommended split:

- `map_controller.gd`
- `map_generator.gd`
- `map_state.gd`

Keep it simple at first.

The map only needs to know enough to:

- generate progression
- select next encounters/rewards
- update run progression

Do not over-abstract the map before the battle loop is stable.

---

## 8. Specific Refactor Recommendations for Existing Files

### `script/core/global.gd`

Refactor into a smaller autoload:

- rename/rework toward `RunState`
- keep only cross-scene run data
- remove scene node references
- remove scene-path lookups

Good data for `RunState`:

- current run HP / max HP
- unlocked balls
- active modifiers
- map progress
- currency / rewards

Bad data for `RunState`:

- direct references to battle nodes
- temporary scene-only pointers
- active scene lookups

### `script/session/game_manager.gd`

Split into:

- `battle_controller.gd`
- `battle_state.gd`
- `battle_rules.gd`
- `battle_context.gd`

Important rule:

- move concrete ball logic into `BallEffect` / `MergeRule`
- move concrete enemy logic into `EnemyAction`

Do **not** let `battle_rules.gd` become a giant replacement switch file.

### `script/ball/game_ball.gd`

Split into:

- `ball.gd`
- `ball_data.gd`

Keep the ball node focused on local runtime and visuals.

Move ball-specific mechanics into resources attached to `ball_data.gd`.

### `script/entities/enemy.gd`

Split into:

- `enemy.gd`
- `enemy_data.gd`

Keep the enemy node focused on local runtime and visuals.

Move enemy-specific behavior into resources attached to `enemy_data.gd`.

### `scenes/main.tscn` inline script

Move inline logic into:

- `script/battle/battle_controller.gd`

This should be one of the first changes.

### `script/map/map_generator.gd`

Split responsibilities into:

- generation
- selection/routing
- state updates

Also remove debug prints and string-based node type logic over time.

---

## 9. Coding Rules for This Project

### 9.1 One script, one reason to change

If one file changes because of both UI work and rule work, it is probably doing too much.

### 9.2 Battle orchestration should be generic

Good:

- `battle_rules.gd` calls `merge_rule.resolve(...)`
- `battle_rules.gd` calls `effect.apply(...)`
- `battle_rules.gd` calls `action.execute(...)`

Bad:

- `battle_rules.gd` contains one large `match` for every ball and enemy in the game

### 9.3 Ball effects should be ball-owned

When adding a new ball, the first question should be:

> Can this be made by creating a new `ball_data` resource and attaching existing `MergeRule` / `BallEffect` resources?

If yes, do not edit central battle scripts.

### 9.4 Enemy actions should be enemy-owned

When adding a new enemy, the first question should be:

> Can this be made by creating a new `enemy_data` resource and attaching existing `EnemyAction` resources?

If yes, do not edit central battle scripts.

### 9.5 Systems should work through explicit inputs

Bad:

- searching `/root/Main/...`
- scanning the scene tree from arbitrary scripts

Better:

- controller passes references
- behaviors use `BattleContext`

### 9.6 Prefer reusable mechanic libraries

Over time, build small reusable libraries of:

- merge rules
- ball effects
- enemy actions
- modifier effects

That is the scalable content layer.

### 9.7 Default to two files per gameplay concept

For most content, the default should remain:

- one node script
- one data resource

Only add more files when there is real pressure.

---

## 10. Recommended Patterns

Use these patterns consistently:

- **Composition** for content assembly
- **Controller + state + rules** for battle flow
- **Interface-style resources** for behavior
- **Resource-driven content** for expansion
- **Context object** for safe, reusable effect/action execution

Avoid these patterns:

- giant singleton that knows everything
- hard-coded scene path dependencies
- one battle coordinator with a branch per content type
- deep inheritance trees for balls or enemies
- splitting one gameplay concept into too many tiny files too early

---

## 11. Suggested Refactor Order

### Phase 1: Structural cleanup

1. Move the inline script from `main.tscn` into `battle_controller.gd`.
2. Remove hard-coded `/root/Main/...` lookups.
3. Slim down `Global` into `RunState`.

### Phase 2: Battle architecture

1. Introduce `BattleState`.
2. Introduce `BattleContext`.
3. Keep `battle_controller.gd` focused on scene orchestration.
4. Keep `battle_rules.gd` focused on resolution order only.

### Phase 3: Ball-owned and enemy-owned behavior

1. Add `ball_data.gd`, `enemy_data.gd`, and `modifier_data.gd`.
2. Add base contracts:
   - `MergeRule`
   - `BallEffect`
   - `EnemyAction`
   - `ModifierEffect`
3. Convert current ball mechanics into ball-owned resources.
4. Convert current enemy behavior into enemy-owned resources.

### Phase 4: Content migration

1. Move current balls into `.tres` definitions.
2. Move current enemies into `.tres` definitions.
3. Build a reusable library of common ball effects and enemy actions.
4. Update spawn pools and encounter pools to use content resources.

### Phase 5: Map and progression

1. Add `MapState`.
2. Clean up encounter routing.
3. Route rewards and modifiers through `RunState`.

### Phase 6: Content scaling

1. Add more balls and enemies mostly through resources.
2. Only add a new script when introducing a genuinely new reusable mechanic.

---

## 12. Target Outcome

After this refactor:

### Adding a new ball should usually look like this

1. Create a new `ball_data` resource.
2. Attach a merge rule.
3. Attach one or more ball effects.
4. Add art and tuning values.
5. Register it in the spawn/reward pool.

### Adding a new enemy should usually look like this

1. Create a new `enemy_data` resource.
2. Attach one or more enemy actions.
3. Add stats, visuals, and rewards.
4. Register it in encounter content.

Only unusual mechanics should require one new reusable effect/action script.

That is the architecture target:

> **balls own their effects, enemies own their actions/effects, and content grows by adding resources instead of rewriting battle code.**
