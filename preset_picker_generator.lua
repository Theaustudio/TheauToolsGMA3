--  __   __        __   __      __     __        ___  __      __         ___       ___            __  ___       __     __  
-- /  ` /  \ |    /  \ |__)    |__) | /  ` |__/ |__  |__)    |__) \ /     |  |__| |__   /\  |  | /__`  |  |  | |  \ | /  \ 
-- \__, \__/ |___ \__/ |  \    |    | \__, |  \ |___ |  \    |__)  |      |  |  | |___ /~~\ \__/ .__/  |  \__/ |__/ | \__/ 
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
    require("gma3_objects")
    debuggee.print("log", "start")

    while true do
        local result = presetPicker()
        if result ~= 2 then break end 
    end

    debuggee.print("log", "done")
end

local outlineImage, fillImage

function importAssets()
    -- GetPathOverrideFor("plugins", "")

end

function presetPicker()
    local presetPickerUndo = CreateUndo("generate Preset Picker")
    Cmd("ClearAll")

    --  New layout "select group"
    -- select group 
    --  New layout "select preset"
    -- select preset

    -- create layout
    -- Cmd('Store Layout 3 "' .. colorPickerLayoutName .. '" /o')

    outlineImage = ObjectList('Image 2."theau_square_outline"')[1]
    fillImage = ObjectList('Image 2."theau_square_fill"')[1]

    if outlineImage == nil or fillImage == nil then
        ErrEcho('Missing Symbols')
        MessageBox({
            title = 'Error',
            message = 'Missing symbols, please import them!',
            backColor = "Global.AlertText",
            commands = {{
                value = 1,
                name = "Ok"
            }}
        })
        return 0
    end

    local presetPickerOptionsBox = MessageBox({
        title = 'Preset Picker Options',
        commands = {{
            value = 1,
            name = "Ok"
        }},
        inputs = {{
            name = 'DataPool',
            value = "3",
            maxTextLength = 4,
            vkPlugin = "NumericInput",
            whiteFilter = "0123456789"
        },
        {
            name = 'Layout',
            value = "20",
            maxTextLength = 4,
            vkPlugin = "NumericInput",
            whiteFilter = "0123456789"
        }},
        states = {
            {name = "ALL Macro", state = true},
        }
    })

    if presetPickerOptionsBox.success == false then
        ErrEcho('User Aborted')
        return 0
    end

    local presetPickerLayout = DataPool().Layouts[tonumber(presetPickerOptionsBox.inputs['Layout'])]
    if presetPickerLayout == nil then
        ErrEcho('Layout null')
        local presetPickerLayoutNilBox = MessageBox({
            title = 'Error',
            message = 'The Layout does not exist!',
            backColor = "Global.AlertText",
            commands = {{
                value = 1,
                name = "Retry"
            },{
                value = 0,
                name = "Abort"
            }}
        })
        if presetPickerLayoutNilBox.success == true and presetPickerLayoutNilBox.result == 1 then
            return 2
        end
        return 0
    end

    local allMacroOption = presetPickerOptionsBox.states['ALL Macro']
    local presetPickerDataPoolIndex = tonumber(presetPickerOptionsBox.inputs['DataPool'])

    

    local presetPickerLayoutElements = presetPickerLayout:Children()

    Cmd(string.format('Store DataPool %s "Preset Picker"', presetPickerDataPoolIndex))
    local presetPickerDataPool = ObjectList('DataPool 3')[1]

    if presetPickerDataPool == nil then
        ErrEcho('DataPool null')
        local presetPickerDataPoolNilBox = MessageBox({
            title = 'Error',
            message = 'The Datapool cannot be created!',
            backColor = "Global.AlertText",
            commands = {{
                value = 1,
                name = "Retry"
            },{
                value = 0,
                name = "Abort"
            }}
        })
        if presetPickerLayoutNilBox.success == true and presetPickerLayoutNilBox.result == 1 then
            return 2
        end
        return 0
    end

    local presetLayoutElements = {}
    local groupLayoutElements = {}

    for i, presetPickerLayoutElement in pairs(presetPickerLayoutElements) do
        if presetPickerLayoutElement.assignType == "Preset" then
            debuggee.print("log", 'Preset ' .. presetPickerLayoutElement.name)
            table.insert(presetLayoutElements, presetPickerLayoutElement)
        elseif presetPickerLayoutElement.assignType == "Group" then
            debuggee.print("log", 'group ' .. presetPickerLayoutElement.name)
            table.insert(groupLayoutElements, presetPickerLayoutElement)
        end
    end

    debuggee.print("log", 'presetLayoutElements')
    debuggee.print("log", gma3_helpers:dump(presetLayoutElements))
    debuggee.print("log", 'groupLayoutElements')
    debuggee.print("log", gma3_helpers:dump(groupLayoutElements))

    -- progress bar "step"
    -- progress bar "step" macro
    -- progress bar "macro"
    -- for preset in presets
    -- macro
    -- store macro
    -- assign macro at layout
    -- progressbar macro +1

    -- progress bar "step" group
    -- progressbar "group"
    -- for group in groups

    local sequenceIndex = 1

    for igroup, groupLayoutElement in pairs(groupLayoutElements) do
        local group = groupLayoutElement.object

        -- progressbar "preset"

        local groupMatricks =
            ObjectList(string.format('%s MAtricks "%s"', presetPickerDataPool:ToAddr(), group.name))[1]
        if groupMatricks == nil then
            Cmd(string.format('Store %s MAtricks "%s" /Overwrite', presetPickerDataPool:ToAddr(), group.name))
            groupMatricks = ObjectList(string.format('%s MAtricks "%s"', presetPickerDataPool:ToAddr(), group.name))[1]
        end

        for ipreset, presetLayoutElement in pairs(presetLayoutElements) do
            local preset = presetLayoutElement.object
            -- local sequencePreset = gma3_objects:create(presetPickerDataPool.Sequences, sequenceIndex)
            -- if sequencePreset == nil then
            --     ErrEcho('sequencePreset null')
            --     break
            -- end

            -- -- Cue 1 (index 3)
            -- local sequencePresetCue = (sequencePreset[3] and sequencePreset[3] or sequencePreset:Append())
            -- -- Part 0
            -- local sequencePresetPart = (sequencePresetCue[1] and sequencePresetCue[1] or sequencePresetCue:Append())
            -- -- Recipe Line 1
            -- local sequencePresetRecipe = (sequencePresetPart[1] and sequencePresetPart[1] or sequencePresetPart:Append())

            local preset = presetLayoutElement.object
            Cmd(string.format('Store %s Sequence %s Cue 1 Part 0.1 /NoConfirm /Overwrite',
                presetPickerDataPool:ToAddr(), sequenceIndex))
            local sequencePreset = ObjectList(string.format('DataPool %s Sequence %s', presetPickerDataPool.No,
                sequenceIndex))[1]
            if sequencePreset == nil then
                ErrEcho('sequencePreset null')
                break
            end
            local sequencePresetCue = sequencePreset[3]
            local sequencePresetCuePart = sequencePresetCue[1]
            local sequencePresetRecipe = sequencePresetCuePart[1]

            -- Appearance

            local presetOnAppearance, presetOffAppearance = presetToAppearance(preset)

            if presetOffAppearance and presetOnAppearance then
                sequencePreset.appearance = presetOffAppearance
                sequencePresetCuePart.appearance = presetOnAppearance
            else
                sequencePreset.appearance = preset.appearance
            end

            sequencePreset.name = string.format('%s > %s', group.name, preset.name)
            sequencePreset.prefercueappearance = "Yes"
            sequencePresetRecipe.selection = group
            sequencePresetRecipe.values = preset
            sequencePresetRecipe.matricks = groupMatricks

            -- Store PresetSequence at Layout
            Cmd(string.format('Assign %s At %s', sequencePreset:ToAddr(), presetPickerLayout:ToAddr()))

            local sequenceLayoutElement = presetPickerLayout:Children()[#presetPickerLayout:Children()]
            if sequenceLayoutElement == nil then
                ErrEcho('SequenceLayoutElement null')
                break
            end

            sequenceLayoutElement.posX = presetLayoutElement.posX
            sequenceLayoutElement.posY = groupLayoutElement.posY
            sequenceLayoutElement.width = presetLayoutElement.width
            sequenceLayoutElement.height = groupLayoutElement.height
            sequenceLayoutElement.BORDERSIZE = 0
            sequenceLayoutElement.VISIBILITYBAR = false
            sequenceLayoutElement.VISIBILITYOBJECTNAME = false
            sequenceLayoutElement.VISIBILITYINDICATORBAR = false
            sequenceLayoutElement.action = OnToken

            -- ALL Macro
            if allMacroOption then
                local allMacroName = string.format('ALL %s', preset.name)

                local allMacro = ObjectList(string.format('%s Macro "%s"', presetPickerDataPool:ToAddr(), allMacroName))[1]
                if allMacro == nil then
                    Cmd(string.format('Store %s Macro "%s" /Overwrite', presetPickerDataPool:ToAddr(), allMacroName))
                    allMacro = ObjectList(string.format('%s Macro "%s"', presetPickerDataPool:ToAddr(), allMacroName))[1]
                    allMacro.appearance = ObjectList(string.format('Appearance "%s"', presetToAppearanceNameState(preset, 'On')))[1]

                    Cmd(string.format('Assign %s At %s', allMacro:ToAddr(), presetPickerLayout:ToAddr()))
                    local allMacroLayoutElement = presetPickerLayout:Children()[#presetPickerLayout:Children()]
                    if allMacroLayoutElement == nil then
                        ErrEcho('allMacroLayoutElement null')
                    else
                        allMacroLayoutElement.posX = presetLayoutElement.posX
                        allMacroLayoutElement.posY = presetLayoutElement.posY + presetLayoutElement.height
                        allMacroLayoutElement.width = presetLayoutElement.width
                        allMacroLayoutElement.height = presetLayoutElement.height
                        allMacroLayoutElement.BORDERSIZE = 0
                        allMacroLayoutElement.VISIBILITYBAR = false
                        allMacroLayoutElement.VISIBILITYOBJECTNAME = true
                        allMacroLayoutElement.VISIBILITYINDICATORBAR = false
                    end
                end

                Cmd(string.format('Cd %s', allMacro:ToAddr()))
                Cmd('insert "%s" Property Command "On %s"', group.name, sequencePreset:ToAddr())
                Cmd('cd Root')
            end

            -- progressbar preset +1
            sequenceIndex = sequenceIndex + 1
        end

        -- store macro preset line indexGroup with "on ${sequence}"

        -- progressbar group +1
    end

    Cmd(string.format('Cook %s Sequence 1 thru /Overwrite', presetPickerDataPool:ToAddr()))

    Cmd(string.format('Select Layout %s', presetPickerLayout.index))

    MessageBox({
        title = 'Preset Picker Generator',
        message = 'Completed!',
        backColor = "Global.SuccessText",
        timeout = 1000,
        commands = {{
            value = 1,
            name = "Ok"
        }}
    })

    CloseUndo(presetPickerUndo)

    return 1
end

-- ██╗   ██╗████████╗██╗██╗     
-- ██║   ██║╚══██╔══╝██║██║     
-- ██║   ██║   ██║   ██║██║     
-- ██║   ██║   ██║   ██║██║     
-- ╚██████╔╝   ██║   ██║███████╗
--  ╚═════╝    ╚═╝   ╚═╝╚══════╝

function presetToAppearance(preset)

    local presetType = presetToType(preset)
    if preset.appearance then
        if ShowData().Appearances[preset.appearance.index + 1] then
            return preset.appearance, ShowData().Appearances[preset.appearance.index + 1]
        end
    end
    if presetType == "Color" then
        return presetNameToAppearance(preset)
    end
end

function presetToType(preset)
    local presetPool = preset:Parent()
    if presetPool.name then
        return presetPool.name
    end
end

function presetToAppearanceNameState(preset, state)
    return string.format("<%s> %s", preset.name, state)
end

function presetNameToAppearance(preset)
    local color = colorTableConversion[string.lower(preset.name)]
    if color == nil then
        color = colorTableConversion["white"]
    end
    -- Outline Appearance
    local outlineName = presetToAppearanceNameState(preset, "Off")
    Cmd(string.format('Store Appearance "%s" /Overwrite', outlineName))
    local appearanceOutline = ObjectList(string.format('Appearance "%s"', outlineName))[1]
    appearanceOutline.image = outlineImage
    appearanceOutline.name = outlineName

    -- Fill Appearance
    local fillName = presetToAppearanceNameState(preset, "On")
    Cmd(string.format('Store Appearance "%s" /Overwrite', fillName))
    local appearanceFill = ObjectList(string.format('Appearance "%s"', fillName))[1]
    appearanceFill.image = fillImage
    appearanceFill.name = fillName

    appearanceOutline.imager = color[1]
    appearanceOutline.imageg = color[2]
    appearanceOutline.imageb = color[3]

    appearanceFill.imager = color[1]
    appearanceFill.imageg = color[2]
    appearanceFill.imageb = color[3]

    return appearanceFill, appearanceOutline

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
