# Roguelike Architecture Refactor Plan (Current Implementation)

## 1. Purpose

This document now reflects the code that actually exists in the project today.

The previous version described an intended refactor target and referenced files that no longer exist, such as:

- `script/ball/behaviors/ball_behavior.gd`
- `script/ball/resolve/merge_resolver.gd`
- `script/ball/resolve/special_ball_resolver.gd`
- `script/session/game_manager.gd`
- `script/core/global.gd`
- battle logic embedded directly inside `scenes/main.tscn`

Those responsibilities have been replaced by the current `battle/`, `ball/`, `enemy/`, `player/`, and `run/` structure described below.

This is the architecture that should be treated as the source of truth.

## 2. Current Architecture Summary

The current project is organized around five runtime layers:

1. `RunState` stores cross-scene run data such as player HP and map progression.
2. `BattleController` orchestrates battle flow, but does not contain ball-specific or enemy-specific content logic.
3. `BattleRules` resolves merges, ball effects, and enemy actions through reusable contracts.
4. `BallData` and `EnemyData` resources own content configuration.
5. Scene-local UI scripts handle presentation, while gameplay state stays in battle/runtime objects.

This gives the project a simpler shape:

- static content lives in `.tres` resources
- runtime mutable battle data lives in `BattleState`
- orchestration lives in `BattleController`
- reusable gameplay behavior lives behind `MergeRule`, `BallEffect`, and `EnemyAction`
- cross-scene persistence is limited to `RunState`

## 3. Relevant Folder Structure

Godot `.uid` files are omitted here because they are metadata, not gameplay architecture.

```text
res://
  content/
    balls/
      attack_ball.tres
      duplicate_ball.tres
      heal_ball.tres
      multiply_ball.tres
    enemies/
      slime.tres

  scenes/
    damage_floater.tscn
    indicator_sprite.tscn
    main.tscn
    map.tscn
    map_tile.tscn

  script/
    ball/
      ball_data.gd
      game_ball.gd
      effects/
        duplicate_touching_effect.gd
        heal_touching_effect.gd
        multiply_touching_effect.gd
      merge_rules/
        level_merge_rule.gd
        no_merge_rule.gd

    battle/
      contracts/
        ball_effect.gd
        enemy_action.gd
        merge_rule.gd
      field/
        box.gd
      flow/
        context.gd
        controller.gd
        rules.gd
      state/
        ammo.gd
        state.gd
      ui/
        hud.gd

    enemy/
      enemy.gd
      enemy_data.gd
      actions/
        direct_attack_action.gd

    player/
      player.gd

    run/
      run_state.gd

    map/
      map_controller.gd
      map_generator.gd
      map_tile.gd

    ui/
      damage_floater.gd
      line_indicator.gd
      shoot_ammo_hud.gd
      timer_ring.gd
```

## 4. File Responsibilities

### 4.1 Content Resources

- `content/balls/attack_ball.tres`: default mergeable attack ball. It participates in level merges, appears often, and has no special effect.
- `content/balls/duplicate_ball.tres`: special utility ball that does not merge by level and duplicates nearby valid targets.
- `content/balls/heal_ball.tres`: special utility ball that consumes touching mergeable balls and heals the player. Its current `spawn_weight` is `0`, so it is defined content but not part of the random spawn pool.
- `content/balls/multiply_ball.tres`: special utility ball that doubles the level of touching mergeable balls.
- `content/enemies/slime.tres`: current enemy definition. It sets HP, damage, action list, and a wall-clock attack interval of `20.0` seconds.

### 4.2 Scenes

- `scenes/main.tscn`: battle scene. It composes the battlefield, template ball, target area, player, enemy, shared assets, and battle HUD.
- `scenes/map.tscn`: map scene. It hosts the map controller, camera, and simple map UI.
- `scenes/map_tile.tscn`: reusable scene for one map tile instance.
- `scenes/damage_floater.tscn`: reusable floating-number scene for combat text.
- `scenes/indicator_sprite.tscn`: reusable visual segment used by the aiming line.

### 4.3 Ball Scripts

