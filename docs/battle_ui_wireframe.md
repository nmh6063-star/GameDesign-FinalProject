# Battle UI Wireframe Spec

## 1. Purpose

This document describes the user-provided battle wireframe in implementation terms so it can be translated into Godot scene nodes and scripts without re-interpreting the image every time.

Use this as the layout source of truth for the next battle UI pass.

The wireframe is not a generic HUD. It is a fixed composition with:

- a large center-left play box
- a left-side ball information card
- a top-right enemy information card
- a right-side HP/ammo cluster
- two circular action badges under the player and enemy
- a large gun/hand foreground element on the bottom-right

## 2. Reference Frame

All measurements below use an approximate reference canvas of `1920 x 1380`.

Use percentages first when coding. The pixel values are for composition guidance, not strict hardcoded layout.

## 3. Visual Direction

### 3.1 Overall Look

- Pixel-art battle scene
- Deep purple dominant palette
- Flat white cards over a dark world background
- Medieval / gothic / blackletter-like text
- High contrast silhouette shapes
- Minimal ornamentation, strong blocking

### 3.2 Color Intent

- Background base: dark purple, around `#4B215F`
- Background detail: dusty lavender, around `#877097`
- Info cards: soft white, around `#EDEDED`
- Text: near-black, around `#111111`
- Box frame: muted lavender-gray, around `#8B72A0`
- Box interior: darker purple than background, around `#3D0F50`
- HP fill: strong red, around `#D60B00`
- HP empty: black
- Inactive pips: dark gray
- Active pips: off-white
- Action badge ring: saturated red
- Sword icon: silver blade, gold guard

### 3.3 Font Intent

- Headings: decorative gothic / blackletter-like font
- Body text: same family or a compatible stylized serif/pixel font
- Avoid modern rounded UI typography

## 4. Layout Zones

### 4.1 Background Zone

- Full canvas background image
- Fills the entire viewport
- Contains abstract pixel-art scenery in light lavender shapes over dark purple
- Should sit behind every other element

### 4.2 Character Zone

- Upper-middle band of the screen
- Player on the left side of the central lane
- Enemy on the right side of the central lane
- Both characters sit visually above the box and below the top edge

### 4.3 Box Zone

- Large play box in the lower center-left
- Dominant object in the lower half of the scene
- Open at the top
- Balls collect at the bottom

### 4.4 Right HUD Zone

- Enemy info card at the top-right
- HP bar directly beneath it
- Circular pip row beneath the HP bar
- Gun foreground overlaps the lower-right corner below this cluster

### 4.5 Left HUD Zone

- Ball info card aligned to left edge, slightly above the box midpoint
- Small selected-ball preview tile below it near the bottom-left

## 5. Component Spec

## 5.1 Background

- Id: `BattleBackground`
- Suggested node type: `Sprite2D` or full-screen `TextureRect`
- Layer: far background
- Bounds: `x=0 y=0 w=1920 h=1380`
- Notes:
  - Must cover the whole frame
  - Should not be blurred or glossy
  - Preserve coarse pixel texture

## 5.2 Player Sprite

- Id: `PlayerSprite`
- Suggested node type: `Node2D` + `Sprite2D`
- Layer: world
- Approx bounds: `x=690 y=245 w=180 h=260`
- Approx center: `x=780 y=375`
- Notes:
  - Position is slightly left of screen center
  - The player silhouette is smaller than the box but clearly readable
  - Leave negative space between player and left info card

## 5.3 Enemy Sprite

- Id: `EnemySprite`
- Suggested node type: `Node2D` + `AnimatedSprite2D`
- Layer: world
- Approx bounds: `x=1125 y=280 w=170 h=210`
- Approx center: `x=1210 y=385`
- Notes:
  - Sits to the right of the player with comfortable separation
  - Must leave room above-right for the enemy attack card

## 5.4 Player Action Badge

- Id: `PlayerActionBadge`
- Suggested node type: `Node2D`
- Suggested children:
  - outer red ring
  - white inner disc
  - sword icon sprite or custom draw
- Layer: world-follow or overlay-follow
- Approx bounds: `x=885 y=440 w=110 h=110`
- Approx center: `x=940 y=495`
- Notes:
  - Positioned below the player, not touching the sprite
  - Reads like a circular status token or action marker
  - Red ring is thick and clearly visible

## 5.5 Enemy Action Badge

- Id: `EnemyActionBadge`
- Suggested node type: `Node2D`
- Same construction as `PlayerActionBadge`
- Approx bounds: `x=1325 y=440 w=110 h=110`
- Approx center: `x=1380 y=495`
- Notes:
  - Positioned below the enemy
  - Matches the player badge in size and visual language

## 5.6 Enemy Attack Info Card

- Id: `EnemyInfoCard`
- Suggested node type: `PanelContainer` or rounded `Panel`
- Layer: screen-space HUD
- Approx bounds: `x=1390 y=95 w=485 h=325`
- Anchor intent: top-right cluster with fixed inset
- Corner radius: large, around `32-40px`
- Fill: soft white
- Text color: black
- Internal padding: around `28-36px`
- Children:
  - `Label` or `RichTextLabel` title: `enemy attack info`
  - `Label` line: `next attack in: 15 sec`
  - `Label` line: `damage: 100`
- Text alignment:
  - title centered
  - body left-aligned
- Notes:
  - This card is descriptive, not decorative
  - Leave generous vertical spacing between lines

## 5.7 Enemy HP Bar

- Id: `EnemyHealthBar`
- Suggested node type: `Control`
- Suggested children:
  - black background bar
  - red fill bar
