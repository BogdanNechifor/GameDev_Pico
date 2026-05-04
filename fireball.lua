--fireball
fireball = {}
fireball.__index = fireball

function fireball:new(pos, dir, speed, team, dmg, life)
    local f = setmetatable({}, self)

    f.pos = vec2:new(pos.x, pos.y)
    f.vel = vec2:new(dir.x, dir.y)
    f.vel:nrm()
    f.vel:mul(speed or 2)

    -- player/enemy
    f.team = team
    f.damage = dmg or 10

    f.radius = 3
    f.active = true

    -- animation
    f.anim_timer = 0
    f.anim_frame = 0

    -- lifetime (frames)
    f.life_timer = life or 120

    return f
end

function fireball:update()
    self.pos:add(self.vel)

    -- lifetime
    self.life_timer -= 1
    if self.life_timer <= 0 then
        self.active = false
    end

    -- flicker animation for enemies
    self.anim_timer += 1
    if self.anim_timer >= 4 then
        self.anim_timer = 0
        self.anim_frame = (self.anim_frame + 1) % 2
    end

    if self.team == "player" then
        -- check enemies
        for e in all(enemies) do
            local f_cp = { x = self.pos.x + 4, y = self.pos.y + 4 }
            local e_cp = { x = e.pos.x + e.off_x, y = e.pos.y + e.off_y }
            if check_overlap_circle(f_cp, e_cp, self.radius, e.radius) then
                e:take_damage(self.damage)
                self.active = false
                break
            end
        end
    else
        -- check player
        local f_cp = { x = self.pos.x + 4, y = self.pos.y + 4 }
        local p_cp = { x = p.pos.x + p.off_x, y = p.pos.y + p.off_y }
        if check_overlap_circle(f_cp, p_cp, self.radius, p.radius) then
            p:take_damage(self.damage) -- src is nil by default here, so no knockback
            self.active = false
        end
    end
end

function fireball:draw()
    if self.team == "player" then
        -- rotated sprite 2
        local a = atan2(self.vel.x, self.vel.y) - 0.25
        rspr(2, self.pos.x + 4, self.pos.y + 4, a)
    else
        -- animated sprites 3 and 4
        local s = 3 + self.anim_frame
        spr(s, flr(self.pos.x), flr(self.pos.y))
    end
end

function cast_fireball(pos, dir, speed, team, dmg, life)
    add(fireballs, fireball:new(pos, dir, speed, team, dmg, life))
end
