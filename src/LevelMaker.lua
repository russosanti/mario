--[[
    CS50 2D
    Super Mario Bros. Remake

    -- LevelMaker Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

LevelMaker = Class({})

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
	local pillarNext = false -- to see if next column will have a tall pillar
	local tallPillarTop = 3 -- top height of a tall pillar

	-- insert blank tables into tiles for later access
	for x = 1, height do
		table.insert(tiles, {})
	end

	-- column by column generation instead of row; sometimes better for platformers
	for x = 1, width do
		local tileID = TILE_ID_EMPTY

		-- lay out the empty space
		for y = 1, 6 do
			table.insert(tiles[y], Tile(x, y, tileID, nil, tileset, topperset))
		end

		-- chance to just be emptiness except we need a ladder
		if not pillarNext and math.random(7) == 1 then
			for y = 7, height do
				table.insert(tiles[y], Tile(x, y, tileID, nil, tileset, topperset))
			end
		else
			tileID = TILE_ID_GROUND

			-- height at which we would spawn a potential jump block
			local blockHeight = 4

			for y = 7, height do
				table.insert(tiles[y], Tile(x, y, tileID, y == 7 and topper or nil, tileset, topperset))
			end

			if pillarNext then
				-- generate tall pillar
				for y = tallPillarTop, 6 do
					tiles[y][x] = Tile(x, y, tileID, y == tallPillarTop and topper or nil, tileset, topperset)
				end
				tiles[7][x].topper = nil
				pillarNext = false
			elseif x < width - 1 and math.random(20) == 1 then
				-- ladder on this collumn
				pillarNext = true
				table.insert(objects, GameObject {
					texture = "ladders",
					x = (x - 1) * TILE_SIZE,
					y = (tallPillarTop - 1) * TILE_SIZE,
					width = LADDER_WIDTH,
					height = (7 - tallPillarTop) * TILE_SIZE,
					collidable = false,
					solid = false,
					consumable = false,
                    onRender = function (self)
                        love.graphics.draw(gTextures['ladders'], gFrames['ladders'][1], self.x, self.y)
                        for cy = self.y + TILE_SIZE, self.y + self.height - TILE_SIZE, TILE_SIZE do
                            love.graphics.draw(gTextures['ladders'], gFrames['ladders'][2], self.x, cy)
                        end
                    end,
				})
			else
				-- chance to generate a pillar
				if math.random(8) == 1 then
					blockHeight = 2

					-- chance to generate bush on pillar
					if math.random(8) == 1 then
						table.insert(
							objects,
							GameObject({
								texture = "bushes",
								x = (x - 1) * TILE_SIZE,
								y = (4 - 1) * TILE_SIZE,
								width = 16,
								height = 16,

								-- select random frame from bush_ids whitelist, then random row for variance
								frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7,
								collidable = false,
							})
						)
					end

					-- pillar tiles
					tiles[5][x] = Tile(x, 5, tileID, topper, tileset, topperset)
					tiles[6][x] = Tile(x, 6, tileID, nil, tileset, topperset)
					tiles[7][x].topper = nil

				-- chance to generate bushes
				elseif math.random(8) == 1 then
					table.insert(
						objects,
						GameObject({
							texture = "bushes",
							x = (x - 1) * TILE_SIZE,
							y = (6 - 1) * TILE_SIZE,
							width = 16,
							height = 16,
							frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7,
							collidable = false,
						})
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
					table.insert(objects, LevelMaker.generateJumpBlock(objects, blockHeight, x, false, keyColor))
				end
			end
		end
	end

	local map = TileMap(width, height)
	map.tiles = tiles

	return GameLevel(entities, objects, map)
end

-- Generates a jump block which may contain a key or not
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
					LevelMaker.spawnBlockItem(objects, "locks", x, blockHeight, KEYS[keyColor], function(player, object)
						gSounds["key"]:play()
						player.hasKey = true
					end)
				elseif math.random(4) == 1 then -- chance to spawn gem, not guaranteed
					if math.random(3) == 1 then
						local frame = math.random(FIREBALLS_COUNT)
						LevelMaker.spawnBlockItem(objects, "fireballs", x, blockHeight, frame, function(player, object)
							gSounds["pickup"]:play()
							player:activatePowerup((frame - 1) % 4)
						end)
					else
						LevelMaker.spawnBlockItem(
							objects,
							"gems",
							x,
							blockHeight,
							math.random(#GEMS),
							function(player, object)
								gSounds["pickup"]:play()
								player.score = player.score + 100
							end
						)
					end
				end
				obj.hit = true
			end

			gSounds["empty-block"]:play()
		end,
	})
end

-- Generates the object to spawn on colission with block: key or gems
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
		onConsume = onConsume,
	})

	Timer.tween(0.1, {
		[item] = { y = (blockHeight - 2) * TILE_SIZE },
	})

	gSounds["powerup-reveal"]:play()
	table.insert(objects, item)
end

-- Generates Lock Block
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
				gSounds["unlock"]:play()
				LevelMaker.spawnGoalPost(player.level)
				return true
			end
			return false
		end,
	})
end

-- Finds a column at the end that has not a chasm. If it is a pillar it returns the row
local function groundRowAt(tileMap, col)
	for row = 1, tileMap.height do
		if tileMap.tiles[row][col]:collidable() then
			return row
		end
	end
	return nil
end

-- Finds row and column to place the flag
local function poleCoordinates(level)
	local col = level.tileMap.width - 1
	local groundRow = groundRowAt(level.tileMap, col)
	while not groundRow and col > 1 do
		col = col - 1
		groundRow = groundRowAt(level.tileMap, col)
	end
	groundRow = groundRow or 7

	return (col - 1) * TILE_SIZE, (groundRow - 1) * TILE_SIZE - FLAG_POLE_HEIGHT
end

-- Spawns Goal Post on the end of the level
function LevelMaker.spawnGoalPost(level)
	local poleX, poleY = poleCoordinates(level)
	local color = math.random(#FLAGS)

	-- insert pole
	local pole = GameObject({
		texture = "flags",
		frameGroup = "poles",
		frame = 1,
		x = poleX,
		y = poleY,
		width = FLAG_POLE_WIDTH,
		height = FLAG_POLE_HEIGHT,
		collidable = false,
		solid = false,
		consumable = false,
	})

	-- insert flag in pole
	local flag = GameObject({
		texture = "flags",
		frameGroup = "flags",
		frame = FLAGS[color].anim[1],
		x = poleX + FLAG_WIDTH / 2,
		y = poleY + 4, -- To put it under the end of the pole
		width = FLAG_WIDTH,
		height = FLAG_HEIGHT,
		collidable = false,
		solid = false,
		consumable = false,
		animation = Animation({ frames = FLAGS[color].anim, interval = 0.2 }),
	})

	table.insert(level.objects, pole)
	table.insert(level.objects, flag)

	level.goalPole = pole
	level.goalFlag = flag
	level.goalFlagCaptured = FLAGS[color].captured
end