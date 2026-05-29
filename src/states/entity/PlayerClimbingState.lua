--[[
    Player state for climbing the ladders
]]

PlayerClimbingState = Class{__includes = BaseState}

function PlayerClimbingState:init(player)
    self.player = player
    self.animation = Animation {
    frames = PLAYER_CLIMB_FRAMES,
        interval = 0.2
    }
    self.player.currentAnimation = self.animation
end

function PlayerClimbingState:enter(params)
    self.ladder = params.ladder
    self.player.x = self.ladder.x
    self.player.dx = 0
    self.player.dy = 0
end
function PlayerClimbingState:update(dt)
    if love.keyboard.wasPressed('space') then
        self.player:changeState('jump')
        return
    end

    -- ladder + player height as limit
    local climbingTop = self.ladder.y - self.player.height
    -- bottom ground as limit
    local ladderBottom = self.ladder.y + self.ladder.height - self.player.height

    if love.keyboard.isDown('up') then
        self.player.currentAnimation:update(dt)
        self.player.y = math.max(self.player.y - CLIMB_SPEED * dt, climbingTop)
        if self.player.y == climbingTop then
            self.player:changeState('idle')
            return
        end
    elseif love.keyboard.isDown('down') then
        self.player.currentAnimation:update(dt)
        self.player.y = math.min(self.player.y + CLIMB_SPEED * dt, ladderBottom)
        if self.player.y == ladderBottom then
            self.player:changeState('idle')
            return
        end
    elseif love.keyboard.isDown('left') then
        self.player.direction = 'left'
        self.player:changeState('walking')
        return
    elseif love.keyboard.isDown('right') then
        self.player.direction = 'right'
        self.player:changeState('walking')
        return
    end

    if not self.player:overlappingLadder() then
        self.player:changeState('falling')
    end
end