--enemies

--pitic
dwarf = setmetatable({}, entity)
dwarf.__index = dwarf

function dwarf:new(x, y)
    local time_ratio = mid(0, (survival_timer or 0) / 18000, 1)
    local base_hp = flr(40 + time_ratio * 260)

    local d = entity.new(self, x, y, 0.8, base_hp, { 41, 42, 43, 42 }, 4, 1, 2)
    d.anim_paused = false
    d.off_y = 11
    d.idle_frame = 2
    d.xp_value = 15
    d.is_predictive = rnd(1) < 0.5
    d.damage = 10
    return d
end

function dwarf:update(idx)
    if (idx + survival_timer) % 2 != 0 then
        entity.update(self) -- maintain animation frame updates
        return
    end

    local hist = p.history[1]
    local p_cx = hist.x + p.off_x
    local p_cy = hist.y + p.off_y
    local e_cx = self.pos.x + self.off_x
    local e_cy = self.pos.y + self.off_y

    local real_dx = p_cx - e_cx
    local real_dy = p_cy - e_cy
    local real_man_dist = abs(real_dx) + abs(real_dy)

    if self.is_predictive and real_man_dist > 50 then
        p_cx += (hist.vx or 0) * 30
        p_cy += (hist.vy or 0) * 30
    end

    local dx = p_cx - e_cx
    local dy = p_cy - e_cy
    local man_dist = abs(dx) + abs(dy)

    -- Teleport if too far away (despawn & respawn optimization)
    -- Manhattan dist 200 roughly equals Euclidean 165
    if real_man_dist > 200 then
        local ang = rnd(1)
        local spawn_dist = 110 + rnd(30)
        self.pos.x = p.pos.x + cos(ang) * spawn_dist
        self.pos.y = p.pos.y + sin(ang) * spawn_dist
        return
    end

    if man_dist > 0 then
        local ux = dx / man_dist
        local uy = dy / man_dist
        local speed = self.vel * 2 -- Double speed because it runs half as often
        self.pos.x += ux * speed
        self.pos.y += uy * speed
        if ux > 0 then
            self.faces_right = true
        elseif ux < 0 then
            self.faces_right = false
        end
    end

    entity.update(self)
end

--shaman
shaman = setmetatable({}, entity)
shaman.__index = shaman

function shaman:new(x, y)
    local time_ratio = mid(0, (survival_timer or 0) / 18000, 1)
    local base_hp = flr(40 + time_ratio * 260)

    local s = entity.new(self, x, y, 1.2, base_hp, { 9, 10, 11, 10 }, 4, 1, 2)
    s.anim_paused = false
    s.off_y = 11
    s.chase_range = 60 * (0.7 + rnd(0.4))
    s.idle_frame = 2
    s.firerate = 90
    s.fire_timer = rnd(s.firerate)
    s.xp_value = 35
    s.is_predictive = false
    return s
end

function shaman:update(idx)
    if (idx + survival_timer) % 2 != 0 then
        entity.update(self) -- maintain animation frame updates
        return
    end

    local hist = p.history[1]
    local p_cx = hist.x + p.off_x
    local p_cy = hist.y + p.off_y
    if self.is_predictive then
        p_cx += (hist.vx or 0) * 30
        p_cy += (hist.vy or 0) * 30
    end
    local e_cx = self.pos.x + self.off_x
    local e_cy = self.pos.y + self.off_y

    local dx = p_cx - e_cx
    local dy = p_cy - e_cy
    local man_dist = abs(dx) + abs(dy)

    -- Teleport if too far away (despawn & respawn optimization)
    if man_dist > 200 then
        local ang = rnd(1)
        local spawn_dist = 110 + rnd(30)
        self.pos.x = p.pos.x + cos(ang) * spawn_dist
        self.pos.y = p.pos.y + sin(ang) * spawn_dist
        return
    end

    -- chase while distance is greater than range
    -- multiply chase_range by 1.2 to account for manhattan inflation
    if man_dist > self.chase_range * 1.2 then
        self.anim_paused = false
        if man_dist > 0 then
            local ux = dx / man_dist
            local uy = dy / man_dist
            local speed = self.vel * 2 -- Double speed for half-rate update
            self.pos.x += ux * speed
            self.pos.y += uy * speed
            if ux > 0 then
                self.faces_right = true
            elseif ux < 0 then
                self.faces_right = false
            end
        end
    else
        self.anim_paused = true
    end

    -- shooting
    self.fire_timer -= 2 -- Subtract 2 because this only runs every other frame
    if self.fire_timer <= 0 then
        if man_dist <= self.chase_range * 1.2 then
            if #fireballs < 80 then
                local dir = { x = p_cx - e_cx, y = p_cy - e_cy }
                cast_fireball({ x = e_cx - 4, y = e_cy - 4 }, dir, 1.5, "enemy", 5, 120)
                self.fire_timer = self.firerate
            else
                -- Fireball cap reached, wait a fraction of a second before retrying
                self.fire_timer = 10
            end
        else
            -- retry soon if player was out of range
            self.fire_timer = 10
        end
    end

    entity.update(self)
end