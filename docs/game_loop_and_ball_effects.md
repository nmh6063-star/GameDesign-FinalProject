# Battle Flow And Object Responsibilities

This document describes the current battle runtime.

## Structure

The battle runtime is split into three layers inside `script/battle/`:

- `core/`
  `battle_loop.gd`, `battle_context.gd`, `battle_resolver.gd`
- `controllers/`
  `battle_ball_manager.gd`, `enemy_slot_controller.gd`, `reward_selection_controller.gd`
- `ui/`
  `battle_hud_adapter.gd`

The split is intentional:

- `battle_loop.gd` decides when things happen
- `battle_context.gd` stores shared state
- `battle_resolver.gd` decides what happens when board rules resolve
- controllers coordinate battle-scene pieces
- the HUD adapter keeps battle-only UI sync out of the loop

## Main Files

- `script/battle/core/battle_loop.gd`
  Owns battle startup, reward entry, player input, target visuals, turn orchestration, enemy selection, and battle-end handling.

- `script/battle/core/battle_context.gd`
  Owns shared mutable battle state and the helper API passed into merge rules, ball effects, and enemy actions/effects.

- `script/battle/core/battle_resolver.gd`
  Owns merge and board-behavior resolution.

- `script/battle/controllers/battle_ball_manager.gd`
  Owns queue generation and ball spawning/cleanup.

- `script/battle/controllers/enemy_slot_controller.gd`
  Owns one enemy slot's scene object, selection state, and slot-local UI sync.

- `script/battle/controllers/reward_selection_controller.gd`
  Owns the reward overlay scene and emits selected rewards back to the loop.

- `script/battle/ui/battle_hud_adapter.gd`
  Owns battle HUD sync for queue previews, ammo meter, result banners, and player-side damage/heal floaters.

## Core Loop

### 1. Battle startup

`BattleLoop._initialize()` forwards into `BattleLoop._begin_battle()`, which resets `BattleContext` and opens `reward_selection.tscn`.

`RewardSelectionController` now owns reward rendering and selection behavior. When the player confirms:

- the chosen ball ids are added to `BattleLoadout`
- `BattleLoop._begin_stage()` creates `BattleBallManager`
- enemy slots are bound through `EnemySlotController`
- `BattleLoop._begin_turn()` syncs the HUD and spawns the current setup ball

### 2. Setup ball spawning

`BattleBallManager` pulls queue entries from `BallCatalog`.

Each queue entry contains:

- ball id
- shared ball scene
- `BallData`
- rolled spawn level

The catalog chooses between:

- `script/entities/balls/elemental_balls/elemental_ball_scene.tscn`
- `script/entities/balls/modifier_balls/modifier_ball_scene.tscn`

Elemental balls use `ElementalBallBase`, which owns merge behavior. Modifier balls use `ModifierBallBase`, so they cannot be consumed by elemental level-merges.

### 3. Per-frame runtime

`BattleLoop._physics_process()` stays split by concern:

1. `_step_battle_resolution()`
2. `_handle_selection_input()`
3. `_update_enemy_realtime_views()`
4. `_update_target_visual()`
5. `_handle_shoot_input()`

### 4. Board resolution

When `BattleContext.resolving_board` is true, `BattleLoop._step_battle_resolution()` calls:

- `BattleResolver.resolve_frame(ctx)`

The resolver then runs:

1. `_resolve_one_merge(ctx)`
2. `_resolve_triggered_ball_behaviors(ctx)`
3. `_tick_ball_behaviors(ctx)`

It talks to balls only through `BallBase` methods such as:

- `ball.check_merge(ctx, other)`
- `ball.merge_with(ctx, other)`
- `ball.try_apply_board_behavior(ctx)`
- `ball.tick_board_behavior(ctx)`

### 5. Drop -> resolve -> next turn

When the setup ball is dropped:

- `BattleLoop._on_ball_dropped()` forwards to `_complete_turn_after_drop()`
- `BattleContext.current_ball` is cleared
- the battle enters `RESOLVE`
- the flow waits for settle time
- `BattleLoop._end_turn()` finishes resolution
- if the battle is still active, `BattleLoop._begin_turn()` starts the next turn

### 6. Shooting

`BattleLoop.try_shoot()` computes shot results through `BallBase`.

For each hit ball it asks:

- `ball.shot_base_damage()`
- `ball.shot_damage_multiplier()`

After damage is applied, it calls:

- `ball.on_shot(ctx)`

### 7. Enemy turns

Enemies emit `action_requested`.

`BattleLoop` forwards that into:

- `resolve_enemy_turn(enemy)`

The loop then asks the enemy directly:

- `enemy.on_turn(ctx)`

The default `EnemyBase` flow:

- runs `EnemyEffectBase.on_turn_start()`
- picks the first usable `EnemyActionBase`
- runs `on_before_act()`
- executes the action
- runs `on_after_act()`

Enemy turns are driven only by each enemy's real-time attack cooldown timer.

## Recent API Additions (May 6, 2026)

### Element-aware ball drops

`BattleBallManager.drop_element_ball_at_x(rank, x)` — like `drop_ball_at_x` but
mirrors the full `element_list` / `type` setup from `spawn_setup_ball` before
`configure()` is called. Use this when spawning balls that should display the
player's current rank-class texture (e.g. the Shower ability).

