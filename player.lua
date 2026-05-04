--player
player = setmetatable({}, entity)
player.__index = player

function player:new()
    local p = entity.new(self, 0, 0, 2, 100, { 32, 33, 34 })
    p.firerate = 45
    p.fire_timer = 0
    p.fire_damage = 25
    return p
end

function player:update()
    -- shooting
    self.fire_timer -= 1
    if self.fire_timer <= 0 then
        self:fire()
        self.fire_timer = self.firerate
    end

    --movement
    local dxy = vec2:new()
    self.anim_paused = true

    if btn(0) then
        dxy.x = -1
        self.faces_right = false
    end
    if btn(1) then
        dxy.x = 1
        self.faces_right = true
    end
    if btn(2) then
        dxy.y = -1
    end
    if btn(3) then
        dxy.y = 1
    end

    self.anim_paused = dxy:mag() == 0

    dxy:nrm()
    dxy:mul(self.vel)
    self.pos:add(dxy)

    entity.update(self)
end

function player:take_damage(dmg, src)
    entity.take_damage(self, dmg)

    if self.visible == false then run() end

    if src == nil then return end

    local p_cx = self.pos.x + self.off_x
    local p_cy = self.pos.y + self.off_y
    local s_cx = src.pos.x + src.off_x
    local s_cy = src.pos.y + src.off_y

    local dxy = vec2:new(p_cx - s_cx, p_cy - s_cy)
    dxy:nrm()
    dxy:mul(5)

    self.pos:add(dxy)
end

function player:draw()
    entity.draw(self)
end

function player:fire()
    local closest_e = nil
    local min_dist = 32767

    local p_cx = self.pos.x + self.off_x
    local p_cy = self.pos.y + self.off_y

    for e in all(enemies) do
        local e_cx = e.pos.x + e.off_x
        local e_cy = e.pos.y + e.off_y

        local dist_vec = vec2:new(e_cx - p_cx, e_cy - p_cy)
        local d = dist_vec:mag()

        if d < min_dist then
            min_dist = d
            closest_e = e
        end
    end

    if closest_e then
        local e_cx = closest_e.pos.x + closest_e.off_x
        local e_cy = closest_e.pos.y + closest_e.off_y
        local dir = vec2:new(e_cx - p_cx, e_cy - p_cy)
        -- fire from player center (offset to center the 8x8 fireball sprite)
        cast_fireball(vec2:new(p_cx - 4, p_cy - 4), dir, 3, "player", self.fire_damage)
    end
end