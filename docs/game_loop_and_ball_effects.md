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