- `script/ball/ball_data.gd`: ball definition resource. It owns spawn data, tags, visuals, level-based radius growth, merge rule, and ball effects.
- `script/ball/game_ball.gd`: runtime ball node. It handles ball setup state, aiming movement before drop, drop input, collision radius refresh, and drawing the ball label/color.
- `script/ball/merge_rules/level_merge_rule.gd`: merge rule for standard numbered balls. Two touching balls of the same level merge into one higher-level ball.
- `script/ball/merge_rules/no_merge_rule.gd`: merge rule for balls that should never participate in level merging.
- `script/ball/effects/duplicate_touching_effect.gd`: ball effect that duplicates nearby valid balls, consumes the source ball, and wakes the playfield.
- `script/ball/effects/heal_touching_effect.gd`: ball effect that consumes touching mergeable balls, converts their levels into healing, and heals the player.
- `script/ball/effects/multiply_touching_effect.gd`: ball effect that doubles the level of touching mergeable balls, then consumes the source ball.

### 4.4 Battle Scripts

- `script/battle/flow/controller.gd`: top-level battle orchestrator. It initializes the battle, runs the battle loop, handles shooting, routes damage/heal events, tracks battle end, and connects enemy action timing to rule resolution.
- `script/battle/field/box.gd`: playfield box service. It owns spawn-pool loading, random ball selection, template-ball duplication, active-ball queries, ball cleanup, and waking rigid bodies after board changes.
- `script/battle/state/state.gd`: mutable per-battle state. It tracks phase, resolution state, energy, current setup ball, and shoot ammo state.
- `script/battle/state/ammo.gd`: small runtime object that converts merge progress into bullets and consumes bullets on shot.
- `script/battle/flow/context.gd`: narrow API passed into merge rules, ball effects, and enemy actions. It exposes only the shared operations those systems need.
- `script/battle/flow/rules.gd`: battle rule coordinator. It resolves one merge step at a time, repeatedly applies ball effects until stable, and executes the next valid enemy action.
- `script/battle/ui/hud.gd`: battle HUD adapter. It syncs player HP, energy, shoot ammo, result text, and floating combat text without putting UI details in the controller.
- `script/battle/contracts/merge_rule.gd`: base resource contract for merge behavior.
- `script/battle/contracts/ball_effect.gd`: base resource contract for ball-triggered special effects.
- `script/battle/contracts/enemy_action.gd`: base resource contract for enemy actions.

### 4.5 Run State

- `script/run/run_state.gd`: autoload singleton for run-wide state. It persists player HP, map layout, and current map tile between scenes.

### 4.6 Enemy Scripts

- `script/enemy/enemy.gd`: runtime enemy node. It owns current HP, health-bar updates, hit flash, death handling, cooldown timer behavior, and cooldown-ring updates. It emits `action_requested` when its wall-clock timer reaches zero.
- `script/enemy/enemy_data.gd`: enemy definition resource. It owns enemy identifiers, stats, attack interval, and the action list.
- `script/enemy/actions/direct_attack_action.gd`: simplest enemy action. It damages the player directly through the battle context.

### 4.7 Player Scripts

- `script/player/player.gd`: lightweight player presentation node. It currently only handles the damage flash effect.

### 4.8 Map Scripts

- `script/map/map_controller.gd`: map scene orchestrator. It draws the persistent map layout, handles map navigation input, tracks the selected tile, and changes scenes when the player enters a tile.
- `script/map/map_generator.gd`: procedural map builder. It creates the dictionary layout stored in `RunState`.
- `script/map/map_tile.gd`: runtime visual script for one map tile. It chooses the tile icon based on tile type.

### 4.9 UI Scripts

- `script/ui/damage_floater.gd`: floating combat text animation script.
- `script/ui/line_indicator.gd`: aiming-line controller that follows the current setup ball.
- `script/ui/shoot_ammo_hud.gd`: shoot-ammo meter and bullet-pip presentation.
- `script/ui/timer_ring.gd`: circular cooldown display used by enemies to show remaining attack time.

## 5. Runtime Flow

### 5.1 Battle Startup

1. `scenes/main.tscn` instantiates the battle scene.
2. `BattleController` resets `BattleState`, builds `BattleBox`, connects to the enemy timer signal, syncs `BattleHud`, and spawns the current setup ball.
3. `BattleEnemy` resets its HP bar and starts its cooldown timer from `EnemyData.attack_interval`.

### 5.2 Ball Turn Flow

