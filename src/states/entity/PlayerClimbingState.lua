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

function PlayerClimbingState:update(dt)
    if love.keyboard.wasPressed('space') then
        self.player:changeState('jump')
        return
    end
    self.player.currentAnimation:update(dt)
end