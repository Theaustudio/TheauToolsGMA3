--  Preset Picker by Theaustudio
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
local outlineImage, fillImage, presetGeneratorProgressBar

local function main()
    require 'gma3_debug'()
    require("gma3_helpers")
    require("gma3_objects")
    debuggee.print("log", "start")

    -- If return == 2 relauch function else stop the program
    while true do
        local result = presetPicker()
        if result ~= 2 then
            break
        end
    end
    StopProgress(presetGeneratorProgressBar)

    debuggee.print("log", "done")
end

-- Preset Picker Generator function
function presetPicker()
    Cmd("ClearAll")

    -- =============================================================
    -- button icons
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

    -- =============================================================
    -- Preset Picker modal options
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
        }, {
            name = 'Layout',
            value = "20",
            maxTextLength = 4,
            vkPlugin = "NumericInput",
            whiteFilter = "0123456789"
        }},
        states = {{
            name = "ALL Macro",
            state = true
        }}
    })

    if presetPickerOptionsBox.success == false then
        ErrEcho('User Aborted')
        return 0
    end
    
    -- If layout exist
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
            }, {
                value = 0,
                name = "Abort"
            }}
        })
        if presetPickerLayoutNilBox.success == true and presetPickerLayoutNilBox.result == 1 then
            -- relauch function
            return 2
        end
        return 0
    end

    -- Options
    local allMacroOption = presetPickerOptionsBox.states['ALL Macro']
    local presetPickerDataPoolIndex = tonumber(presetPickerOptionsBox.inputs['DataPool'])

    Cmd(string.format('Store DataPool %s', presetPickerDataPoolIndex))
    local presetPickerDataPool = ObjectList('DataPool 3')[1]
    -- local presetPickerDataPool = ShowData().DataPools:Create(presetPickerDataPoolIndex)

    -- =============================================================
    -- Get or Create the DataPool if doesn't exist
    if presetPickerDataPool == nil then
        ErrEcho('DataPool null')
        local presetPickerDataPoolNilBox = MessageBox({
            title = 'Error',
            message = 'The Datapool cannot be created!',
            backColor = "Global.AlertText",
            commands = {{
                value = 1,
                name = "Retry"
            }, {
                value = 0,
                name = "Abort"
            }}
        })
        if presetPickerDataPoolNilBox.success == true and presetPickerDataPoolNilBox.result == 1 then
            return 2
        end
        return 0
    end
    presetPickerDataPool.name = "Theau Picker Pool"

    -- =============================================================
    -- Get Layout Elements in Layout
    local presetPickerLayoutElements = presetPickerLayout:Children()
    local presetLayoutElements = {}
    local groupLayoutElements = {}

    -- Get Group and Preset Layout Element
    for i, presetPickerLayoutElement in pairs(presetPickerLayoutElements) do
        if presetPickerLayoutElement.assignType == "Preset" then
            -- debuggee.print("log", 'Preset ' .. presetPickerLayoutElement.name)
            table.insert(presetLayoutElements, presetPickerLayoutElement)
        elseif presetPickerLayoutElement.assignType == "Group" then
            -- debuggee.print("log", 'group ' .. presetPickerLayoutElement.name)
            table.insert(groupLayoutElements, presetPickerLayoutElement)
        end
    end

    -- =============================================================
    -- Progress Bar
    presetGeneratorProgressBar = StartProgress('PresetGeneratorTheauTools')
    local presetGenProgressBarEndRange = #groupLayoutElements + 1
    SetProgressRange(presetGeneratorProgressBar, 1, presetGenProgressBarEndRange)
    SetProgressText(presetGeneratorProgressBar, 'Preset Generator TheauTools')
    SetProgress(presetGeneratorProgressBar, 0)

    -- Create the Undo
    local presetPickerUndo = CreateUndo("generate Preset Picker (TheauTools Plugin)")

    -- =============================================================
    -- Loop Groups
    for igroup, groupLayoutElement in pairs(groupLayoutElements) do
        local group = groupLayoutElement.object
        SetProgressText(presetGeneratorProgressBar,
            string.format('Preset Generator TheauTools (Group %s/%s)', igroup, #groupLayoutElements))
        SetProgress(presetGeneratorProgressBar, igroup)

        -- =============================================================
        -- Get or Create MAtricks for each group
        local groupMatricks =
            ObjectList(string.format('%s MAtricks "%s"', presetPickerDataPool:ToAddr(), group.name))[1]
        if groupMatricks == nil then
            groupMatricks = presetPickerDataPool.MAtricks:Aquire(MAtricks, presetPickerUndo)
            if groupMatricks == nil then
                ErrEcho('groupMatricks nil')
                return
            end
            groupMatricks.name = group.name
        end

        -- =============================================================
        -- Loop Presets
        for ipreset, presetLayoutElement in pairs(presetLayoutElements) do

            SetProgressText(presetGeneratorProgressBar,
                string.format('Preset Generator TheauTools (Group %s/%s | Preset %s/%s)', igroup, #groupLayoutElements,
                    ipreset, #presetLayoutElements))

            local preset = presetLayoutElement.object

            -- =============================================================
            -- Get or Create the Sequence with the recipe
            local sequencePreset = ObjectList(string.format('%s Sequence "%s"', presetPickerDataPool:ToAddr(),
                string.format('%s > %s', group.name, preset.name)))[1]
            if sequencePreset == nil then
                -- Create the Sequence
                sequencePreset = presetPickerDataPool.Sequences:Aquire(Sequence, presetPickerUndo)

                if sequencePreset == nil then
                    ErrEcho('sequencePreset null')
                    break
                end
                -- Cue 3
                local sequencePresetCue = sequencePreset:Aquire(Cue, presetPickerUndo)
                -- Part 0
                local sequencePresetCuePart = sequencePresetCue:Create(1, Part, presetPickerUndo)
                -- Recipe 1
                local sequencePresetRecipe = sequencePresetCuePart:Aquire(Recipe, presetPickerUndo)

                sequencePreset.name = string.format('%s > %s', group.name, preset.name)
                sequencePreset.prefercueappearance = "Yes"
                sequencePresetRecipe.selection = group
                sequencePresetRecipe.values = preset
                sequencePresetRecipe.matricks = groupMatricks

                -- Get the Appearance to assign to the Cue and to the Sequence
                local presetOnAppearance, presetOffAppearance = presetToAppearance(preset, presetPickerUndo)

                if presetOffAppearance and presetOnAppearance then
                    sequencePreset.appearance = presetOffAppearance
                    sequencePresetCuePart.appearance = presetOnAppearance
                else
                    -- Apply the preset appearance if cannot create the appearance
                    sequencePreset.appearance = preset.appearance
                end

            end

            -- =============================================================
            -- Store PresetSequence at Layout
            local sequenceLayoutElement = presetPickerLayout[sequencePreset.name]
            if sequenceLayoutElement == nil then
                sequenceLayoutElement = presetPickerLayout:Aquire(Layout, presetPickerUndo)
            end
            if sequenceLayoutElement == nil then
                ErrEcho('SequenceLayoutElement null')
                break
            end

            sequenceLayoutElement.object = sequencePreset
            sequenceLayoutElement.posX = presetLayoutElement.posX
            sequenceLayoutElement.posY = groupLayoutElement.posY
            sequenceLayoutElement.width = presetLayoutElement.width
            sequenceLayoutElement.height = groupLayoutElement.height
            sequenceLayoutElement.BORDERSIZE = 0
            sequenceLayoutElement.VISIBILITYBAR = false
            sequenceLayoutElement.VISIBILITYOBJECTNAME = false
            sequenceLayoutElement.VISIBILITYINDICATORBAR = false
            sequenceLayoutElement.action = OnToken

            -- =============================================================
            -- ALL Macro
            if allMacroOption then
                local allMacroName = string.format('%s ALL %s', presetPickerLayout.index, preset.name)

                -- Get or Create the ALL Macro
                local allMacro =
                    ObjectList(string.format('%s Macro "%s"', presetPickerDataPool:ToAddr(), allMacroName))[1]
                if allMacro == nil then
                    allMacro = presetPickerDataPool.Macros:Aquire(Macro, presetPickerUndo)
                    allMacro.name = allMacroName
                    allMacro.appearance = ObjectList(string.format('Appearance "%s"',
                        presetToAppearanceNameState(preset, 'On')))[1]

                    local allMacroLayoutElement = presetPickerLayout:Aquire(LayoutElement, presetPickerUndo)
                    if allMacroLayoutElement == nil then
                        ErrEcho('allMacroLayoutElement null')
                    else
                        allMacroLayoutElement.object = allMacro
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
                local allMacroLine = allMacro[1]
                if allMacroLine == nil then
                    -- Create the Macro Line
                    allMacroLine = allMacro:Aquire(MacroLine, presetPickerUndo)
                    allMacroLine.command = string.format("On %s", sequencePreset:ToAddr())
                else
                    -- Add the sequence to the Macro Line
                    allMacroLine.command = string.format("%s + %s", allMacroLine.command, sequencePreset:ToAddr())
                end
            end
        end
    end

    -- =============================================================
    -- Cook all Sequences in the DataPool
    SetProgressText(presetGeneratorProgressBar, 'Preset Generator TheauTools (Cooking...)')
    Cmd(string.format('Cook %s Sequence 1 thru /Overwrite', presetPickerDataPool:ToAddr()))

    SetProgressText(presetGeneratorProgressBar, 'Preset Generator TheauTools')
    SetProgress(presetGeneratorProgressBar, presetGenProgressBarEndRange)

    -- =============================================================
    -- Select the targeted Layout
    Cmd(string.format('Select Layout %s', presetPickerLayout.index))

    -- =============================================================
    StopProgress(presetGeneratorProgressBar)
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
    Printf('Preset Picker Generator completed!')

    -- End of Undo
    CloseUndo(presetPickerUndo)

    -- return success
    return 1
end

-- ██╗   ██╗████████╗██╗██╗     
-- ██║   ██║╚══██╔══╝██║██║     
-- ██║   ██║   ██║   ██║██║     
-- ██║   ██║   ██║   ██║██║     
-- ╚██████╔╝   ██║   ██║███████╗
--  ╚═════╝    ╚═╝   ╚═╝╚══════╝

-- Create the appearance with the preset
-- presetToAppearance(preset: handle, presetPickerUndo: undo): {handle | nil, handle | nil} | nil
function presetToAppearance(preset, presetPickerUndo)

    local presetType = presetToType(preset)
    if preset.appearance then
        if ShowData().Appearances[preset.appearance.index + 1] then
            return preset.appearance, ShowData().Appearances[preset.appearance.index + 1]
        end
    end

    local searchAppearanceOn =
        ObjectList(string.format('Appearance "%s"', presetToAppearanceNameState(preset, 'On')))[1]
    local searchAppearanceOff =
        ObjectList(string.format('Appearance "%s"', presetToAppearanceNameState(preset, 'Off')))[1]
    if searchAppearanceOn ~= nil and searchAppearanceOff ~= nil then
        return searchAppearanceOn, searchAppearanceOff
    end

    if presetType == "Color" then
        return presetNameToAppearance(preset, presetPickerUndo)
    end
end

-- Return the type of Preset
-- presetToType(preset: handle): string
function presetToType(preset)
    local presetPool = preset:Parent()
    if presetPool.name then
        return presetPool.name
    end
end

-- Generate the Appearance name with the Preset name and state
-- presetToAppearanceNameState(preset: handle, state: string): string
function presetToAppearanceNameState(preset, state)
    return string.format("<%s> %s", preset.name, state)
end

-- Create the appearance by guessing the color with the Preset name
-- presetNameToAppearance(preset: handle, presetPickerUndo: undo): {handle | nil, handle | nil}
function presetNameToAppearance(preset, presetPickerUndo)
    local color = colorTableConversion[string.lower(preset.name)]
    if color == nil then
        color = colorTableConversion["white"]
    end
    -- Outline Appearance
    local outlineName = presetToAppearanceNameState(preset, "Off")
    local appearanceOutline = ShowData().Appearances:Aquire(Appearance, presetPickerUndo)
    appearanceOutline.name = outlineName
    appearanceOutline.image = outlineImage
    appearanceOutline.name = outlineName

    -- Fill Appearance
    local fillName = presetToAppearanceNameState(preset, "On")
    local appearanceFill = ShowData().Appearances:Aquire(Appearance, presetPickerUndo)
    appearanceFill.name = fillName
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
    ["ambre"] = {255, 184, 2},
    ["amber"] = {255, 184, 2},
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
    ["laser"] = {24, 255, 0},
    ["darkcyan"] = {0, 139, 139},
    ["cyanfonce"] = {0, 139, 139},
    ["aqua"] = {0, 255, 255},
    ["cyan"] = {0, 255, 255},
    ["seagreen"] = {0, 255, 127},
    ["vertmer"] = {0, 255, 127},
    ["vertocean"] = {0, 255, 127},
    ["lightblue"] = {130, 240, 255},
    ["bleuclair"] = {130, 240, 255},
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
    ["bordeaux"] = {128, 0, 0},
    -- filters
    ["ctb"] = {195, 225, 250},
    ["201"] = {195, 225, 250},
    ["l201"] = {195, 225, 250},
    ["cto"] = {250, 195, 135},
    ["206"] = {250, 195, 135},
    ["l206"] = {250, 195, 135}
}

function nameToRGB(name)
    return colorTableConversion[string.match(string.lower(name), "^%s*(.-)%s*$")]
end

return main
