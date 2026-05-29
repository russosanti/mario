--[[
    CS50 2D
    -- Super Mario Bros. Remake --

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

GameObject = Class{}

function GameObject:init(def)
    self.x = def.x
    self.y = def.y
    self.texture = def.texture
    self.width = def.width
    self.height = def.height
    self.frame = def.frame
    self.solid = def.solid
    self.collidable = def.collidable
    self.consumable = def.consumable
    self.onCollide = def.onCollide
    self.onConsume = def.onConsume
    self.hit = def.hit
    self.containsKey = def.containsKey
    self.unlockable = def.unlockable
    -- Render poles and flags
    self.frameGroup = def.frameGroup
    self.animation = def.animation
end

function GameObject:collides(target)
    return not (target.x > self.x + self.width or self.x > target.x + target.width or
            target.y > self.y + self.height or self.y > target.y + target.height)
end

function GameObject:update(dt)
    if self.animation then
        self.animation:update(dt)
        self.frame = self.animation:getCurrentFrame()
    end
end

-- Render function
function GameObject:render()
    local quads = self.frameGroup and gFrames[self.texture][self.frameGroup] or gFrames[self.texture]
    love.graphics.draw(gTextures[self.texture], quads[self.frame], self.x, self.y)
end