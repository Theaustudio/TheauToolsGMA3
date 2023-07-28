--  __   __        __   __      __     __        ___  __      __         ___       ___            __  ___       __     __  
-- /  ` /  \ |    /  \ |__)    |__) | /  ` |__/ |__  |__)    |__) \ /     |  |__| |__   /\  |  | /__`  |  |  | |  \ | /  \ 
-- \__, \__/ |___ \__/ |  \    |    | \__, |  \ |___ |  \    |__)  |      |  |  | |___ /~~\ \__/ .__/  |  \__/ |__/ | \__/ 
local sequenceStartIndex = 1000
local appearanceStartIndex = 1000
local layoutIndex = 1500
local dataPoolIndex = 100

-- ██████╗ ███████╗██████╗ ██╗   ██╗ ██████╗ 
-- ██╔══██╗██╔════╝██╔══██╗██║   ██║██╔════╝ 
-- ██║  ██║█████╗  ██████╔╝██║   ██║██║  ███╗
-- ██║  ██║██╔══╝  ██╔══██╗██║   ██║██║   ██║
-- ██████╔╝███████╗██████╔╝╚██████╔╝╚██████╔╝
-- ╚═════╝ ╚══════╝╚═════╝  ╚═════╝  ╚═════╝ 

local function testDebugError()
    xpcall(function()
        -- Code to actually run:
        error();
    end, function(e)
        if debuggee.enterDebugLoop(1, e) then
            -- ok
        else
            -- If the debugger is not attached, enter here.
            Printf(e)
            Printf(debug.traceback())
        end
    end)
end

local function enterDebugLoop()
    coroutine.yield(0.5)
    debuggee.enterDebugLoop(1)
end

-- ███╗   ███╗ █████╗ ██╗███╗   ██╗
-- ████╗ ████║██╔══██╗██║████╗  ██║
-- ██╔████╔██║███████║██║██╔██╗ ██║
-- ██║╚██╔╝██║██╔══██║██║██║╚██╗██║
-- ██║ ╚═╝ ██║██║  ██║██║██║ ╚████║
-- ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝

local function main()
    require 'gma3_debug'()
    require("gma3_helpers")
    debuggee.print("log", "start")

    colorPicker()

    debuggee.print("log", "done")
end

function colorPicker()
    local colorPickerUndo = CreateUndo("generate Color Picker")
    Cmd("ClearAll")

    local fromGroup = askListObject(DataPool().Groups, "From Group")
    local toGroup = askListObject(DataPool().Groups, "To Group")
    debuggee.print("log", "fromGroup = #" .. fromGroup.index .. " " .. fromGroup.name)
    debuggee.print("log", "toGroup = #" .. toGroup.index .. " " .. toGroup.name)

    -- Select Presets
    local fromColorPreset = askListObject(DataPool().PresetPools[4], "From Preset")
    local toColorPreset = askListObject(DataPool().PresetPools[4], "To Preset", fromColorPreset.index)

    debuggee.print("log", "fromColorPreset = " .. fromColorPreset.name)
    debuggee.print("log", "toColorPreset = " .. toColorPreset.name)

    -- debuggee.print("log", gma3_helpers:dumpObj(DataPool()))

    Cmd("Delete Layout " .. layoutIndex)
    Cmd("Store Layout " .. layoutIndex)
    local layout = DataPool().Layouts[layoutIndex]
    local OnToken = GetTokenName("on")
    Cmd("Store DataPool " .. dataPoolIndex .. " /Overwrite")
    local pool = ObjectList("DataPool " .. dataPoolIndex)[1]

    -- Groups i
    local groupsPool = DataPool().Groups:Children()

    local groupProgHandle = StartProgress("groupProgress")
    local endIdx = 0
    for _ in pairs(groupsPool) do
        endIdx = endIdx + 1
    end
    SetProgressRange(groupProgHandle, 0, endIdx)

    local index = 0
    for i, group in pairs(DataPool().Groups:Children()) do
        if (group.index >= fromGroup.index and group.index <= toGroup.index) then
            Echo("group " .. group.index)
            local colorSequences = createSeqColorsGroup(pool, group, fromColorPreset, toColorPreset)

            -- Groups in layout
            Cmd("Assign Group " .. group.No .. " At Layout " .. layout.No)
            local layoutChildren = layout:Children()
            local layoutElement = layoutChildren[#layoutChildren]
            layoutElement.posX = 0
            layoutElement.posY = 65486 - i * 70
            layoutElement.width = 50
            layoutElement.height = 50

            for i2, colorSequence in pairs(colorSequences) do
                -- Color in layout
                Cmd("Assign Datapool " .. colorSequence.No .. " At Layout " .. layout.No)
                local layoutChildren = layout:Children()
                local layoutElement = layoutChildren[#layoutChildren]

                layoutElement.posX = 0 + i2 * 60
                layoutElement.posY = 65486 - i * 70
                layoutElement.width = 50
                layoutElement.height = 50
                layoutElement.BORDERSIZE = 0
                layoutElement.VISIBILITYBAR = false
                layoutElement.VISIBILITYOBJECTNAME = false
                layoutElement.VISIBILITYINDICATORBAR = false
                layoutElement.action = OnToken

                -- debuggee.print("log", gma3_helpers:dumpObj(layout:Children()[#layoutChildren]))

            end
            index = index + 1
            SetProgress(groupProgHandle, index)

        end

    end

    StopProgress(groupProgHandle)

    -- Create Macro Change all fixture color
    for icolorPreset, colorPreset in pairs(DataPool().PresetPools[4]:Children()) do
        if (colorPreset.index >= fromColorPreset.index and colorPreset.index <= toColorPreset.index) then
            local macroIndex = 1000 + colorPreset.index
            Cmd("Store DataPool " .. pool.No .. " Macro " .. macroIndex .. " /o")
            local macro = pool.Macros[macroIndex]
            macro.name = "TOGGLE ALL " .. colorPreset.name
            macro.appearance = ObjectList("DataPool " .. pool.No .. " Appearance " .. colorPreset.index * 2 +
                                              appearanceStartIndex)[1]

            -- Macro line by group
            local iMacroLine = 1
            for igroup, group in pairs(DataPool().Groups:Children()) do
                if (group.index >= fromGroup.index and group.index <= toGroup.index) then
                    -- Echo(macro:Dump())
                    Echo("Store DataPool " .. pool.No .. " Macro " .. macroIndex .. "." .. iMacroLine .. " /o")
                    Cmd("Store DataPool " .. pool.No .. " Macro " .. macroIndex .. "." .. iMacroLine .. " /o")
                    local macroLine = macro:Children()[iMacroLine]
                    macroLine.command = "On DataPool " .. pool.No .. " Sequence " ..
                                            presetColorToSequenceColor(colorPreset, group)
                    iMacroLine = iMacroLine + 1
                end
            end

            Cmd("Assign Root " .. macro:Addr() .. " At Layout " .. layout.No)
            local layoutChildren = layout:Children()
            local layoutElement = layoutChildren[#layoutChildren]

            layoutElement.posX = -60 + icolorPreset * 60
            layoutElement.posY = 65486
            layoutElement.width = 50
            layoutElement.height = 50
            layoutElement.BORDERSIZE = 0
            layoutElement.VISIBILITYBAR = false
            layoutElement.VISIBILITYOBJECTNAME = false
            layoutElement.VISIBILITYINDICATORBAR = false

        end

    end

    -- layoutElement.visibiltybar = "Hidden"
    Cmd("Select Layout " .. layoutIndex)

    CloseUndo(colorPickerUndo)
end

-- ██╗   ██╗████████╗██╗██╗     
-- ██║   ██║╚══██╔══╝██║██║     
-- ██║   ██║   ██║   ██║██║     
-- ██║   ██║   ██║   ██║██║     
-- ╚██████╔╝   ██║   ██║███████╗
--  ╚═════╝    ╚═╝   ╚═╝╚══════╝

function createSeqColorsGroup(pool, group, fromColorPreset, toColorPreset)
    local colorPresets = pool.PresetPools[4]:Children()
    Echo(pool.PresetPools[4]:Dump())

    local colorProgHandle = StartProgress("colorProgress")
    local endIdx = 0
    for _ in pairs(colorPresets) do
        endIdx = endIdx + 1
    end
    SetProgressRange(colorProgHandle, 0, endIdx)

    local index = 0
    local colorSequences = {}
    for i, colorPreset in pairs(pool.PresetPools[4]:Children()) do
        if (colorPreset.index >= fromColorPreset.index and colorPreset.index <= toColorPreset.index) then
            table.insert(colorSequences, createSequenceColorRecipe(pool, group, colorPreset))
            index = index + 1
            SetProgress(colorProgHandle, index)

        end

    end

    StopProgress(colorProgHandle)

    return colorSequences
end

function createSequenceColorRecipe(pool, group, colorPreset)

    local outlineImage = ObjectList("Image 3.1")[1]
    local fillImage = ObjectList("Image 3.2")[1]

    local presetIndex = colorPreset.index
    local sequenceIndex = presetColorToSequenceColor(colorPreset, group)
    local appearenceIndex = presetIndex * 2 - 1 + appearanceStartIndex

    -- Create recipe in cue part
    Cmd("Delete DataPool " .. pool.No .. " Sequence " .. sequenceIndex .. " /NoConfirm")
    Echo("Store DataPool " .. pool.No .. " Sequence " .. sequenceIndex .. " Cue 1 Part 0.1 /NoConfirm /Overwrite")
    Cmd("Store DataPool " .. pool.No .. " Sequence " .. sequenceIndex .. " Cue 1 Part 0.1 /NoConfirm /Overwrite")
    local sequence = ObjectList("DataPool " .. pool.No .. " Sequence " .. sequenceIndex)[1]

    -- Outline Appearance
    Cmd("Store DataPool " .. pool.No .. " Appearance " .. appearenceIndex)
    local appearanceOutline = ObjectList("DataPool " .. pool.No .. " Appearance " .. appearenceIndex)[1]
    appearanceOutline.image = outlineImage
    appearanceOutline.name = "<" .. colorPreset.name .. "> Off"

    -- Fill Appearance
    Cmd("Store DataPool " .. pool.No .. " Appearance " .. appearenceIndex + 1)
    local appearanceFill = ObjectList("DataPool " .. pool.No .. " Appearance " .. appearenceIndex + 1)[1]
    appearanceFill.image = fillImage
    appearanceFill.name = "<" .. colorPreset.name .. "> On"

    -- Name to color
    local color = nameToRGB(colorPreset.name)
    if color ~= nil then
        appearanceOutline.imager = color[1]
        appearanceOutline.imageg = color[2]
        appearanceOutline.imageb = color[3]

        appearanceFill.imager = color[1]
        appearanceFill.imageg = color[2]
        appearanceFill.imageb = color[3]
    end

    sequence.appearance = appearanceOutline
    colorPreset.appearance = appearanceFill
    sequence.name = group.name .. " > " .. colorPreset.name
    sequence.prefercueappearance = "Yes"

    local part = ObjectList("Root " .. sequence:AddrNative(nil, true) .. " Cue 1 Part 0")[1]
    part.appearance = appearanceFill

    local recipe = ObjectList("Root " .. sequence:AddrNative(nil, true) .. " Cue 1 Part 0.1")[1]:Children()[1]
    recipe.selection = group
    recipe.values = colorPreset

    Cmd("Cook Root " .. sequence:AddrNative(nil, true) .. " /Overwrite")

    return sequence

    -- debuggee.print("log", gma3_helpers:dumpObj(sequence))

end

function askListObject(objectPool, title, fromId)
    if fromId == nil then
        fromId = 0
    else
        fromId = tonumber(fromId)
    end

    local pool = objectPool:Children()
    local listItem = {}
    local listItemDisplay = {}
    for i, item in pairs(pool) do
        if tonumber(item.index) >= fromId then
            table.insert(listItem, item)
            table.insert(listItemDisplay, item.index .. " " .. item.name)

        end
    end

    local indexList, nameList = PopupInput({
        title = title,
        caller = GetFocusDisplay(),
        items = listItemDisplay
    })

    return listItem[indexList + 1]

end

function presetColorToSequenceColor(preset, group)
    return preset.index + sequenceStartIndex + group.index * 100
end

colorTableConversion = {
    -- white and gray
    ["white"] = {255, 255, 255},
    ["blanc"] = {255, 255, 255},
    ["azure"] = {240, 255, 255},
    ["silver"] = {192, 192, 192},
    ["argent"] = {192, 192, 192},
    ["gray"] = {128, 128, 128},
    ["gris"] = {128, 128, 128},
    ["black"] = {255, 255, 255},
    ["noir"] = {255, 255, 255},
    -- color
    ["red"] = {255, 0, 0},
    ["rouge"] = {255, 0, 0},
    ["darkred"] = {178, 34, 34},
    ["rougefonce"] = {178, 34, 34},
    ["pink"] = {255, 192, 203},
    ["rose"] = {255, 192, 203},
    ["orangered"] = {255, 160, 122},
    ["orangerouge"] = {255, 160, 122},
    ["orange"] = {255, 165, 0},
    ["gold"] = {255, 215, 0},
    ["or"] = {255, 215, 0},
    ["yellow"] = {255, 255, 0},
    ["jaune"] = {255, 255, 0},
    ["lavender"] = {230, 230, 250},
    ["lavande"] = {230, 230, 250},
    ["fuchsia"] = {255, 0, 255},
    ["magenta"] = {255, 0, 255},
    ["blueviolet"] = {102, 51, 226},
    ["bleuviolet"] = {102, 51, 226},
    ["darkviolet"] = {148, 0, 211},
    ["violetfonce"] = {148, 0, 211},
    ["purple"] = {128, 0, 128},
    ["violet"] = {128, 0, 128},
    ["indigo"] = {75, 0, 130},
    ["lime"] = {0, 255, 0},
    ["citron"] = {0, 255, 0},
    ["green"] = {0, 128, 0},
    ["vert"] = {0, 128, 0},
    ["darkcyan"] = {0, 139, 139},
    ["cyanfonce"] = {0, 139, 139},
    ["aqua"] = {0, 255, 255},
    ["cyan"] = {0, 255, 255},
    ["sky"] = {135, 206, 235},
    ["ciel"] = {135, 206, 235},
    ["blue"] = {0, 0, 255},
    ["bleu"] = {0, 0, 255},
    ["darkblue"] = {0, 0, 139},
    ["bleufonce"] = {0, 0, 139},
    ["midnightblue"] = {25, 25, 112},
    ["bleuminuit"] = {25, 25, 112},
    ["beige"] = {255, 222, 196},
    ["bisque"] = {255, 222, 196},
    ["chocolate"] = {210, 105, 30},
    ["chocolat"] = {210, 105, 30},
    ["brown"] = {165, 42, 42},
    ["brun"] = {165, 42, 42},
    ["marron"] = {165, 42, 42},
    ["maroon"] = {128, 0, 0},
    ["bordeaux"] = {128, 0, 0}
}

function nameToRGB(name)
    return colorTableConversion[string.lower(name)]
end

return main
