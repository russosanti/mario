--[[
    CS50 2D
    Super Mario Bros. Remake

    -- LevelMaker Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

LevelMaker = Class{}

function LevelMaker.generate(width, height)
    local tiles = {}
    local entities = {}
    local objects = {}

    local tileID = TILE_ID_GROUND
    
    -- whether we should draw our tiles with toppers
    local topper = true
    local tileset = math.random(20)
    local topperset = math.random(20)

    -- Key and lock gen variables
    -- Key target is guaranteed to spawn at least 1 lock space away from the right edge
    local keyTargetX = math.random(10, width - LOCK_SIZE * 2)
    local lockTargetX = math.random(keyTargetX + LOCK_SIZE, width - LOCK_SIZE)
    local keySpawned = false
    local lockSpawned = false
    local keyColor = math.random(#KEYS)

    -- insert blank tables into tiles for later access
    for x = 1, height do
        table.insert(tiles, {})
    end

    -- column by column generation instead of row; sometimes better for platformers
    for x = 1, width do
        local tileID = TILE_ID_EMPTY
        
        -- lay out the empty space
        for y = 1, 6 do
            table.insert(tiles[y],
                Tile(x, y, tileID, nil, tileset, topperset))
        end

        -- chance to just be emptiness
        if math.random(7) == 1 then
            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, nil, tileset, topperset))
            end
        else
            tileID = TILE_ID_GROUND

            -- height at which we would spawn a potential jump block
            local blockHeight = 4

            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, y == 7 and topper or nil, tileset, topperset))
            end

            -- chance to generate a pillar
            if math.random(8) == 1 then
                blockHeight = 2
                
                -- chance to generate bush on pillar
                if math.random(8) == 1 then
                    table.insert(objects,
                        GameObject {
                            texture = 'bushes',
                            x = (x - 1) * TILE_SIZE,
                            y = (4 - 1) * TILE_SIZE,
                            width = 16,
                            height = 16,
                            
                            -- select random frame from bush_ids whitelist, then random row for variance
                            frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7,
                            collidable = false
                        }
                    )
                end
                
                -- pillar tiles
                tiles[5][x] = Tile(x, 5, tileID, topper, tileset, topperset)
                tiles[6][x] = Tile(x, 6, tileID, nil, tileset, topperset)
                tiles[7][x].topper = nil
            
            -- chance to generate bushes
            elseif math.random(8) == 1 then
                table.insert(objects,
                    GameObject {
                        texture = 'bushes',
                        x = (x - 1) * TILE_SIZE,
                        y = (6 - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,
                        frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7,
                        collidable = false
                    }
                )
            end

            -- chance to spawn a block or place the block with key
            if not keySpawned and x >= keyTargetX then
                table.insert(objects, LevelMaker.generateJumpBlock(objects, blockHeight, x, true, keyColor))
                keySpawned = true
            elseif not lockSpawned and x >= lockTargetX then
                table.insert(objects, LevelMaker.generateLockBlock(blockHeight, x, keyColor))
                lockSpawned = true
            elseif math.random(10) == 1 then
                table.insert(objects, LevelMaker.generateJumpBlock(objects, blockHeight, x, false, keyColor)
                )
            end
        end
    end

    local map = TileMap(width, height)
    map.tiles = tiles
    
    return GameLevel(entities, objects, map)
end

function LevelMaker.generateJumpBlock(objects, blockHeight, x, containsKey, keyColor)
	-- jump block
	return GameObject({
		texture = "jump-blocks",
		x = (x - 1) * TILE_SIZE,
		y = (blockHeight - 1) * TILE_SIZE,
		width = 16,
		height = 16,

		-- make it a random variant
		frame = math.random(#JUMP_BLOCKS),
		collidable = true,
		hit = false,
		solid = true,
        containsKey = containsKey or false,

		-- collision function takes itself
		onCollide = function(obj)
			-- spawn a gem if we haven't already hit the block
			if not obj.hit then
                if obj.containsKey then
                    LevelMaker.spawnBlockItem(objects, 'locks', x, blockHeight, KEYS[keyColor],
                        function(player, object)
                            gSounds["pickup"]:play()
                            player.hasKey = true
                        end
                )

                elseif math.random(5) == 1 then -- chance to spawn gem, not guaranteed
					LevelMaker.spawnBlockItem(objects, 'gems', x, blockHeight, math.random(#GEMS),
                        function(player, object)
                            gSounds["pickup"]:play()
                            player.score = player.score + 100
                        end
                    )
                end
				obj.hit = true
			end

			gSounds["empty-block"]:play()
		end,
	})
end

function LevelMaker.spawnBlockItem(objects, texture, x, blockHeight, frame, onConsume)
    local item = GameObject({
        texture = texture,
        x = (x - 1) * TILE_SIZE,
        y = (blockHeight - 1) * TILE_SIZE - 4,
        width = 16,
        height = 16,
        frame = frame,
        collidable = true,
        consumable = true,
        solid = false,
        onConsume = onConsume
    })

    Timer.tween(0.1, {
        [item] = { y = (blockHeight - 2) * TILE_SIZE }
    })

    gSounds["powerup-reveal"]:play()
    table.insert(objects, item)
end

function LevelMaker.generateLockBlock(blockHeight, x, keyColor)
    -- lock block
    return GameObject({
        texture = "locks",
        x = (x - 1) * TILE_SIZE,
        y = (blockHeight - 1) * TILE_SIZE,
        width = 16,
        height = 16,

        -- make it a random variant
        frame = LOCKS[keyColor],
        collidable = true,
        solid = true,
        consumable = false,
        unlockable = true,

        onCollide = function(obj, player)
            if player.hasKey then
                player.hasKey = false
                gSounds["empty-block"]:play()
                return true
            end
            return false
        end,
    })
end