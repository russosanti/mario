--[[
    CS50 2D
    Super Mario Bros. Remake

    -- constants --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Some global constants for our application.
]]

-- size of our actual window
WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

-- size we're trying to emulate with push
VIRTUAL_WIDTH = 256
VIRTUAL_HEIGHT = 144

-- global standard tile size
TILE_SIZE = 16

-- width and height of screen in tiles
SCREEN_TILE_WIDTH = VIRTUAL_WIDTH / TILE_SIZE
SCREEN_TILE_HEIGHT = VIRTUAL_HEIGHT / TILE_SIZE

-- camera scrolling speed
CAMERA_SPEED = 100

-- speed of scrolling background
BACKGROUND_SCROLL_SPEED = 10

-- number of tiles in each tile set
TILE_SET_WIDTH = 5
TILE_SET_HEIGHT = 4

-- number of tile sets in sheet
TILE_SETS_WIDE = 6
TILE_SETS_TALL = 10

-- number of topper sets in sheet
TOPPER_SETS_WIDE = 6
TOPPER_SETS_TALL = 18

-- total number of topper and tile sets
TOPPER_SETS = TOPPER_SETS_WIDE * TOPPER_SETS_TALL
TILE_SETS = TILE_SETS_WIDE * TILE_SETS_TALL

-- player walking speed
PLAYER_WALK_SPEED = 60

-- player jumping velocity
PLAYER_JUMP_VELOCITY = -300

-- snail movement speed
SNAIL_MOVE_SPEED = 10

-- key and lock size
LOCK_SIZE = 16

-- powerup default duration in secs
POWERUP_DURATION = 10
FIREBALLS_COUNT = 16
-- seconds added depending on powerup size
POWERUP_SIZE_BONUS = { [0] = 0, [1] = 1, [2] = 2, [3] = 3 }

--
-- tile IDs
--
TILE_ID_EMPTY = 5
TILE_ID_GROUND = 3

-- table of tiles that should trigger a collision
COLLIDABLE_TILES = {
    TILE_ID_GROUND
}

-- Flags constants
FLAG_POLE_WIDTH = 16
FLAG_POLE_HEIGHT = 48
FLAG_POLE_COUNT = 6

FLAG_WIDTH = 16
FLAG_HEIGHT = 16


-- Ladder constants
LADDER_WIDTH = 16
LADDER_HEIGHT = 16
CLIMB_SPEED = 40
PLAYER_CLIMB_FRAMES = { 6, 7 }

--
-- game object IDs
--
BUSH_IDS = {
    1, 2, 5, 6, 7
}

COIN_IDS = {
    1, 2, 3
}

CRATES = {
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
}

GEMS = {
    1, 2, 3, 4, 5, 6, 7, 8
}

KEYS = {
    1, 2, 3, 4
}

LOCKS = {
    5, 6, 7, 8
}

-- Flags animation and captured id grouped by color
FLAGS = {
    { anim = { 1, 2 },  captured = 3  },
    { anim = { 4, 5 },  captured = 6  },
    { anim = { 7, 8 },  captured = 9  },
    { anim = { 10, 11 }, captured = 12 },
}

JUMP_BLOCKS = {}

for i = 1, 30 do
    table.insert(JUMP_BLOCKS, i)
end