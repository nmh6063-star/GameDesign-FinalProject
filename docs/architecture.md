# Roguelike Architecture

## Purpose

This document reflects the current runtime structure after the battle refactor.

The battle code is now grouped by responsibility inside `script/battle/`:

- `core/` for battle flow, state, and rule resolution
- `controllers/` for battle-specific scene coordination
- `ui/` for battle-only HUD glue

Generic reusable widgets still live in `script/ui/`, and content definitions still live under `script/entities/` plus `data/`.

## Before / After

### Before

- battle-specific logic was split inconsistently between `script/battle/`, top-level scene helper scripts, and generic UI folders
- `battle_loop.gd` temporarily absorbed helper logic that really belonged to separate battle-only controllers
- reward selection and HUD coordination were harder to locate because they were mixed into the loop

### After

- `script/battle/core/` contains only the battle runtime foundation
- `script/battle/controllers/` contains the battle-only scene helpers
- `script/battle/ui/` contains the battle-only HUD adapter
- `script/ui/` is back to generic widgets only

## Folder Structure

```text
res://
  script/
	battle/
	  core/
		battle_context.gd
		battle_loop.gd
		battle_resolver.gd

	  controllers/
		battle_ball_manager.gd
		enemy_slot_controller.gd
		reward_selection_controller.gd

	  ui/
		battle_hud_adapter.gd

	entities/
	  balls/
		ball_base.gd
		ball_catalog.gd
		ball_data.gd
		elemental_balls/
		  elemental_ball_base.gd
		  elemental_ball_scene.tscn
		  level_merge_rule.gd
		  merge_rule_base.gd
		modifier_balls/
		  modifier_ball_base.gd
		  modifier_ball_scene.tscn
		effects/
		  ball_effect_base.gd
		  duplicate_effect.gd
		  explode_effect.gd
		  heal_touch_effect.gd
		  magnet_effect.gd
		  multiply_effect.gd
		  shot_amplifier_effect.gd

	  enemies/
		enemy_base.gd
		enemy_catalog.gd
		enemy_data.gd
		enemy_scene.tscn
		actions/
		  bomb_drop_action.gd
		  direct_attack_action.gd
		  enemy_action_base.gd
		effects/
		  enemy_effect_base.gd

	map/
	  map_controller.gd
	  map_generator.gd
	  map_tile.gd

	player/
	  player.gd

	state/
	  battle_loadout.gd
	  map_state.gd
	  player_state.gd

	ui/
	  damage_floater.gd
	  line_indicator.gd
	  shoot_ammo_hud.gd
	  timer_ring.gd

  data/
	balls/
	  amplifier_ball.tres
	  bomb_ball.tres
	  duplication_ball.tres
	  heal_ball.tres
	  magnet_ball.tres
	  multiplication_ball.tres
	  normal_ball.tres
	enemies/
	  enemy1.tres
	  enemy2.tres

  scenes/
	main.tscn
	map.tscn
	map_tile.tscn
	reward_selection.tscn
```

## Main Responsibilities

### Battle Core

- `script/battle/core/battle_loop.gd`
  The scene-facing orchestrator. It decides when things happen and in what order: reward entry, stage startup, per-frame stepping, shooting, drop-to-resolve flow, enemy turns, and battle-end checks.

- `script/battle/core/battle_context.gd`
  The shared battle state bag. It stores phase, current setup ball, player energy, merge progress, bullet stock, battle result state, and the narrow helper API used by balls and enemies.

- `script/battle/core/battle_resolver.gd`
  The rule executor. It resolves merges, triggered ball behaviors, and board behavior ticks by talking to `BallBase` through shared interfaces.

### Battle Controllers

- `script/battle/controllers/battle_ball_manager.gd`
  Handles battle-scene ball queue generation, setup-ball spawning, board spawns, duplication spawns, and ball cleanup.

- `script/battle/controllers/enemy_slot_controller.gd`
  Handles one enemy slot in the battle scene: scene spawning, HP/cooldown UI sync, selection highlight, and enemy damage floaters.

- `script/battle/controllers/reward_selection_controller.gd`
  Owns the reward overlay scene. It renders reward options, hover descriptions, selection state, and emits the chosen ball ids back to the loop.

### Battle UI

- `script/battle/ui/battle_hud_adapter.gd`
  Coordinates battle-only HUD state: queue previews, shoot ammo meter sync, result banners, and player-side damage/heal floaters.

### Entity Layer

- `script/entities/balls/ball_base.gd`
  Shared ball runtime object for rendering, physics, shots, and board-effect hooks. Merge behavior no longer lives here.

- `script/entities/balls/elemental_balls/elemental_ball_base.gd`
  Merge-capable ball runtime. Only elemental balls use this path, so modifier balls cannot be level-merged by accident.

- `script/entities/balls/modifier_balls/modifier_ball_base.gd`
  Modifier-ball runtime. It keeps the shared ball behavior but has no merge implementation.

- `script/entities/balls/ball_data.gd`
  Ball definition resource. It stores display data, spawn data, merge rule, and composed ball effects.

- `script/entities/balls/ball_catalog.gd`
  Registry from ball id to `BallData` plus the correct elemental or modifier shared scene.

- `script/entities/balls/elemental_balls/merge_rule_base.gd`
  Shared merge-rule contract.

- `script/entities/balls/effects/ball_effect_base.gd`
  Shared ball-effect hook contract.

- `script/entities/enemies/enemy_base.gd`
  Shared enemy runtime object and loop-facing enemy interface. Enemy turns are driven by each enemy's real-time cooldown timer.

- `script/entities/enemies/enemy_data.gd`
  Enemy definition resource. It stores stats, real-time attack timing, actions, and effects.

- `script/entities/enemies/enemy_catalog.gd`
  Registry from enemy id to shared scene plus `EnemyData`.

- `script/entities/enemies/actions/enemy_action_base.gd`
  Shared enemy-action contract.

- `script/entities/enemies/effects/enemy_effect_base.gd`
  Shared enemy-effect hook contract.

### Cross-Scene State

- `script/state/player_state.gd`
  Persistent player HP.

- `script/state/battle_loadout.gd`
  Persistent unlocked ball pool.

- `script/state/map_state.gd`
  Persistent map layout and current tile.

### Generic UI Widgets

- `script/ui/line_indicator.gd`
  Small aiming widget reused by the battle scene.

- `script/ui/shoot_ammo_hud.gd`
  Small shoot-meter widget.

- `script/ui/timer_ring.gd`
  Small cooldown-ring widget.

These stay outside `script/battle/` because they are reusable widgets, not battle-specific orchestration.

## Loop / Object Boundary

The battle core talks to entities through shared interfaces:

- `ball.check_merge(ctx, other)`
- `ball.merge_with(ctx, other)`
- `ball.try_apply_board_behavior(ctx)`
- `ball.tick_board_behavior(ctx)`
- `ball.on_shot(ctx)`
- `enemy.on_turn(ctx)`
- `enemy.take_damage_with_context(amount, ctx)`

That keeps the loop focused on flow, while content is mostly added through:

1. `BallData` or `EnemyData`
2. composed effect/action resources
3. only a new subclass when the default base-object flow is not enough
