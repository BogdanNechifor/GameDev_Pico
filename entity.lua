--entities
entity = {}
entity.__index = entity

function entity:new(x, y, vel, hp, spr, radius, w, h)
    local e = setmetatable({}, self)

    e.visible = true

    e.pos = vec2:new(x, y)
    e.x = x or 0
    e.y = y or 0
    e.vel = vel or 2

    e.hp = hp or 100
    e.max_hp = hp or 100

    e.faces_right = false
    e.spr = spr

    e.anim_paused = true
    e.anim_timer = 0
    e.anim_frame = 1
    e.anim_speed = 5

    e.radius = radius or 2
    e.w = w or 1
    e.h = h or 1
    e.off_x = 4
    e.off_y = 4

    e.invincibility_timer = 0

    return e
end

function entity:take_damage(dmg)
    if self.invincibility_timer > 0 then return end

    self.hp -= dmg
    self.visible = self.hp > 0
    self.invincibility_timer = 3
end

function entity:update()
    -- invincibility
    if self.invincibility_timer > 0 then
        self.invincibility_timer -= 1
    end

    --progress animation
    if self.anim_paused then
        self.anim_frame = self.idle_frame or 1
    else
        self.anim_timer += 1
        if self.anim_timer >= self.anim_speed then
            self.anim_timer = 0
            self.anim_frame %= #self.spr
            self.anim_frame += 1
        end
    end
end

function entity:draw()
    if self.visible then
        -- red flash for 2 frames
        if self.invincibility_timer > 1 then
            for i = 1, 15 do pal(i, 8) end
        end

        spr(self.spr[self.anim_frame], flr(self.pos.x), flr(self.pos.y), self.w, self.h, self.faces_right)

        -- reset palette
        pal()

        -- hp bar above sprite (only when damaged)
        if self.hp < self.max_hp and self != p then
            local bx = flr(self.pos.x)
            local by = flr(self.pos.y) - 4
            draw_hp_bar(bx, by, self.hp, self.max_hp, 7, 1)
        end

        if debug_coll then
            local cx = flr(self.pos.x + self.off_x)
            local cy = flr(self.pos.y + self.off_y)

            circ(cx, cy, self.radius, 7)
        end
    end
end
