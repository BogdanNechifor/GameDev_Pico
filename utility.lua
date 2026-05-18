

--collision
function check_overlap_circle(x1, y1, x2, y2, r1, r2)
    local dx = abs(x1 - x2)
    local dy = abs(y1 - y2)
    local r = r1 + r2

    if dx > r or dy > r then return false end

    return (dx * dx) + (dy * dy) < (r * r)
end

function draw_hp_bar(x, y, hp, max_hp, w, h)
    local pct = mid(0, hp / max_hp, 1)
    local fill = flr(w * pct)
    rectfill(x, y, x + w, y + h, 1)
    local col = 10
    if pct < 0.25 then col = 8 end
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
    
    local cos_a = cos(a)
    local sin_a = sin(a)
    local half_w = sw / 2
    local half_h = sh / 2
    
    for i = 0, sh - 1 do
        local dy = i - half_h
        local dy_cos = dy * cos_a
        local dy_sin = dy * sin_a
        
        for j = 0, sw - 1 do
            local dx = j - half_w
            local rx = dx * cos_a - dy_sin
            local ry = dx * sin_a + dy_cos
            
            local c = sget(sx + j, sy + i)
            if c != 0 then pset(x + rx, y + ry, c) end
        end
    end
end

-- resolve overlap between two entities - LLM assisted
function resolve_overlap(e1, e2)
    local p1_x, p1_y = e1.pos.x + e1.off_x, e1.pos.y + e1.off_y
    local p2_x, p2_y = e2.pos.x + e2.off_x, e2.pos.y + e2.off_y

    local dx = p1_x - p2_x
    local dy = p1_y - p2_y

    local r = e1.radius + e2.radius
    if abs(dx) > r or abs(dy) > r then return end

    local d = sqrt(dx * dx + dy * dy)

    if d < r then
        local push = (r - d) / 2
        if d == 0 then
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

-- UI and Progression Utilities
floating_texts = {}
level_effects = {}

function print_centered_text(txt, cx, y, col)
    local w = #txt * 4
    print(txt, cx - flr(w / 2), y, col or 7)
end

function draw_xp_bar(x, y, xp, max_xp, w, h)
    local pct = mid(0, xp / max_xp, 1)
    local fill = flr(w * pct)
    rectfill(x, y, x + w, y + h, 1) -- dark blue bg
    
    if p.level >= p.level_cap then
        rectfill(x, y, x + w, y + h, 11) -- full green bar at max level
        print_centered_text("max", x + flr(w / 2), y - 1, 0)
        print_centered_text("max", x + flr(w / 2) - 1, y - 2, 7)
    elseif fill > 0 then
        rectfill(x, y, x + fill, y + h, 11) -- emerald green fill
    end
end

function get_level_up_options()
    local available = {}
    
    -- Check speed
    if p.vel < 1.9 then
        add(available, { id = "speed", title = "speed", desc = "+0.1 speed" })
    end
    
    -- Check haste
    if p.firerate > 15 then
        add(available, { id = "haste", title = "haste", desc = "+8% fire rate" })
    end
    
    -- Check multishot
    if p.level > 10 and p.fireballs_count < 3 and rnd(1) < 0.5 then
        add(available, { id = "multishot", title = "multishot", desc = "+1 fireball" })
    end

    -- Check crit
    if p.crit_chance < 0.37 then
        add(available, { id = "crit", title = "crit", desc = "+4% crit chance" })
    end
    
    -- Check splash
    if p.splash_ratio < 0.92 then
        add(available, { id = "splash", title = "splash", desc = "+8% splash dmg" })
    end
    
    -- Check damage (up to 9 upgrades)
    if p.upgrades.damage < 9 then
        add(available, { id = "damage", title = "might", desc = "+4 fireball dmg" })
    end
    
    -- Check vitality (uncapped)
    if p.hp < p.max_hp * 0.3 or #available < 2 then
        add(available, { id = "vitality", title = "vitality", desc = "max hp & heal" })
    end

    -- Pick 2 distinct options randomly
    local opt1 = available[flr(rnd(#available)) + 1]
    del(available, opt1)
    
    local opt2 = nil
    if #available > 0 then
        opt2 = available[flr(rnd(#available)) + 1]
    else
        opt2 = { id = "vitality", title = "vitality", desc = "max hp & heal" }
    end
    
    return { opt1, opt2 }
end

function apply_upgrade(choice)
    local id = choice.id
    if id == "speed" then
        p.vel = min(1.9, p.vel + 0.1)
    elseif id == "haste" then
        p.firerate = max(15, flr(p.firerate * 0.92))
    elseif id == "multishot" then
        p.fireballs_count = min(3, p.fireballs_count + 1)
    elseif id == "crit" then
        p.crit_chance = min(0.37, p.crit_chance + 0.04)
    elseif id == "splash" then
        p.splash_ratio = min(0.92, p.splash_ratio + 0.08)
    elseif id == "damage" then
        p.fire_damage += 4
    elseif id == "vitality" then
        p.max_hp += 20
        p.hp = p.max_hp
    end

    -- Increment the tracker
    if p.upgrades[id] != nil then
        p.upgrades[id] += 1
    end

    -- Return to play state
    game_state = "play"

    -- Check if we level up again
    if p.level < p.level_cap and p.xp >= p.max_xp then
        p:level_up()
    end
end

-- VFX: Floating Text
function add_floating_text(txt, x, y, col)
    add(floating_texts, {
        text = txt,
        x = x,
        y = y,
        col = col or 7,
        timer = 30
    })
end

function update_floating_texts()
    for ft in all(floating_texts) do
        ft.y -= 0.5
        ft.timer -= 1
        if ft.timer <= 0 then
            del(floating_texts, ft)
        end
    end
end

function draw_floating_texts()
    for ft in all(floating_texts) do
        -- black shadow for contrast
        print(ft.text, flr(ft.x) - 4 + 1, flr(ft.y) + 1, 0)
        print(ft.text, flr(ft.x) - 4, flr(ft.y), ft.col)
    end
end

-- VFX: Level Up Concentric Rings
function trigger_level_up_effect(pos)
    add(level_effects, {
        type = "levelup",
        x = pos.x + 4,
        y = pos.y + 4,
        r = 1,
        max_r = 25,
        timer = 20
    })
end

function trigger_explosion_effect(x, y, radius)
    add(level_effects, {
        type = "explosion",
        x = x,
        y = y,
        r = 1,
        max_r = radius or 24,
        timer = 8
    })
end

function update_level_effects()
    for le in all(level_effects) do
        if le.type == "levelup" then
            le.r += 1.5
        else -- explosion
            le.r = le.max_r * (1 - (le.timer / 8))
        end
        le.timer -= 1
        if le.timer <= 0 then
            del(level_effects, le)
        end
    end
end

function draw_level_effects()
    for le in all(level_effects) do
        if le.type == "levelup" then
            circ(flr(le.x), flr(le.y), flr(le.r), 10)
            circ(flr(le.x), flr(le.y), flr(le.r - 3), 9)
        else -- explosion
            local col = le.timer > 4 and 9 or (le.timer > 2 and 10 or 15)
            circfill(flr(le.x), flr(le.y), flr(le.r), col)
        end
    end
end