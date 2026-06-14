--player
player = setmetatable({}, entity)
player.__index = player

function player:new()
    local p = entity.new(self, 0, 0, 1.0, 100, { 32, 33, 34 })
    p.firerate = 45
    p.fire_timer = 0
    p.fire_damage = 25
    p.level = 1
    p.xp = 0
    p.max_xp = 80
    p.level_cap = 30
    p.fireballs_count = 1
    p.crit_chance = 0.01
    p.splash_ratio = 0.2
    p.splash_radius = 16
    p.upgrades = { speed = 0, haste = 0, multishot = 0, crit = 0, splash = 0, damage = 0, vitality = 0 }
    p.iframe_timer = 0
    p.iframe_duration = 10

    p.history = {}
    for i=1, 6 do add(p.history, {x=p.pos.x, y=p.pos.y, vx=0, vy=0}) end

    if debug_stress then
        p.firerate = 15
        p.fireballs_count = 3
        p.fire_damage = 45
        p.crit_chance = 0.25
        p.splash_ratio = 0.7
        p.splash_radius = 16
        p.vel = 1.9
        p.max_hp = 300
        p.hp = 300
        p.damage_upgrades = 10
        p.level = 30
    end

    return p
end

function player:gain_xp(amount, spawn_pos)
    if debug_stress then return end
    if self.level >= self.level_cap then return end

    self.xp += amount
    if spawn_pos then
        add_floating_text("+"..amount.." xp", spawn_pos.x, spawn_pos.y, 11)
    end

    if self.xp >= self.max_xp then
        self:level_up()
    end
end

function player:level_up()
    self.level += 1
    self.xp -= self.max_xp
    self.max_xp = flr(80 * (1.15 ^ (self.level - 1)))
    if self.level >= self.level_cap then
        self.xp = 0
    end

    add_floating_text("level up!", self.pos.x, self.pos.y - 8, 10)
    trigger_level_up_effect(self.pos)
    sfx(0)

    level_up_choices = get_level_up_options()
    selected_choice = 1
    game_state = "level_up"
end

function player:update()
    self.fire_timer -= 1
    if self.fire_timer <= 0 then
        self:fire()
        self.fire_timer = self.firerate
    end

    --movement
    local dx, dy = 0, 0
    self.anim_paused = true

    if btn(0) or btn(0, 1) then
        dx = -1
        self.faces_right = false
    end
    if btn(1) or btn(1, 1) then
        dx = 1
        self.faces_right = true
    end
    if btn(2) or btn(2, 1) then
        dy = -1
    end
    if btn(3) or btn(3, 1) then
        dy = 1
    end

    local mag = sqrt(dx * dx + dy * dy)
    self.anim_paused = mag == 0

    if mag > 0 then
        self.vx = (dx / mag) * self.vel
        self.vy = (dy / mag) * self.vel
        self.pos.x += self.vx
        self.pos.y += self.vy
    else
        self.vx = 0
        self.vy = 0
    end

    self.iframe_timer = max(0, self.iframe_timer - 1)
    
    deli(self.history, 1)
    add(self.history, {x=self.pos.x, y=self.pos.y, vx=self.vx, vy=self.vy})

    if self.regen_cooldown and self.regen_cooldown > 0 then
        self.regen_cooldown -= 1
        self.regen_timer = 0
    else
        -- 2% missing hp regen per second
        self.regen_timer = (self.regen_timer or 0) + 1
        if self.regen_timer >= 30 then
            self.regen_timer = 0
            if self.hp < self.max_hp then
                local missing = self.max_hp - self.hp
                self.hp = min(self.max_hp, self.hp + missing * 0.02)
            end
        end
    end

    entity.update(self)
end

function player:take_damage(dmg, src)
    if self.iframe_timer > 0 then return end
    
    entity.take_damage(self, dmg)
    self.iframe_timer = self.iframe_duration
    self.regen_cooldown = 150

    if src == nil then return end

    local p_cx = self.pos.x + self.off_x
    local p_cy = self.pos.y + self.off_y
    local s_cx = src.pos.x + src.off_x
    local s_cy = src.pos.y + src.off_y

    local dx = p_cx - s_cx
    local dy = p_cy - s_cy
    local mag = sqrt(dx * dx + dy * dy)
    if mag > 0 then
        self.pos.x += (dx / mag) * 5
        self.pos.y += (dy / mag) * 5
    end
end

function player:draw()
    if self.iframe_timer > 0 and self.iframe_timer % 4 < 2 then
        return
    end
    entity.draw(self)
end

function player:fire()
    local p_cx = self.pos.x + self.off_x
    local p_cy = self.pos.y + self.off_y

    -- translate mouse screen coordinates to world coordinates
    local cam_x = flr(self.pos.x - 60)
    local cam_y = flr(self.pos.y - 60)
    local mouse_x = stat(32) + cam_x
    local mouse_y = stat(33) + cam_y

    local dir_x = mouse_x - p_cx
    local dir_y = mouse_y - p_cy

    -- if mouse is exactly on player, default to aiming right
    if dir_x == 0 and dir_y == 0 then
        dir_x = 1
    end

        local base_ang = atan2(dir_x, dir_y)
        local spread = 0.05
        local start_ang = base_ang - (self.fireballs_count - 1) * spread / 2

        sfx(2)

        for i = 0, self.fireballs_count - 1 do
            local ang = start_ang + i * spread
            local f_dir = { x = cos(ang), y = sin(ang) }
            cast_fireball({ x = p_cx - 4, y = p_cy - 4 }, f_dir, 3, "player", self.fire_damage)
        end
end