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

    local oct <const> = octaves or 8
    local lac <const> = lacunarity or 1.0
    local gn <const> = gain or 1.0

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

    local oct <const> = octaves or 8
    local lac <const> = lacunarity or 1.0
    local gn <const> = gain or 1.0

    local i = 0
    while i < oct do
        i = i + 1
        vinx = vx * freq
        viny = vy * freq
        vinz = vz * freq
        vinw = vw * freq

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
    local u <const> = 1.0 - t
    local crLin <const> = u * arLin + t * brLin
    local cgLin <const> = u * agLin + t * bgLin
    local cbLin <const> = u * abLin + t * bbLin

    local cr01 <const> = crLin ^ gammaInv
    local cg01 <const> = cgLin ^ gammaInv
    local cb01 <const> = cbLin ^ gammaInv
    local ct01 <const> = u * at01 + t * bt01

    local cr255 <const> = math.floor(cr01 * 255 + 0.5)
    local cg255 <const> = math.floor(cg01 * 255 + 0.5)
    local cb255 <const> = math.floor(cb01 * 255 + 0.5)
    local ct255 <const> = math.floor(ct01 * 255 + 0.5)

    return cr255, cg255, cb255, ct255
end

local dlg = Dialog { title = "Noise" }

dlg:check {
    id = "useSeed",
    label = "Use Seed:",
    selected = false,
    onclick = function()
        local args <const> = dlg.data
        local use <const> = args.useSeed --[[@as boolean]]
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
        local args <const> = dlg.data
        local mode <const> = args.mode --[[@as string]]
        local useAnim <const> = mode == "ANIMATED"
        local useTile <const> = mode == "TILED"
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
        local args <const> = dlg.data
        local mode <const> = args.mode --[[@as string]]
        local useSeed <const> = args.useSeed --[[@as boolean]]
        local seedNum <const> = args.seed --[[@as number]]
        local scale <const> = args.scale --[[@as number]]
        local radius <const> = args.radius --[[@as number]]
        local xOrigin <const> = args.xOrigin --[[@as number]]
        local yOrigin <const> = args.yOrigin --[[@as number]]
        local octaves <const> = args.octaves --[[@as integer]]
        local lacunarity <const> = args.lacunarity --[[@as number]]
        local gain <const> = args.gain --[[@as number]]
        local quantization <const> = args.quantization --[[@as integer]]
        local widthNum <const> = args.spriteWidth --[[@as number]]
        local heightNum <const> = args.spriteHeight --[[@as number]]
        local aColor <const> = args.aColor --[[@as Color]]
        local bColor <const> = args.bColor --[[@as Color]]

        -- Validate width and height.
        local widthVrf <const> = math.min(math.max(math.floor(
            math.abs(widthNum) + 0.5), 1), 65535)
        local heightVrf <const> = math.min(math.max(math.floor(
            math.abs(heightNum) + 0.5), 1), 65535)
        local flatLen <const> = widthVrf * heightVrf

        -- Store new dimensions in preferences.
        local filePrefs <const> = app.preferences.new_file
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
        local useQuantize <const> = quantization > 0.0
        local delta = 1.0
        local levels = 1.0
        if useQuantize then
            levels = quantization
            delta = 1.0 / levels
        end

        -- Colors need to be unpacked before new sprite created.
        local gamma <const> = 2.2
        local gammaInv <const> = 1.0 / gamma

        local aRed <const> = aColor.red
        local aGreen <const> = aColor.green
        local aBlue <const> = aColor.blue
        local aAlpha <const> = aColor.alpha

        local ar01 <const> = aRed / 255.0
        local ag01 <const> = aGreen / 255.0
        local ab01 <const> = aBlue / 255.0
        local at01 <const> = aAlpha / 255.0

        local arLin <const> = ar01 ^ gamma
        local agLin <const> = ag01 ^ gamma
        local abLin <const> = ab01 ^ gamma

        local bRed <const> = bColor.red
        local bGreen <const> = bColor.green
        local bBlue <const> = bColor.blue
        local bAlpha <const> = bColor.alpha

        local br01 <const> = bRed / 255.0
        local bg01 <const> = bGreen / 255.0
        local bb01 <const> = bBlue / 255.0
        local bt01 <const> = bAlpha / 255.0

        local brLin <const> = br01 ^ gamma
        local bgLin <const> = bg01 ^ gamma
        local bbLin <const> = bb01 ^ gamma

        -- Create new sprite, load default palette.
        local spriteSpec = ImageSpec {
            width = widthVrf,
            height = heightVrf,
            colorMode = ColorMode.RGB,
            transparentColor = 0
        }
        spriteSpec.colorSpace = ColorSpace { sRGB = true }

        local oldPalette = app.defaultPalette
        local oldSprite <const> = app.sprite
        if oldSprite then
            oldPalette = oldSprite.palettes[1]
        end

        local activeSprite <const> = Sprite(spriteSpec)

        -- Onion skinning is bugged for tags.
        -- docPrefs is also needed to set the tiled view mode.
        local docPrefs <const> = app.preferences.document(activeSprite)
        docPrefs.onionskin.loop_tag = false

        local activeLayer <const> = activeSprite.layers[1]
        app.transaction("Name Layer", function()
            activeLayer.name = string.format("Noise %d", seedVrf)
        end)

        if oldPalette then
            app.transaction("Set Palette", function()
                activeSprite:setPalette(oldPalette)
            end)
        end

        -- Cache methods used in loop.
        local cos <const> = math.cos
        local sin <const> = math.sin
        local floor <const> = math.floor
        local strpack <const> = string.pack
        local tconcat <const> = table.concat

        -- Math constants.
        local pi <const> = math.pi
        local tau <const> = pi + pi

        local os2s <const> = OpenSimplex2S.new(seedVrf)
        local spriteFrames <const> = activeSprite.frames
        local firstFrame <const> = spriteFrames[1]

        if mode == "TILED" then
            local wInv <const> = 1.0 / widthVrf
            local hInv <const> = 1.0 / heightVrf

            ---@type number[]
            local factors <const> = {}
            local tMin = 100000
            local tMax = -100000
            local j = 0
            while j < flatLen do
                local xPx <const> = j % widthVrf
                local yPx <const> = j // widthVrf

                local xNrm <const> = xPx * wInv
                local yNrm <const> = yPx * hInv
                local xSgn <const> = xNrm - 0.5
                local ySgn <const> = yNrm - 0.5
                local xTransform <const> = xSgn * scaleVrf + xOrigin
                local yTransform <const> = ySgn * scaleVrf + yOrigin

                local sx <const> = radiusVrf * cos(xTransform * pi)
                local sy <const> = radiusVrf * sin(xTransform * pi)
                local sz <const> = radiusVrf * cos(yTransform * pi)
                local sw <const> = radiusVrf * sin(yTransform * pi)

                local t <const> = fbm2Tile(
                    os2s,
                    sx, sy, sz, sw,
                    octaves, lacunarity, gain)

                if t < tMin then tMin = t end
                if t > tMax then tMax = t end
                j = j + 1
                factors[j] = t
            end

            local tRange <const> = tMax - tMin
            local tDenom = 0.0
            if tRange ~= 0.0 then tDenom = 1.0 / tRange end

            ---@type string[]
            local byteStrs <const> = {}
            local k = 0
            while k < flatLen do
                k = k + 1

                local t = (factors[k] - tMin) * tDenom
                if useQuantize then
                    t = delta * floor(0.5 + t * levels)
                end

                local cr8 <const>, cg8 <const>, cb8 <const>, ct8 <const> = mix(
                    arLin, agLin, abLin, at01,
                    brLin, bgLin, bbLin, bt01,
                    t, gammaInv)
                byteStrs[k] = strpack("B B B B", cr8, cg8, cb8, ct8)
            end

            local image <const> = Image(spriteSpec)
            image.bytes = tconcat(byteStrs)
            activeSprite:newCel(activeLayer, firstFrame, image)

            docPrefs.tiled.mode = 3
        else
            -- Create new empty frames per request.
            local framesCount <const> = args.frames --[[@as integer]]
            local fps <const> = args.fps --[[@as integer]]

            local duration <const> = 1.0 / math.max(1, fps)
            if framesCount > 1 then
                app.transaction("Create Frames", function()
                    firstFrame.duration = duration
                    local i = 1
                    while i < framesCount do
                        i = i + 1
                        local frObj <const> = activeSprite:newEmptyFrame()
                        frObj.duration = duration
                    end
                end)
            else
                app.transaction("Set Duration", function()
                    firstFrame.duration = duration
                end)
            end

            local iToTheta <const> = tau / framesCount
            local aspect <const> = (widthVrf - 1.0) / (heightVrf - 1.0)
            local wInv <const> = aspect / (widthVrf - 1.0)
            local hInv <const> = 1.0 / (heightVrf - 1.0)
            local scaleDivWidth <const> = scaleVrf * wInv
            local scaleDivHeight <const> = scaleVrf * hInv

            app.transaction("Create Cels", function()
                local i = 0
                while i < framesCount do
                    local iTheta <const> = i * iToTheta
                    local cosTheta <const> = cos(iTheta)
                    local sinTheta <const> = sin(iTheta)
                    local cost01 <const> = cosTheta * 0.5 + 0.5
                    local sint01 <const> = sinTheta * 0.5 + 0.5
                    local costRad <const> = radiusVrf * cost01
                    local sintRad <const> = radiusVrf * sint01

                    ---@type number[]
                    local factors <const> = {}
                    local tMin = 100000
                    local tMax = -100000
                    local j = 0
                    while j < flatLen do
                        local xPx <const> = j % widthVrf
                        local yPx <const> = j // widthVrf
                        local xTransform <const> = xPx * scaleDivWidth + xOrigin
                        local yTransform <const> = yPx * scaleDivHeight + yOrigin

                        local t <const> = fbm2Loop(
                            os2s,
                            xTransform, yTransform,
                            costRad, sintRad,
                            octaves, lacunarity, gain)
                        if t < tMin then tMin = t end
                        if t > tMax then tMax = t end

                        j = j + 1
                        factors[j] = t
                    end

                    local tRange <const> = tMax - tMin
                    local tDenom = 0.0
                    if tRange ~= 0.0 then tDenom = 1.0 / tRange end

                    ---@type string[]
                    local byteStrs <const> = {}
                    local k = 0
                    while k < flatLen do
                        k = k + 1

                        local t = (factors[k] - tMin) * tDenom
                        if useQuantize then
                            t = delta * floor(0.5 + t * levels)
                        end

                        local cr8 <const>, cg8 <const>, cb8 <const>, ct8 <const> = mix(
                            arLin, agLin, abLin, at01,
                            brLin, bgLin, bbLin, bt01,
                            t, gammaInv)
                        byteStrs[k] = strpack("B B B B", cr8, cg8, cb8, ct8)
                    end

                    i = i + 1
                    local frObj <const> = spriteFrames[i]
                    local image <const> = Image(spriteSpec)
                    image.bytes = tconcat(byteStrs)
                    activeSprite:newCel(activeLayer, frObj, image)
                end
            end)
        end

        app.sprite = activeSprite
        app.frame = firstFrame
        app.layer = activeLayer
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

dlg:show {
    autoscrollbars = false,
    wait = false
}