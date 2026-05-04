--Vector2
vec2 = {}
vec2.__index = vec2

function vec2:new(x, y)
    local v = setmetatable({}, self)

    v.x = x or 0
    v.y = y or 0
    return v
end

function vec2:add(v)
    self.x += v.x
    self.y += v.y
end

function vec2:mag()
    local ax = abs(self.x)
    local ay = abs(self.y)
    local max = ax > ay and ax or ay
    if max == 0 then return 0 end
    local min = ax > ay and ay or ax
    local r = min / max
    return max * sqrt(1 + r * r)
end

function vec2:nrm()
    local mag = self:mag()
    if mag > 0 then
        self.x /= mag
        self.y /= mag
    end
end

function vec2:mul(x)
    self.x *= x
    self.y *= x
end

--collision

function check_overlap_circle(pos1, pos2, r1, r2)
    local dx = abs(pos1.x - pos2.x)
    local dy = abs(pos1.y - pos2.y)
    local r = r1 + r2

    -- quick exit for far away objects to prevent overflow
    if dx > r or dy > r then return false end

    local sq_dist = (dx * dx) + (dy * dy)
    local sq_rad = r * r

    return sq_dist < sq_rad
end

function draw_hp_bar(x, y, hp, max_hp, w, h)
    local pct = mid(0, hp / max_hp, 1)
    local fill = flr(w * pct)
    -- background
    rectfill(x, y, x + w, y + h, 1)
    -- fill color
    local col = 10
    -- yellow
    if pct < 0.25 then col = 8 end
    -- red
    if fill > 0 then
        rectfill(x, y, x + fill, y + h, col)
    end
end

function draw_map(x, y)
    local start_tx = flr(x / 8)
    local start_ty = flr(y / 8)

    for i = 0, 16 do
        for j = 0, 16 do
            local tile_x = (start_tx + i) % 128
            local tile_y = (start_ty + j) % 32

            local draw_x = (start_tx + i) * 8
            local draw_y = (start_ty + j) * 8

            spr(mget(tile_x, tile_y), draw_x, draw_y)
        end
    end
end

-- rotate sprite - LLM assisted
function rspr(s, x, y, a, w, h)
    w = w or 1
    h = h or 1
    local sw, sh = w * 8, h * 8
    local sx, sy = s % 16 * 8, flr(s / 16) * 8
    for i = 0, sh - 1 do
        for j = 0, sw - 1 do
            local dx, dy = j - sw / 2, i - sh / 2
            local rx = dx * cos(a) - dy * sin(a)
            local ry = dx * sin(a) + dy * cos(a)
            local c = sget(sx + j, sy + i)
            if c != 0 then pset(x + rx, y + ry, c) end
        end
    end
end

-- resolve overlap between two entities
function resolve_overlap(e1, e2)
    local p1_x, p1_y = e1.pos.x + e1.off_x, e1.pos.y + e1.off_y
    local p2_x, p2_y = e2.pos.x + e2.off_x, e2.pos.y + e2.off_y

    local dx = p1_x - p2_x
    local dy = p1_y - p2_y

    -- quick AABB check for speed
    local r = e1.radius + e2.radius
    if abs(dx) > r or abs(dy) > r then return end

    -- safe mag
    local d_vec = vec2:new(dx, dy)
    local d = d_vec:mag()

    if d < r then
        -- overlap found
        local push = (r - d) / 2
        if d == 0 then
            -- exact same spot, push in random direction
            local ang = rnd(1)
            e1.pos.x += cos(ang) * push
            e1.pos.y += sin(ang) * push
            e2.pos.x -= cos(ang) * push
            e2.pos.y -= sin(ang) * push
        else
            local ux = dx / d
            local uy = dy / d
            e1.pos.x += ux * push
            e1.pos.y += uy * push
            e2.pos.x -= ux * push
            e2.pos.y -= uy * push
        end
    end
end