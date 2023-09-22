dofile("./opensimplex2s.lua")

---@param gen OpenSimplex2S
---@param vx number
---@param vy number
---@param cosa number
---@param sina number
---@param octaves integer?
---@param lacunarity number?
---@param gain number?
---@return number
local function fbm2Loop(
-- seed,
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
    while i < oct do
        i = i + 1
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

---@param gen OpenSimplex2S
---@param vx number
---@param vy number
---@param vz number
---@param vw number
---@param octaves integer?
---@param lacunarity number?
---@param gain number?
---@return number
local function fbm2Tile(
-- seed,
    gen,
    vx, vy, vz, vw,
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
    while i < oct do
        i = i + 1
        vinx = vx * freq
        viny = vy * freq
        vinz = vz * freq
        vinw = vw * freq

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

---@param arLin number
---@param agLin number
---@param abLin number
---@param at01 number
---@param brLin number
---@param bgLin number
---@param bbLin number
---@param bt01 number
---@param t number
---@param gammaInv number
---@return integer
---@return integer
---@return integer
---@return integer
local function mix(
    arLin, agLin, abLin, at01,
    brLin, bgLin, bbLin, bt01,
    t, gammaInv)
    local u = 1.0 - t
    local crLin = u * arLin + t * brLin
    local cgLin = u * agLin + t * bgLin
    local cbLin = u * abLin + t * bbLin

    local cr01 = crLin ^ gammaInv
    local cg01 = cgLin ^ gammaInv
    local cb01 = cbLin ^ gammaInv
    local ct01 = u * at01 + t * bt01

    local cr255 = math.floor(cr01 * 255 + 0.5)
    local cg255 = math.floor(cg01 * 255 + 0.5)
    local cb255 = math.floor(cb01 * 255 + 0.5)
    local ct255 = math.floor(ct01 * 255 + 0.5)

    return cr255, cg255, cb255, ct255
end

local dlg = Dialog { title = "Noise" }

dlg:check {
    id = "useSeed",
    label = "Use Seed:",
    selected = false,
    onclick = function()
        local args = dlg.data
        local use = args.useSeed --[[@as boolean]]
        dlg:modify { id = "seed", visible = use }
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
    text = string.format("%.5f", 0.0),
    decimals = 5
}

dlg:number {
    id = "yOrigin",
    text = string.format("%.5f", 0.0),
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

dlg:number {
    id = "spriteWidth",
    label = "Size:",
    text = string.format("%d",
        app.preferences.new_file.width),
    decimals = 0
}

dlg:number {
    id = "spriteHeight",
    text = string.format("%d",
        app.preferences.new_file.height),
    decimals = 0
}

dlg:newrow { always = false }

dlg:combobox {
    id = "mode",
    label = "Mode:",
    option = "ANIMATED",
    options = { "ANIMATED", "TILED" },
    onchange = function()
        local args = dlg.data
        local mode = args.mode --[[@as string]]
        local useAnim = mode == "ANIMATED"
        local useTile = mode == "TILED"
        dlg:modify { id = "frames", visible = useAnim }
        dlg:modify { id = "fps", visible = useAnim }
        dlg:modify { id = "scale", visible = not useTile }
    end
}

dlg:newrow { always = false }

dlg:slider {
    id = "frames",
    label = "Frames:",
    min = 1,
    max = 96,
    value = 8,
    visible = true
}

dlg:newrow { always = false }

dlg:slider {
    id = "fps",
    label = "FPS:",
    min = 1,
    max = 50,
    value = 12,
    visible = true
}

dlg:newrow { always = false }

dlg:color {
    id = "aColor",
    label = "Colors:",
    color = Color { r = 0, g = 0, b = 0, a = 255 }
}

dlg:color {
    id = "bColor",
    color = Color { r = 255, g = 255, b = 255, a = 255 }
}

dlg:newrow { always = false }

dlg:button {
    id = "okButton",
    text = "&OK",
    focus = false,
    onclick = function()
        -- Unpack arguments.
        local args = dlg.data
        local mode = args.mode --[[@as string]]
        local useSeed = args.useSeed --[[@as boolean]]
        local seedNum = args.seed --[[@as number]]
        local scale = args.scale --[[@as number]]
        local radius = args.radius --[[@as number]]
        local xOrigin = args.xOrigin --[[@as number]]
        local yOrigin = args.yOrigin --[[@as number]]
        local octaves = args.octaves --[[@as integer]]
        local lacunarity = args.lacunarity --[[@as number]]
        local gain = args.gain --[[@as number]]
        local quantization = args.quantization --[[@as integer]]
        local widthNum = args.spriteWidth --[[@as number]]
        local heightNum = args.spriteHeight --[[@as number]]
        local aColor = args.aColor --[[@as Color]]
        local bColor = args.bColor --[[@as Color]]

        -- Validate width and height.
        local widthVrf = math.min(math.max(math.floor(
            math.abs(widthNum) + 0.5), 1), 65535)
        local heightVrf = math.min(math.max(math.floor(
            math.abs(heightNum) + 0.5), 1), 65535)
        local flatLen = widthVrf * heightVrf

        -- Store new dimensions in preferences.
        local filePrefs = app.preferences.new_file
        filePrefs.width = widthVrf
        filePrefs.height = heightVrf

        -- Validate seed.
        local seedVrf = 0
        if useSeed then
            seedVrf = math.floor(seedNum)
        else
            seedVrf = math.random(
                math.mininteger,
                math.maxinteger)
        end

        -- Validate scale and radius.
        local scaleVrf = 2.0
        if scale ~= 0.0 and mode ~= "TILED" then scaleVrf = scale end
        local radiusVrf = 1.0
        if radius ~= 0.0 then radiusVrf = radius end

        -- Validate quantization.
        local useQuantize = quantization > 0.0
        local delta = 1.0
        local levels = 1.0
        if useQuantize then
            levels = quantization
            delta = 1.0 / levels
        end

        -- Colors need to be unpacked before new sprite created.
        local gamma = 2.2
        local gammaInv = 1.0 / gamma

        local aRed = aColor.red
        local aGreen = aColor.green
        local aBlue = aColor.blue
        local aAlpha = aColor.alpha

        local ar01 = aRed / 255.0
        local ag01 = aGreen / 255.0
        local ab01 = aBlue / 255.0
        local at01 = aAlpha / 255.0

        local arLin = ar01 ^ gamma
        local agLin = ag01 ^ gamma
        local abLin = ab01 ^ gamma

        local bRed = bColor.red
        local bGreen = bColor.green
        local bBlue = bColor.blue
        local bAlpha = bColor.alpha

        local br01 = bRed / 255.0
        local bg01 = bGreen / 255.0
        local bb01 = bBlue / 255.0
        local bt01 = bAlpha / 255.0

        local brLin = br01 ^ gamma
        local bgLin = bg01 ^ gamma
        local bbLin = bb01 ^ gamma

        -- Create new sprite, load default palette.
        local activeSprite = Sprite(widthVrf, heightVrf)
        local activeLayer = activeSprite.layers[1]
        activeLayer.name = string.format("Noise.%d", seedVrf)
        app.command.LoadPalette { preset = "default" }

        -- Cache methods used in loop.
        local cos = math.cos
        local sin = math.sin
        local floor = math.floor
        local composeRgba = app.pixelColor.rgba
        local os2s = OpenSimplex2S.new(seedVrf)
        local pi = math.pi
        local tau = pi + pi

        local spriteFrames = activeSprite.frames
        local firstFrame = spriteFrames[1]

        local spriteSpec = activeSprite.spec

        local docPrefs = app.preferences.document(activeSprite)
        local onionSkinPrefs = docPrefs.onionskin
        onionSkinPrefs.loop_tag = false

        if mode == "TILED" then
            local wInv = 1.0 / widthVrf
            local hInv = 1.0 / heightVrf

            ---@type number[]
            local factors = {}
            local tMin = 100000
            local tMax = -100000
            local j = 0
            while j < flatLen do
                local xPx = j % widthVrf
                local yPx = j // widthVrf

                local xNrm = xPx * wInv
                local yNrm = yPx * hInv
                local xSgn = xNrm - 0.5
                local ySgn = yNrm - 0.5
                local xTransform = xSgn * scaleVrf + xOrigin
                local yTransform = ySgn * scaleVrf + yOrigin

                local sx = radiusVrf * cos(xTransform * pi)
                local sy = radiusVrf * sin(xTransform * pi)
                local sz = radiusVrf * cos(yTransform * pi)
                local sw = radiusVrf * sin(yTransform * pi)

                local t = fbm2Tile(
                    os2s,
                    sx, sy, sz, sw,
                    octaves, lacunarity, gain)

                if t < tMin then tMin = t end
                if t > tMax then tMax = t end
                j = j + 1
                factors[j] = t
            end

            local tRange = tMax - tMin
            local tDenom = 0.0
            if tRange ~= 0.0 then tDenom = 1.0 / tRange end

            j = 0
            local image = Image(spriteSpec)
            local iterator = image:pixels()
            for pixel in iterator do
                j = j + 1

                local t = (factors[j] - tMin) * tDenom
                if useQuantize then
                    t = delta * floor(0.5 + t * levels)
                end

                local cr255, cg255, cb255, ct255 = mix(
                    arLin, agLin, abLin, at01,
                    brLin, bgLin, bbLin, bt01,
                    t, gammaInv)
                pixel(composeRgba(cr255, cg255, cb255, ct255))
            end

            activeSprite:newCel(activeLayer, firstFrame, image)

            docPrefs.tiled.mode = 3
        else
            -- Create new empty frames per request.
            local framesCount = args.frames --[[@as integer]]
            local fps = args.fps --[[@as integer]]

            local duration = 1.0 / math.max(1, fps)
            if framesCount > 1 then
                app.transaction(function()
                    firstFrame.duration = duration
                    local i = 1
                    while i < framesCount do
                        i = i + 1
                        local frObj = activeSprite:newEmptyFrame()
                        frObj.duration = duration
                    end
                end)
            else
                firstFrame.duration = duration
            end

            local iToTheta = tau / framesCount
            local aspect = (widthVrf - 1.0) / (heightVrf - 1.0)
            local wInv = aspect / (widthVrf - 1.0)
            local hInv = 1.0 / (heightVrf - 1.0)
            local scaleDivWidth = scaleVrf * wInv
            local scaleDivHeight = scaleVrf * hInv

            app.transaction(function()
                local i = 0
                while i < framesCount do
                    local iTheta = i * iToTheta
                    local cosTheta = cos(iTheta)
                    local sinTheta = sin(iTheta)
                    local cost01 = cosTheta * 0.5 + 0.5
                    local sint01 = sinTheta * 0.5 + 0.5
                    local costRad = radiusVrf * cost01
                    local sintRad = radiusVrf * sint01

                    ---@type number[]
                    local factors = {}
                    local tMin = 100000
                    local tMax = -100000
                    local j = 0
                    while j < flatLen do
                        local xPx = j % widthVrf
                        local yPx = j // widthVrf
                        local xTransform = xPx * scaleDivWidth + xOrigin
                        local yTransform = yPx * scaleDivHeight + yOrigin

                        local t = fbm2Loop(
                            os2s,
                            xTransform, yTransform,
                            costRad, sintRad,
                            octaves, lacunarity, gain)
                        if t < tMin then tMin = t end
                        if t > tMax then tMax = t end

                        j = j + 1
                        factors[j] = t
                    end

                    local tRange = tMax - tMin
                    local tDenom = 0.0
                    if tRange ~= 0.0 then tDenom = 1.0 / tRange end

                    j = 0
                    local image = Image(spriteSpec)
                    local iterator = image:pixels()
                    for pixel in iterator do
                        j = j + 1

                        local t = (factors[j] - tMin) * tDenom
                        if useQuantize then
                            t = delta * floor(0.5 + t * levels)
                        end

                        local cr255, cg255, cb255, ct255 = mix(
                            arLin, agLin, abLin, at01,
                            brLin, bgLin, bbLin, bt01,
                            t, gammaInv)
                        pixel(composeRgba(cr255, cg255, cb255, ct255))
                    end

                    i = i + 1
                    local frObj = spriteFrames[i]
                    activeSprite:newCel(activeLayer, frObj, image)
                end
            end)
        end

        if app.apiVersion >= 23 then
            app.sprite = activeSprite
            app.frame = firstFrame
            app.layer = activeLayer
        else
            app.activeSprite = activeSprite
            app.activeFrame = firstFrame
            app.activeLayer = activeLayer
        end
        app.command.FitScreen()
        app.refresh()
    end
}

dlg:button {
    id = "cancelButton",
    text = "&CANCEL",
    focus = true,
    onclick = function()
        dlg:close()
    end
}

dlg:show { wait = false }
