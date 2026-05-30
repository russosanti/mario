# Mario - CS50 Game Development

A side-scrolling platformer inspired by Super Mario Bros., developed in Lua using LÖVE2D.

## Features

### Improved Chasm Detection

Fixed an issue where the player could sometimes walk over gaps without falling.

The falling-state detection was expanded by checking a few pixels beyond the player's left and right edges, preventing false ground collisions when walking across chasms.

This creates more reliable platforming behavior.

## Safe Player Spawn

Implemented a safe spawn system to ensure the player never starts inside a chasm.

When a level is generated:

- The game searches for the first valid ground column
- The player is spawned above that location

A helper function was added to `PlayState` to determine a valid spawn position.

## Key and Lock System

Added progression-based collectibles to each level.

### Key Spawn

- A random key is generated somewhere in the level
- The key acts as a collectible object
- The player stores the key after collecting it

### Locked Block

- A locked block is generated later in the level
- The key always appears before the lock block
- Once the player has the key, the block can be broken from below

When the locked block is hit:

- The block disappears
- The level exit becomes available

Additional logic was implemented in `LevelMaker` and `Player` to support the key state and object generation.

## Goal Pole and Flag

Breaking the locked block spawns the level goal.

### Goal Generation

- A pole and flag are spawned near the end of the level
- The spawn point is placed one tile before the end
- If that location contains a chasm, the game searches for the nearest valid ground tile

### Level Completion

When the player touches the pole:

- A victory sequence begins
- The player automatically walks toward the flag
- The flag is lowered
- The score is preserved
- A new, longer level is generated

A dedicated victory animation sequence was implemented in `PlayState`.

## Ladders and Tall Pillars

Added vertical traversal elements to generated levels.

### Ladder Generation

- Tall pillars can now appear in the level
- When appropriate, ladders are automatically generated alongside those pillars
- Ladder pieces are built using chunk generation

This creates more varied platform layouts and traversal challenges.

## Climbing System

Implemented a dedicated climbing state and animations.

### Ladder Interaction

When standing on the ground:

- Pressing Up while near a ladder enters the climbing state

When airborne:

- If the player is falling
- And is not colliding with nearby terrain
- The ladder is automatically grabbed mid-air

Custom climb animations were added for smooth transitions between movement states.

## Fireball Power-Up System

Added a rare special power-up that can appear instead of a regular gem.

### Power-Up Effects

When collected:

- The player becomes temporarily immune to enemy damage
- Touching a snail instantly defeats it

### Duration Variants

The power-up can grant:

- 10 seconds
- 12 seconds
- 14 seconds
- 16 seconds

Larger power-ups provide longer durations.

### Stackable Buffs

Power-up durations are cumulative.

Collecting additional power-ups extends the remaining immunity timer.

## Power-Up Visual Effects

Added visual feedback while the immunity power-up is active.

### Effects

- Alternate pink and blue player skins
- Particle effects surrounding the player
- Animated transitions while immunity is active

These effects provide clear feedback about the player's powered-up state.

## Technologies

- Lua
- LÖVE2D

## Future Improvements

- User can't fall between blocks. Same issue as fixed above