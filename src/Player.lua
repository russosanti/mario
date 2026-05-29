--[[
    CS50 2D
    Super Mario Bros. Remake

    -- Player Class --
]]

Player = Class{__includes = Entity}

function Player:init(def)
    Entity.init(self, def)
    self.score = 0
    self.hasKey = false

    -- powerup
    self.powerup = false
    self.powerupTimer = 0
    self.baseTexture = def.texture or 'green-alien'
    self.flashTimer = 0

     -- particles effect for powerup
    self.psystem = love.graphics.newParticleSystem(gTextures['particle'], 200)
    self.psystem:setParticleLifetime(0.4, 1.0)
    self.psystem:setEmissionRate(0)
    self.psystem:setSizes(0.3, 0.1, 0.3)
    self.psystem:setSpeed(10, 40)
    self.psystem:setSpread(2 * math.pi)
    self.psystem:setLinearAcceleration(-10, -30, 10, -10)
    self.psystem:setColors(
        1, 1, 0.3, 1,      -- bright yellow
        1, 0.5, 0.0, 0.8,  -- orange
        1, 0.2, 0.0, 0.0   -- fade out
    )
    self.psystem:setEmissionArea('uniform', 5, 9)
end

function Player:update(dt)
    Entity.update(self, dt)

    -- particle system spawn
    self.psystem:setPosition(self.x + self.width / 2, self.y + self.height / 2)
    self.psystem:update(dt)

    -- powerup timers and effects
    if self.powerup then
        self.powerupTimer = self.powerupTimer - dt
        if self.powerupTimer <= 0 then
            self:deactivatePowerup()
        else
            -- flash player with pink and blue skins
            self.flashTimer = self.flashTimer + dt
            if self.flashTimer >= 0.1 then
                self.flashTimer = self.flashTimer - 0.1
                self.texture = self.texture == 'pink-alien' and 'blue-alien' or 'pink-alien'
            end
        end
    end
end

function Player:render()
    Entity.render(self)
    love.graphics.draw(self.psystem)
end

function Player:checkLeftCollisions(dt)
    -- check for left two tiles collision
    local tileTopLeft = self.map:pointToTile(self.x + 1, self.y + 1)
    local tileBottomLeft = self.map:pointToTile(self.x + 1, self.y + self.height - 1)

    -- place player outside the X bounds on one of the tiles to reset any overlap
    if (tileTopLeft and tileBottomLeft) and (tileTopLeft:collidable() or tileBottomLeft:collidable()) then
        self.x = (tileTopLeft.x - 1) * TILE_SIZE + tileTopLeft.width - 1
    else
        
        -- allow us to walk atop solid objects even if we collide with them
        self.y = self.y - 1
        local collidedObjects = self:checkObjectCollisions()
        self.y = self.y + 1

        -- reset X if new collided object (not walking atop)
        -- prevents clipping to top of blocks when jumping up into them
        if #collidedObjects > 0 then
            self.x = self.x + PLAYER_WALK_SPEED * dt
        end
    end
end

function Player:checkRightCollisions(dt)
    -- check for right two tiles collision
    local tileTopRight = self.map:pointToTile(self.x + self.width - 1, self.y + 1)
    local tileBottomRight = self.map:pointToTile(self.x + self.width - 1, self.y + self.height - 1)

    -- place player outside the X bounds on one of the tiles to reset any overlap
    if (tileTopRight and tileBottomRight) and (tileTopRight:collidable() or tileBottomRight:collidable()) then
        self.x = (tileTopRight.x - 1) * TILE_SIZE - self.width
    else
        
        -- allow us to walk atop solid objects even if we collide with them
        self.y = self.y - 1
        local collidedObjects = self:checkObjectCollisions()
        self.y = self.y + 1

        -- reset X if new collided object (not walking atop)
        -- prevents clipping to top of blocks when jumping up into them
        if #collidedObjects > 0 then
            self.x = self.x - PLAYER_WALK_SPEED * dt
        end
    end
end

function Player:checkObjectCollisions()
    local collidedObjects = {}

    for k, object in pairs(self.level.objects) do
        if object:collides(self) then
            if object.solid then
                table.insert(collidedObjects, object)
            elseif object.consumable then
                object.onConsume(self, object)
                table.remove(self.level.objects, k)
            end
        end
    end

    return collidedObjects
end

-- Activate powerup variables and skins
function Player:activatePowerup(size)
    size = size or 0
    self.powerup = true
    -- depending on the power up size we add an additional second
    self.powerupTimer = self.powerupTimer + POWERUP_DURATION + (POWERUP_SIZE_BONUS[size] or 0)
    self.flashTimer = 0
    self.texture = 'blue-alien'
    self.psystem:setEmissionRate(40)
end

-- deactivate powerup
function Player:deactivatePowerup()
    self.powerup = false
    self.texture = self.baseTexture
    self.psystem:setEmissionRate(0)
end

-- Check colission with other entities based on power up logic
function Player:checkEntityCollisions()
    -- check if we've collided with any entities and die or kill
    for k = #self.level.entities, 1, -1 do
        local entity = self.level.entities[k]
        if entity:collides(self) then
            if self.powerup then
                gSounds['kill']:play()
                gSounds['kill2']:play()
                self.score = self.score + 100
                table.remove(self.level.entities, k)
            else
                gSounds['death']:play()
                gStateMachine:change('start')
                return
            end
        end
    end
end

-- Check if we are on top of a ladder
function Player:overlappingLadder()
    for k, object in pairs(self.level.objects) do
        if object.texture == 'ladders' and object:collides(self) then
            return object
        end
    end
    return nil
end

-- starts to climb
function Player:tryClimb()
    if love.keyboard.isDown('up') then
        local ladder = self:overlappingLadder()
        if ladder then
            self:changeState('climbing', {ladder = ladder})
            return true
        end
    end
    return false
end