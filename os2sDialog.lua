dofile("./opensimplex2s.lua")

local function fbm2Loop(
    gen,
    vx, vy,
    cosa, sina,
    octaves, lacunarity, gain)

    local freq = 1.0
    local amp = 0.5
    local vinx = 0.0
    local viny = 0.0
    local vinz = 0.0
    local vinw = 0.0
    local sum = 0.0

    local oct = octaves or 8
    local lac = lacunarity or 1.0
    local gn = gain or 1.0

    local i = 0
    while i < oct do i = i + 1
        vinx = vx * freq
        viny = vy * freq
        vinz = sina * freq
        vinw = cosa * freq

        -- This noise variety is recommmended for this trick.
        -- https://necessarydisorder.wordpress.com/2017/11/15/
        -- drawing-from-noise-and-then-making-animated-
        -- loopy-gifs-from-there/
        sum = sum + amp * gen:noise4_XYBeforeZW(
            vinx, viny,
            vinz, vinw)

        freq = freq * lac
        amp = amp * gn
    end

    return sum
end

local function lerpRGB(
    ar, ag, ab, aa,
    br, bg, bb, ba, t)
    local u = 1.0 - t
    return app.pixelColor.rgba(
        math.floor(u * ar + t * br),
        math.floor(u * ag + t * bg),
        math.floor(u * ab + t * bb),
        math.floor(u * aa + t * ba))
end

local dlg = Dialog { title = "Noise" }

dlg:check {
    id = "useSeed",
    label = "Use Seed:",
    selected = false,
    onclick = function()
        dlg:modify {
            id = "seed",
            visible = dlg.data.useSeed
        }
    end
}

dlg:number {
    id = "seed",
    text = string.format("%d", os.time()),
    decimals = 0,
    visible = false
}

dlg:newrow { always = false }

dlg:number {
    id = "scale",
    label = "Scale:",
    text = string.format("%.5f", 2.0),
    decimals = 5
}

dlg:newrow { always = false }

dlg:number {
    id = "radius",
    label = "Radius:",
    text = string.format("%.5f", 1.0),
    decimals = 5
}

dlg:newrow { always = false }

dlg:number {
    id = "xOrigin",
    label = "Origin:",
    text = string.format("%.1f", 0.0),
    decimals = 5
}

dlg:number {
    id = "yOrigin",
    text = string.format("%.1f", 0.0),
    decimals = 5
}

dlg:newrow { always = false }

dlg:slider {
    id = "octaves",
    label = "Octaves:",
    min = 1,
    max = 32,
    value = 8
}

dlg:newrow { always = false }

dlg:number {
    id = "lacunarity",
    label = "Lacunarity:",
    text = string.format("%.5f", 1.75),
    decimals = 5
}

dlg:newrow { always = false }

dlg:number {
    id = "gain",
    label = "Gain:",
    text = string.format("%.5f", 0.5),
    decimals = 5
}

dlg:newrow { always = false }

dlg:slider {
    id = "quantization",
    label = "Quantize:",
    min = 0,
    max = 32,
    value = 0
}

dlg:newrow { always = false }

dlg:slider {
    id = "frames",
    label = "Frames:",
    min = 1,
    max = 96,
    value = 0
}

dlg:newrow { always = false }

dlg:slider {
    id = "fps",
    label = "FPS:",
    min = 1,
    max = 50,
    value = 12
}

dlg:newrow { always = false }

dlg:color {
    id = "aColor",
    label = "Colors:",
    color = Color(0, 0, 0, 255)
}

dlg:color {
    id = "bColor",
    color = Color(255, 255, 255, 255)
}

dlg:newrow { always = false }

