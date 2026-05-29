--[[
    CS50 2D
    Super Mario Bros. Remake

    -- PlayState Class --
]]

PlayState = Class{__includes = BaseState}

function PlayState:init()
    self.camX = 0
    self.camY = 0
    self.background = math.random(3)
    self.backgroundX = 0

    self.victory = false

    self.gravityOn = true
    self.gravityAmount = 900
end

-- Sets score when next level generated from win
function PlayState:enter(params)
    params = params or {}
    self.levelWidth = params.width or 100

    self.level = LevelMaker.generate(self.levelWidth, 10)
    self.tileMap = self.level.tileMap

    self.player = Player({
        x = self:getPlayerSpawnX(), y = 0,
        width = 16, height = 20,
        texture = 'green-alien',
        stateMachine = StateMachine {
            ['idle'] = function() return PlayerIdleState(self.player) end,
            ['walking'] = function() return PlayerWalkingState(self.player) end,
            ['jump'] = function() return PlayerJumpState(self.player, self.gravityAmount) end,
            ['falling'] = function() return PlayerFallingState(self.player, self.gravityAmount) end
        },
        map = self.tileMap,
        level = self.level,
    })
    self.player.score = params.score or 0

    self:spawnEnemies()
    self.player:changeState('falling')
end

function PlayState:update(dt)
    Timer.update(dt)

    -- remove any nils from pickups, etc.
    self.level:clear()

    -- update player if not victory. Else freeze
    if not self.victory then
        self.player:update(dt)
    end
    -- update level
    self.level:update(dt)
    self:updateCamera()

    -- constrain player X no matter which state
    if self.player.x <= 0 then
        self.player.x = 0
    elseif self.player.x > TILE_SIZE * self.tileMap.width - self.player.width then
        self.player.x = TILE_SIZE * self.tileMap.width - self.player.width
    end

    -- if player reaches the goalPole
    if not self.victory and self.level.goalPole and self.level.goalPole:collides(self.player) then
        self:victoryLap()
    end
end

function PlayState:render()
    love.graphics.push()
    love.graphics.draw(gTextures['backgrounds'], gFrames['backgrounds'][self.background], math.floor(-self.backgroundX), 0)
    love.graphics.draw(gTextures['backgrounds'], gFrames['backgrounds'][self.background], math.floor(-self.backgroundX),
        gTextures['backgrounds']:getHeight() / 3 * 2, 0, 1, -1)
    love.graphics.draw(gTextures['backgrounds'], gFrames['backgrounds'][self.background], math.floor(-self.backgroundX + 256), 0)
    love.graphics.draw(gTextures['backgrounds'], gFrames['backgrounds'][self.background], math.floor(-self.backgroundX + 256),
        gTextures['backgrounds']:getHeight() / 3 * 2, 0, 1, -1)
    
    -- translate the entire view of the scene to emulate a camera
    love.graphics.translate(-math.floor(self.camX), -math.floor(self.camY))
    
    self.level:render()

    self.player:render()
    love.graphics.pop()
    
    -- render score
    love.graphics.setFont(gFonts['medium'])
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.print(tostring(self.player.score), 5, 5)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(tostring(self.player.score), 4, 4)
end

function PlayState:updateCamera()
    -- clamp movement of the camera's X between 0 and the map bounds - virtual width,
    -- setting it half the screen to the left of the player so they are in the center
    self.camX = math.max(0,
        math.min(TILE_SIZE * self.tileMap.width - VIRTUAL_WIDTH,
        self.player.x - (VIRTUAL_WIDTH / 2 - 8)))

    -- adjust background X to move a third the rate of the camera for parallax
    self.backgroundX = (self.camX / 3) % 256
end

--[[
    Adds a series of enemies to the level randomly.
]]
function PlayState:spawnEnemies()
    -- spawn snails in the level
    for x = 1, self.tileMap.width do

        -- flag for whether there's ground on this column of the level
        local groundFound = false

        for y = 1, self.tileMap.height do
            if not groundFound then
                if self.tileMap.tiles[y][x].id == TILE_ID_GROUND then
                    groundFound = true

                    -- random chance, 1 in 20
                    if math.random(20) == 1 then
                        
                        -- instantiate snail, declaring in advance so we can pass it into state machine
                        local snail
                        snail = Snail {
                            texture = 'creatures',
                            x = (x - 1) * TILE_SIZE,
                            y = (y - 2) * TILE_SIZE,
                            width = 16,
                            height = 16,
                            stateMachine = StateMachine {
                                ['idle'] = function() return SnailIdleState(self.tileMap, self.player, snail) end,
                                ['moving'] = function() return SnailMovingState(self.tileMap, self.player, snail) end,
                                ['chasing'] = function() return SnailChasingState(self.tileMap, self.player, snail) end
                            }
                        }
                        snail:changeState('idle', {
                            wait = math.random(5)
                        })

                        table.insert(self.level.entities, snail)
                    end
                end
            end
        end
    end
end

-- Function to get the X coordinate of the player spawn point to avoid chasms
function PlayState:getPlayerSpawnX()
    for x = 1, self.tileMap.width do
        for y = 1, self.tileMap.height do
            if self.tileMap.tiles[y][x].id == TILE_ID_GROUND then
                return (x - 1) * TILE_SIZE
            end
        end
    end
    -- fallback in case no ground is found (shouldn't happen)
    return 0
end

-- Vicory setting and animation tween
function PlayState:victoryLap()
    self.victory = true
    self.player:changeState('idle') -- freeze in idle pose

    -- Drop player to pole center
    Timer.tween(0.3, {
        [self.player] = {
            x = self.level.goalPole.x + (FLAG_POLE_WIDTH - self.player.width) / 2,
            y = self.level.goalPole.y + FLAG_POLE_HEIGHT - self.player.height,
        }
    })

    self.level.goalFlag.animation = nil
    self.level.goalFlag.frame = self.level.goalFlagCaptured

    Timer.tween(2, {
        [self.level.goalFlag] = { y = self.level.goalPole.y + FLAG_POLE_HEIGHT - 2 - FLAG_HEIGHT}
    }):finish(function()
        for k, object in pairs(self.level.objects) do
            if object == self.level.goalFlag then
                table.remove(self.level.objects, k)
                break
            end
        end

        Timer.after(0.5, function ()
            gStateMachine:change('play', {
                score = self.player.score,
                width = self.levelWidth * 1.2
            })
        end)
    end)
end