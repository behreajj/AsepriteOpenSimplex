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

    for i = 0, oct - 1, 1 do
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
        math.tointeger(u * ar + t * br),
        math.tointeger(u * ag + t * bg),
        math.tointeger(u * ab + t * bb),
        math.tointeger(u * aa + t * ba))
end

local dlg = Dialog { title = "Noise" }

dlg:check {
    id = "useSeed",
    label = "Use Seed:",
    selected = false
}

dlg:number {
    id = "seed",
    label = "Seed:",
    text = string.format("%d", os.time()),
    decimals = 0
}

dlg:number {
    id = "scale",
    label = "Scale:",
    text = string.format("%.5f", 2.0),
    decimals = 5
}

dlg:number {
    id = "radius",
    label = "Radius:",
    text = string.format("%.5f", 1.0),
    decimals = 5
}

dlg:number {
    id = "xOrigin",
    label = "Origin X:",
    text = string.format("%.1f", 0.0),
    decimals = 5
}

dlg:number {
    id = "yOrigin",
    label = "Origin Y:",
    text = string.format("%.1f", 0.0),
    decimals = 5
}

dlg:slider {
    id = "octaves",
    label = "Octaves:",
    min = 1,
    max = 32,
    value = 8
}

dlg:number {
    id = "lacunarity",
    label = "Lacunarity:",
    text = string.format("%.5f", 1.75),
    decimals = 5
}

dlg:number {
    id = "gain",
    label = "Gain:",
    text = string.format("%.5f", 0.5),
    decimals = 5
}

dlg:slider {
    id = "quantization",
    label = "Quantize:",
    min = 0,
    max = 32,
    value = 0
}

dlg:slider {
    id = "frames",
    label = "Frames:",
    min = 1,
    max = 96,
    value = 0
}

dlg:color {
    id = "aColor",
    label = "Color A:",
    color = Color(32, 32, 32, 255)
}

dlg:color {
    id = "bColor",
    label = "Color B:",
    color = Color(255, 245, 215, 255)
}

dlg:button {
    id = "ok",
    text = "OK",
    focus = true,
    onclick = function()
        local args = dlg.data
        if args.ok then

            -- Create a new sprite if none are active.
            local sprite = app.activeSprite
            local layer = nil
            if sprite == nil then
                sprite = Sprite(64, 64)
                app.activeSprite = sprite
                layer = sprite.layers[1]
            else
                layer = sprite:newLayer()
            end
            layer.name = "Noise"

            -- Normalize width and height, accounting
            -- for aspect ratio.
            local w = sprite.width
            local h = sprite.height

            local shortEdge = math.min(w, h)
            local longEdge = math.max(w, h)

            local wInv = 1.0
            local hInv = 1.0 / h

            if shortEdge == longEdge then
                wInv = 1.0 / w
            elseif w == shortEdge then
                local aspect = (shortEdge / longEdge)
                wInv = aspect / w
            elseif h == shortEdge then
                local aspect = (longEdge / shortEdge)
                wInv = aspect / w
            end

            -- Seed.
            local seed = 0
            if args.useSeed then
                seed = args.seed
            else
                seed = math.random(
                    math.mininteger,
                    math.maxinteger)
            end

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
            local octaves = args.octaves
            local lacun = args.lacunarity
            local gain = args.gain

            -- Assign new frames.
            local reqFrames = args.frames
            local oldLen = #sprite.frames
            local needed = math.max(0, reqFrames - oldLen)
            for i = 1, needed, 1 do
                sprite:newEmptyFrame()
            end

            -- Decompose colors.
            local aColor = args.aColor or Color(0xff000000)
            local a0 = aColor.red
            local a1 = aColor.green
            local a2 = aColor.blue
            local a3 = aColor.alpha

            local bColor = args.bColor or Color(0xffffffff)
            local b0 = bColor.red
            local b1 = bColor.green
            local b2 = bColor.blue
            local b3 = bColor.alpha

            -- Loop through frames.
            local toTheta = 6.283185307179586 / reqFrames
            for j = 0, reqFrames - 1, 1 do

                -- Convert frame position to z and w theta.
                local theta = j * toTheta
                local costheta = math.cos(theta)
                local sintheta = math.sin(theta)
                costheta = 0.5 + 0.5 * costheta
                sintheta = 0.5 + 0.5 * sintheta
                costheta = costheta * rad
                sintheta = sintheta * rad

                -- Create new cel.
                local frame = sprite.frames[1 + j]
                local cel = sprite:newCel(layer, frame)
                local img = cel.image

                -- Loop over image pixels.
                local iterator = img:pixels()
                local i = 0
                for elm in iterator do
                    local xPx = i % w
                    local yPx = i // w

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
                        fac = delta * math.floor(
                            0.5 + fac * levels)
                    end
                    fac = 0.5 + fac * 0.5
                    fac = math.max(0.0, math.min(1.0, fac))

                    local clr = lerpRGB(
                        a0, a1, a2, a3,
                        b0, b1, b2, b3,
                        fac)
                    elm(clr)

                    i = i + 1
                end
            end

            app.refresh()
        end
    end
}

dlg:button {
    id = "cancel",
    text = "CANCEL",
    onclick = function()
        dlg:close()
    end
}

dlg:show { wait = false }