1. The current setup ball is a `GameBall`.
2. While the ball is in setup state, it follows the target horizontally.
3. On drop, `BattleController` switches the battle into resolution mode.
4. `BattleRules.step_merge()` resolves one merge at a time.
5. `BattleRules.resolve_ball_effects()` applies special ball effects until no further effect can trigger.
6. `BattleState.register_merge()` feeds `ShootAmmo`, which powers the shoot action.
7. After resolution settles, the controller restores play phase, updates energy and UI, and spawns the next setup ball.

### 5.3 Shooting

1. The player can shoot only if `ShootAmmo` has bullets.
2. `BattleController._shoot()` checks the target area for overlapping `GameBall` bodies.
3. Each hit ball deals damage to the enemy equal to its level, then gets consumed.
4. The shot also applies a knockback burst to nearby balls.

### 5.4 Enemy Actions

1. `BattleEnemy` owns a wall-clock cooldown timer.
2. When the timer expires, the enemy emits `action_requested`.
3. `BattleController` forwards that moment to `BattleRules.resolve_enemy_turn()`.
4. `BattleRules` picks the first valid `EnemyAction` from `EnemyData.actions`.
5. The action executes through `BattleContext`, which keeps the action decoupled from the controller internals.

### 5.5 Map Flow

1. `RunState` persists the generated map and current tile.
2. `MapController` draws tiles from `RunState.map_layout`.
3. Entering a non-shop tile changes back into `scenes/main.tscn`.

## 6. Why This Structure Is Cleaner

The current implementation is cleaner than the old version for three main reasons.

### 6.1 Content logic is resource-owned

Adding a new ball usually means:

- creating a new `BallData` resource
- choosing a `MergeRule`
- attaching one or more `BallEffect` resources

Adding a new enemy usually means:

- creating a new `EnemyData` resource
- assigning one or more `EnemyAction` resources

The battle controller does not need a content-specific `match` block for every ball or enemy type.

### 6.2 Orchestration is centralized, concrete behavior is not

`BattleController` decides:

- when setup begins
- when board resolution runs
- when a shot happens
- when the battle ends

But it does not decide:

- how two balls merge
- what a special ball effect does
- what a specific enemy action does

Those behaviors live behind contracts.

### 6.3 Presentation is split away from rule execution

UI responsibilities are no longer mixed into the controller:

- `BattleHud` owns battle HUD updates
- `DamageFloater` owns floater animation
- `ShootAmmoHUD` owns ammo meter visuals
- `TimerRing` owns cooldown-ring visuals

This keeps rule and state code smaller.

## 7. Current Extension Points

If the project grows, these are the intended extension points:

- new ball type: add a new `content/balls/*.tres`
- new merge behavior: add a new `MergeRule`
- new special ball behavior: add a new `BallEffect`
- new enemy type: add a new `content/enemies/*.tres`
- new enemy ability: add a new `EnemyAction`
- new map tile presentation: extend `map_tile.gd` and `map_generator.gd`

The key rule is still:

> Adding content should usually require new data or a new small behavior resource, not changes to the central battle loop.

## 8. Current Constraints and Future Candidates

The architecture is substantially cleaner now, but a few constraints still exist:

- `flow/controller.gd` still knows the scene structure of `main.tscn`. This is acceptable for now because it is the single battle composition root, but it is still scene-local coupling.
- `enemy/enemy.gd` still owns both enemy runtime state and some presentation details like HP bar updates. That is reasonable at current size, but it may split later if enemy presentation becomes more complex.
- `game_ball.gd` still mixes runtime control and drawing. That is also acceptable at current size because both responsibilities are tightly related to the same node.
- `map_controller.gd` currently changes directly to `main.tscn`. If the project adds multiple encounter scenes, a scene routing layer may become worthwhile.

These are future candidates for change, not current problems that block the project.

## 9. Working Rules For Future Refactors

When extending this project, keep these rules:

- prefer adding resources over branching in `BattleController`
- keep `BattleContext` narrow and explicit
- keep cross-scene mutable state inside `RunState`, not scattered globals
- keep UI updates in UI-facing scripts where possible
- split files only when a single file is clearly holding more than one reason to change
- avoid fallback-heavy code when the scene contract is fixed and local

This should preserve high cohesion, low coupling, and small meaningful files as the project grows.
