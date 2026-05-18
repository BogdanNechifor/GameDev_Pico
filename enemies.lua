--enemies

--pitic
dwarf = setmetatable({}, entity)
dwarf.__index = dwarf

function dwarf:new(x, y)
    local time_ratio = mid(0, (survival_timer or 0) / 18000, 1)
    local hp_multiplier = 1 + 0.5 * time_ratio
    local base_hp = flr(100 * hp_multiplier)

    local d = entity.new(self, x, y, 0.8, base_hp, { 41, 42, 43, 42 }, 4, 1, 2)
    d.anim_paused = false
    d.off_y = 11
    d.idle_frame = 2
    d.xp_value = 15
    return d
end

function dwarf:update()
    local p_cx = p.pos.x + p.off_x
    local p_cy = p.pos.y + p.off_y
    local e_cx = self.pos.x + self.off_x
    local e_cy = self.pos.y + self.off_y

    local dxy = vec2:new(p_cx - e_cx, p_cy - e_cy)
    local dist = dxy:mag()

    -- Teleport if too far away (despawn & respawn optimization)
    if dist > 165 then
        local ang = rnd(1)
        local spawn_dist = 90 + rnd(40)
        self.pos.x = p.pos.x + cos(ang) * spawn_dist
        self.pos.y = p.pos.y + sin(ang) * spawn_dist
        return
    end

    dxy:nrm()
    dxy:mul(self.vel)
    self.pos:add(dxy)
    if dxy.x > 0 then
        self.faces_right = true
    elseif dxy.x < 0 then
        self.faces_right = false
    end

    entity.update(self)
end

--shaman
shaman = setmetatable({}, entity)
shaman.__index = shaman

function shaman:new(x, y)
    local time_ratio = mid(0, (survival_timer or 0) / 18000, 1)
    local hp_multiplier = 1 + 0.5 * time_ratio
    local base_hp = flr(100 * hp_multiplier)

    local s = entity.new(self, x, y, 1.2, base_hp, { 9, 10, 11, 10 }, 4, 1, 2)
    s.anim_paused = false
    s.off_y = 11
    s.chase_range = 60 * (0.7 + rnd(0.4))
    s.idle_frame = 2
    s.firerate = 90
    s.fire_timer = rnd(s.firerate)
    s.xp_value = 35
    return s
end

function shaman:update()
    local p_cx = p.pos.x + p.off_x
    local p_cy = p.pos.y + p.off_y
    local e_cx = self.pos.x + self.off_x
    local e_cy = self.pos.y + self.off_y

    local dxy = vec2:new(p_cx - e_cx, p_cy - e_cy)
    local dist = dxy:mag()

    -- Teleport if too far away (despawn & respawn optimization)
    if dist > 165 then
        local ang = rnd(1)
        local spawn_dist = 90 + rnd(40)
        self.pos.x = p.pos.x + cos(ang) * spawn_dist
        self.pos.y = p.pos.y + sin(ang) * spawn_dist
        return
    end

    -- chase while distance is greater than range
    if dist > self.chase_range then
        self.anim_paused = false
        dxy:nrm()
        dxy:mul(self.vel)
        self.pos:add(dxy)
        if dxy.x > 0 then
            self.faces_right = true
        elseif dxy.x < 0 then
            self.faces_right = false
        end
    else
        self.anim_paused = true
    end

    -- shooting
    self.fire_timer -= 1
    if self.fire_timer <= 0 then
        if dist <= self.chase_range then
            local dir = vec2:new(p_cx - e_cx, p_cy - e_cy)
            cast_fireball(vec2:new(e_cx - 4, e_cy - 4), dir, 1.5, "enemy", 5, 120)
            self.fire_timer = self.firerate
        else
            -- retry soon if player was out of range
            self.fire_timer = 10
        end
    end

    entity.update(self)
end