- Layer: screen-space HUD
- Approx bounds: `x=1285 y=640 w=620 h=66`
- Shape:
  - long horizontal pill/rounded rectangle
  - black full width
  - red fill starts at left and covers about `70%`
- Notes:
  - No text is shown inside the wireframe bar
  - It sits below the attack card and above the pip row

## 5.8 Ammo / Charge Pip Row

- Id: `AmmoPips`
- Suggested node type: `HBoxContainer` or manual row of circles
- Layer: screen-space HUD
- Approx row bounds: `x=1285 y=735 w=610 h=60`
- Count: `8` circular pips
- Approx pip diameter: `38-42px`
- Gap: `28-34px`
- Visible sample state:
  - first 5 pips are dark gray
  - last 3 pips are off-white
- Notes:
  - The row is centered under the HP bar
  - If semantics are still undecided, preserve the visual layout first and bind game meaning later

## 5.9 Ball Info Card

- Id: `BallInfoCard`
- Suggested node type: `PanelContainer` or rounded `Panel`
- Layer: screen-space HUD
- Approx bounds: `x=40 y=705 w=250 h=395`
- Corner radius: large, around `28-36px`
- Fill: soft white
- Text color: black
- Internal padding: around `20-28px`
- Children:
  - heading label: `ball info`
  - body label with wrapped text
- Sample body text from wireframe:
  - `this ball duplicates`
  - `all the ball it comes`
  - `in contact with`
- Notes:
  - Title is top-centered
  - Body is left-aligned
  - This is a descriptive side card for the currently selected or current ball

## 5.10 Selected Ball Preview Tile

- Id: `BallPreviewTile`
- Suggested node type: `Panel`, rounded `ColorRect`, or `TextureRect`
- Layer: screen-space HUD
- Approx bounds: `x=84 y=1178 w=110 h=130`
- Fill: soft white
- Corner radius: large
- Notes:
  - This is visually detached from the info card
  - Keep it simple: blank card, icon, or selected-ball miniature
  - It sits near the lower-left corner

## 5.11 Play Box

- Id: `BattleBox`
- Suggested node type: `StaticBody2D` + visible frame nodes
- Layer: world
- Outer bounds: `x=330 y=615 w=625 h=690`
- Inner cavity bounds: `x=360 y=648 w=565 h=610`
- Construction:
  - left wall
  - right wall
  - bottom lip
  - open top
  - dark interior fill
- Style:
  - thick muted-lavender frame
  - flat dark-purple interior
- Notes:
  - This is the visual and mechanical center of the battle scene
  - It must occupy the lower middle-left, not dead center
  - The gun requires clear space to the right of the box

## 5.12 Balls In Box

- Id: `BallCluster`
- Suggested node type: existing runtime balls
- Layer: world, inside the box
- Approx occupied area: bottom `25-30%` of the box
- Visible state in wireframe:
  - multiple off-white circular balls
  - mixed sizes
  - one tiny marked ball near the middle
  - largest ball near the right side of the cluster
- Notes:
  - Balls should rest against the bottom
  - Their fill should remain simple and bright to contrast against the box interior

## 5.13 Foreground Gun / Hand

- Id: `ForegroundGun`
- Suggested node type: `Sprite2D`
- Layer: foreground world art, above background and box, below HUD cards
- Approx bounds: `x=1180 y=905 w=510 h=475`
- Anchor intent: bottom-right
- Notes:
  - This should feel like a first-person weapon silhouette entering from the bottom-right
  - It overlaps empty space rather than sitting on top of the box
  - Keep it large and heavy; it is part of the composition, not a small prop

## 6. Suggested Godot Mapping

Use this as a practical scene mapping, not a mandatory exact tree.

```text
Main
  Assets
    BattleBackground: Sprite2D
    Box: StaticBody2D
    ForegroundGun: Sprite2D

  PlayerHolder
    Player
      Sprite2D
      ActionBadge: Node2D

  EnemyHolder
    Enemy
      AnimatedSprite2D
      ActionBadge: Node2D

  UI: CanvasLayer
    BallInfoCard: PanelContainer
      Title: Label
      Body: RichTextLabel
    BallPreviewTile: Panel
    EnemyInfoCard: PanelContainer
      Title: Label
      NextAttack: Label
      Damage: Label
    EnemyHealthBar: Control
      Background: ColorRect
      Fill: ColorRect
    AmmoPips: HBoxContainer
      Pip0..Pip7: Panel
```

## 7. Alignment Rules

- Keep the box as the main lower-half anchor.
- Keep the player and enemy above the box opening, not centered vertically.
- Keep left and right HUD elements near the edges so the middle stays readable.
- Keep all white cards as fixed blocks, not auto-flow panels.
- Keep the gun strictly in the bottom-right corner.
- Do not collapse this into a standard top-bar HUD.

## 8. Scaling Rules

- Preserve the relative composition on wide desktop screens first.
- If adapted to smaller resolutions, scale by region:
  - cards shrink slightly
  - box remains dominant
  - gun can crop more aggressively
- Keep the left info card and right enemy card visible without overlapping the box.

## 9. Implementation Notes

- Treat the wireframe as a fixed-screen composition, not a responsive web-style layout.
- Prefer absolute/anchored placement for the first implementation pass.
- Use the existing battle scene as the world root, then replace the current HUD arrangement with this composition.
- If an exact measurement is unclear from the image, match the proportions before matching text size.
- Preserve the strong silhouette and empty space. The composition depends on it.

## 10. Priority Order For Coding

1. Background, box, player, enemy, and gun placement
2. Left info card and right enemy card
3. HP bar and pip row
4. Action badges under player and enemy
5. Final text sizing, spacing, and corner-radius tuning