Exposed up the chain via:
- `BattleLoop.drop_element_ball_in_box(rank, x)` → `_box.drop_element_ball_at_x`
- `BattleContext.drop_element_ball_in_box(rank, x)` → `controller.drop_element_ball_in_box`

### New enemy status keys (BattleContext.enemy_statuses)

| Key | Type | Set by | Effect |
|-----|------|--------|--------|
| `time_stop_until_ms` | int (epoch ms) | Time Stop ability | Blocks attack timer; target takes ×1.5 direct damage |
| (existing) `freeze_until_ms` | int | Freeze/Ice abilities | Blocks attack timer only |

### New battle_flags keys (BattleContext.battle_flags)

| Key | Type | Set by | Effect |
|-----|------|--------|--------|
| `poison_rain_shoots` | int (0–5) | Poison Rain | While active, each board merge adds +3 poison to all enemies |
| `corrupt_field_active` | bool | Corrupt Field | Poisoned enemies deal −20% damage for 1 shoot |
| `bomb_orb_ticks` | int | Bomb Orb | Bomb countdown displayed on enemies; 0 = inactive |

Both `poison_rain_shoots` and `corrupt_field_active` are decremented/cleared in
`BattleLoop._on_ball_dropped()` so duration is measured in ball drops (shoots).

## Recent API Additions (May 10, 2026)

### New enemy status keys (BattleContext.enemy_statuses)

| Key | Type | Set by | Effect |
|-----|------|--------|--------|
| `thunder_stack` | int | Thunder Fang, Storm Surge | Chain damage propagation (see Thunder Debuff); displayed as ⚡ Thdr N |
| `weakness_brand_shoots` | int (shoots) | Weakness Brand | Target takes +30% direct damage; counts down per shoot |

### New player_statuses keys (BattleContext.player_statuses)

| Key | Type | Set by | Effect |
|-----|------|--------|--------|
| `direct_damage_heal_ratio` | float | Lifesteal Field | Heal (ratio × damage) after every direct hit |
| `second_wind_ready` | bool | Second Wind | Enables low-HP trigger |
| `second_wind_main_used` | bool | Second Wind | Tracks first-use vs. repeat-use healing |
| `second_wind_cooldown` | bool | Second Wind | Prevents re-trigger until HP recovers above 30% |

### New battle_flags keys (BattleContext.battle_flags)

| Key | Type | Set by | Effect |
|-----|------|--------|--------|
| `shoot_ball_count` | int | `try_shoot` | Number of balls in current shot; read by Tide Turner |
| `shoot_damage_acc` | int | `damage_enemy` | Total direct damage dealt this shot; read by Tide Turner |
| `tide_turner_pending` | bool | Tide Turner | Resolved after all `on_shot` calls in `try_shoot` |
| `fragile_stacks` | int | Chaos Slash | Player takes +20% per stack; cleared in `_on_ball_dropped` |
| `gatekeeper_charges` | int | Gatekeeper | Converts 50% of each incoming hit to Shield |
| `overkill_active` | bool | Overkill | Kill overflow in `damage_enemy` (battle_loop) |
| `elbaphs_power_start_ms` | int | Elbaph's Power | Start timestamp; drives progressive size/damage ramp |

### New enemy_base.gd field

`_battle_hp_reduction: int` — cumulative max-HP reduction applied during a battle by Decay.
Reset to 0 in `EnemyBase.reset()`. `max_health()` subtracts this from `data.max_health` (floored at 1).

### New BattleContext methods

`_damage_player_hp_only(amount)` — reduces player HP directly, bypassing shield, Gatekeeper, and Fragile. HP is floored at 1. Used by Fortress.

`_propagate_thunder(damage, source_enemy)` — called after every direct and DoT damage event to chain thunder stacks across all living enemies. Guarded by `_thunder_propagating` flag to prevent recursion.

### New BattleLoop methods

`_sync_player_bar_public()` — public wrapper so `BattleContext._damage_player_hp_only` can trigger a bar refresh.

`_update_elbaphs_power(delta)` — throttled (every 0.1 s) updater that linearly ramps `size_mult` (1.0→2.0) and `attack_mult` (0.5→1.5) on all Elbaph-tagged balls over 15 seconds.

## Composition Model

### Balls

The normal way to add a ball is:

1. add or update a `data/balls/*.tres`
2. for elemental balls, choose a `MergeRuleBase` from `script/entities/balls/elemental_balls/`
3. attach one or more `BallEffectBase` resources

### Enemies

The normal way to add an enemy is:

1. add or update a `data/enemies/*.tres`
2. register it in `EnemyCatalog`
3. attach `EnemyActionBase` resources and optional `EnemyEffectBase` resources
4. use an `EnemySpawn_<enemy_id>` marker name in `main.tscn` where that enemy should appear

## Practical Result

The battle runtime now splits cleanly by responsibility:

- `BattleLoop` decides when things happen
- `BattleContext` stores shared battle state
- battle result state also lives in `BattleContext`, while the HUD only renders it
- `BattleResolver` executes board rules
- battle controllers coordinate scene-specific pieces
- `BattleHudAdapter` keeps battle-only HUD sync out of the loop
- `BallBase` and `EnemyBase` define what objects do
