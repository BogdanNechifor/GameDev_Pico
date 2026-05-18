--fireball
fireball = {}
fireball.__index = fireball

function fireball:new(pos, dir, speed, team, dmg, life)
    local f = setmetatable({}, self)

    f.pos = { x = pos.x, y = pos.y }
    
    local d_mag = sqrt(dir.x * dir.x + dir.y * dir.y)
    if d_mag > 0 then
        f.vel = { x = (dir.x / d_mag) * (speed or 2), y = (dir.y / d_mag) * (speed or 2) }
    else
        f.vel = { x = 0, y = 0 }
    end

    f.team = team
    f.damage = dmg or 10

    f.radius = 3
    f.active = true

    f.anim_timer = 0
    f.anim_frame = 0

    f.life_timer = life or 120

    if team == "player" then
        f.crit_chance = p.crit_chance or 0.01
        f.splash_ratio = p.splash_ratio or 0.2
        f.splash_radius = p.splash_radius or 16
    end

    return f
end

function fireball:update()
    self.pos.x += self.vel.x
    self.pos.y += self.vel.y

    self.life_timer -= 1
    if self.life_timer <= 0 then
        self.active = false
    end

    self.anim_timer += 1
    if self.anim_timer >= 4 then
        self.anim_timer = 0
        self.anim_frame = (self.anim_frame + 1) % 2
    end

    if self.team == "player" then
        local fx = self.pos.x + 4
        local fy = self.pos.y + 4
        for e in all(enemies) do
            local ex = e.pos.x + e.off_x
            local ey = e.pos.y + e.off_y
            if check_overlap_circle(fx, fy, ex, ey, self.radius, e.radius) then
                -- Roll for critical strike
                local is_crit = rnd(1) < (self.crit_chance or 0.01)
                
                if is_crit then
                    local crit_dmg = flr(self.damage * 1.5)
                    e:take_damage(crit_dmg, true)
                    
                    -- Splash 150% damage to other nearby enemies
                    for other_e in all(enemies) do
                        if other_e != e then
                            local ox = other_e.pos.x + other_e.off_x
                            local oy = other_e.pos.y + other_e.off_y
                            if check_overlap_circle(fx, fy, ox, oy, self.splash_radius or 16, other_e.radius) then
                                other_e:take_damage(crit_dmg, true)
                            end
                        end
                    end
                    
                    -- Spawn colorful visual explosion ring (only on crit!)
                    trigger_explosion_effect(fx, fy, self.splash_radius or 16)
                else
                    -- Standard single-target hit
                    e:take_damage(self.damage, false)
                    
                    -- Splash damage to other nearby enemies (no visual explosion ring!)
                    local splash_dmg = flr(self.damage * (self.splash_ratio or 0.2))
                    if splash_dmg > 0 then
                        for other_e in all(enemies) do
                            if other_e != e then
                                local ox = other_e.pos.x + other_e.off_x
                                local oy = other_e.pos.y + other_e.off_y
                                if check_overlap_circle(fx, fy, ox, oy, self.splash_radius or 16, other_e.radius) then
                                    other_e:take_damage(splash_dmg, false)
                                end
                            end
                        end
                    end
                end

                self.active = false
                break
            end
        end
    else
        local fx = self.pos.x + 4
        local fy = self.pos.y + 4
        local px = p.pos.x + p.off_x
        local py = p.pos.y + p.off_y
        if check_overlap_circle(fx, fy, px, py, self.radius, p.radius) then
            p:take_damage(self.damage) -- src is nil by default here, so no knockback
            self.active = false
        end
    end
end

function fireball:draw()
    if self.team == "player" then
        local a = atan2(self.vel.x, self.vel.y) - 0.25
        rspr(2, self.pos.x + 4, self.pos.y + 4, a)
    else
        local s = 3 + self.anim_frame
        spr(s, flr(self.pos.x), flr(self.pos.y))
    end
end

function cast_fireball(pos, dir, speed, team, dmg, life)
    add(fireballs, fireball:new(pos, dir, speed, team, dmg, life))
end