dlg:button {
    id = "okButton",
    text = "&OK",
    focus = false,
    onclick = function()

        -- Unpack arguments.
        local args = dlg.data
        local useSeed = args.useSeed
        local octaves = args.octaves
        local lacun = args.lacunarity
        local gain = args.gain
        local reqFrames = args.frames
        local fps = args.fps or 12
        local duration = 1.0 / math.max(1, fps)
        local aColor = args.aColor or Color(0, 0, 0, 255)
        local bColor = args.bColor or Color(255, 255, 255, 255)

        -- Seed.
        local seed = 0
        if useSeed then
            seed = args.seed
        else
            seed = math.random(
                math.mininteger,
                math.maxinteger)
        end

        -- Create a new sprite if none are active.
        local sprite = app.activeSprite
        local layer = nil
        if sprite == nil then
            sprite = Sprite(64, 64)
            app.activeSprite = sprite
            layer = sprite.layers[1]
            app.transaction(function()
                sprite.frames[1].duration = duration
                local pal = sprite.palettes[1]
                pal:resize(3)
                pal:setColor(0, Color(0, 0, 0, 0))
                pal:setColor(1, aColor)
                pal:setColor(2, bColor)
            end)
        else
            layer = sprite:newLayer()
        end

        layer.name = "Noise." .. string.format("%d", seed)
        layer.data = string.format("{\"seed\":%d}", seed)

        -- Normalize width and height, accounting
        -- for aspect ratio.
        local spec = sprite.spec
        local w = spec.width
        local h = spec.height
        local wInv = (w / h) / w
        local hInv = 1.0 / h

        -- Scale and offset.
        local scl = 1.0
        if args.scale ~= 0.0 then
            scl = args.scale
        end
        local rad = 1.0
        if args.radius ~= 0.0 then
            rad = args.radius
        end

        local ox = args.xOrigin or 0.0
        local oy = args.yOrigin or 0.0

        -- Assign quantization variables.
        local useQuantize = args.quantization > 0.0
        local delta = 1.0
        local levels = 1.0
        if useQuantize then
            levels = args.quantization
            delta = 1.0 / levels
        end

        -- Assign fbm variables.
        local os2s = OpenSimplex2S.new(seed)

        -- Assign new frames.
        local oldLen = #sprite.frames
        local needed = math.max(0, reqFrames - oldLen)
        app.transaction(function()
            for i = 1, needed, 1 do
                local frame = sprite:newEmptyFrame()
                frame.duration = duration
            end
        end)

        -- Decompose colors.
        local a0 = aColor.red
        local a1 = aColor.green
        local a2 = aColor.blue
        local a3 = aColor.alpha

        local b0 = bColor.red
        local b1 = bColor.green
        local b2 = bColor.blue
        local b3 = bColor.alpha

        -- Cache global methods
        local cos = math.cos
        local sin = math.sin
        local floor = math.floor

        -- Loop through frames.
        local toTheta = 6.283185307179586 / reqFrames
        local spriteFrames = sprite.frames
        app.transaction(function()
            local j = 0
            while j < reqFrames do
                local theta = j * toTheta
                j = j + 1
                local costheta = cos(theta)
                local sintheta = sin(theta)
                costheta = 0.5 + 0.5 * costheta
                sintheta = 0.5 + 0.5 * sintheta
                costheta = costheta * rad
                sintheta = sintheta * rad

                -- Create new cel.
                local frame = spriteFrames[j]
                local img = Image(spec)

                -- Loop over image pixels.
                local iterator = img:pixels()
                for elm in iterator do
                    local xPx = elm.x
                    local yPx = elm.y

                    local xNrm = xPx * wInv
                    local yNrm = yPx * hInv

                    xNrm = ox + scl * xNrm
                    yNrm = oy + scl * yNrm

                    local fac = fbm2Loop(
                        os2s, xNrm, yNrm,
                        costheta, sintheta,
                        octaves, lacun, gain)

                    -- Quantize first, then shift
                    -- from [-1.0, 1.0] to [0.0,1.0].
                    if useQuantize then
                        fac = delta * floor(
                            0.5 + fac * levels)
                    end
                    fac = 0.5 + fac * 0.5
                    if fac < 0.0 then fac = 0.0
                    elseif fac > 1.0 then fac = 1.0 end

                    local clr = lerpRGB(
                        a0, a1, a2, a3,
                        b0, b1, b2, b3,
                        fac)
                    elm(clr)
                end

                sprite:newCel(layer, frame, img)
            end
        end)

        app.refresh()
    end
}

dlg:button {
    id = "cancelButton",
    text = "&CANCEL",
    onclick = function()
        dlg:close()
    end
}

dlg:show { wait = false }
