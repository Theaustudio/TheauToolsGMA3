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

local pickerDataPoolIndexInput = 3
local pickerLayoutIndexInput = 15
local plusAppearance, minusAppearance

local function main()
    require 'gma3_debug'()
    require("gma3_helpers")

    debuggee.print("log", "start")

    -- If return == 2 relauch function else stop the program
    while true do
        local result = matricksPicker()
        if result ~= 2 then
            break
        end
    end

    debuggee.print("log", "done")
end

function matricksPicker()
    -- =============================================================
    -- button icons
    plusAppearance = ObjectList('Appearnace "theau_plus"')[1]
    minusAppearance = ObjectList('Appearance "theau_minus"')[1]

    if plusAppearance == nil then
        local plusSymbol = ObjectList('Image 2."theau_plus"')[1]
        if plusSymbol == nil then return 1 end
        plusAppearance = ShowData().Appearances:Aquire()
        plusAppearance.name = "theau_plus"
        plusAppearance.image = plusSymbol
    end

    if minusAppearance == nil then
        local minusSymbol = ObjectList('Image 2."theau_minus"')[1]
        if minusSymbol == nil then return 1 end
        minusAppearance = ShowData().Appearances:Aquire()
        minusAppearance.name = "theau_minus"
        minusAppearance.image = minusSymbol
    end

    for i = 0, 9 do
        local numberAppearance = ShowData().Appearances:Aquire()
        numberAppearance.name = string.format('theau_%s', i)
        numberAppearance.image = ObjectList(string.format('Image 2."theau_%s"', i))[1]
    end

    if plusAppearance == nil or minusAppearance == nil then
        ErrEcho('Missing Symbols')
        MessageBox({
            title = 'Error',
            message = 'Missing symbols, please import them!',
            icon = 'small_icon_error',
            backColor = "Global.AlertText",
            commands = {{
                value = 1,
                name = "Ok"
            }}
        })
        return 0
    end

    -- =============================================================
    local matricksPickerOptionsBox = MessageBox({
        title = 'MAtrcicks Picker Options',
        backColor = 'PoolWindow.Matricks',
        icon = 'wizard',
        commands = {{
            value = 1,
            name = "Ok"
        }},
        inputs = {{
            name = 'Layout',
            value = pickerLayoutIndexInput,
            maxTextLength = 4,
            vkPlugin = "NumericInput",
            whiteFilter = "0123456789"
        }, {
            name = 'DataPool',
            value = pickerDataPoolIndexInput,
            maxTextLength = 4,
            vkPlugin = "NumericInput",
            whiteFilter = "0123456789"
        }}
    })

    if matricksPickerOptionsBox.success == false then
        ErrEcho('User Aborted')
        return 0
    end

    pickerDataPoolIndexInput = tonumber(matricksPickerOptionsBox.inputs['DataPool'])
    pickerLayoutIndexInput = tonumber(matricksPickerOptionsBox.inputs['Layout'])

    -- If layout exist
    local matricksPickerLayout = DataPool().Layouts[pickerLayoutIndexInput]
    if matricksPickerLayout == nil then
        ErrEcho('Layout null')
        return ErrorMsg('The Layout does not exist!')
    end

    -- =============================================================
    Cmd(string.format('Store DataPool %s', pickerDataPoolIndexInput))
    local matricksPickerDataPool = ObjectList(string.format('DataPool %s', pickerDataPoolIndexInput))[1]

    -- Get or Create the DataPool if doesn't exist
    if matricksPickerDataPool == nil then
        ErrEcho('DataPool null')
        return ErrorMsg('The Datapool cannot be created!')
    end
    matricksPickerDataPool.name = "Theau Picker Pool"
    

    -- =============================================================
    -- Get Layout Elements in Layout
    local matricksPickerLayoutElements = matricksPickerLayout:Children()
    local matricksLayoutElements = {}

    -- Get MAtricks Layout Element
    for i, matricksPickerLayoutElement in pairs(matricksPickerLayoutElements) do
        if matricksPickerLayoutElement.assignType == "MAtricks" then
            table.insert(matricksLayoutElements, matricksPickerLayoutElement)
        end
    end

    if #matricksLayoutElements == 0 then
        return ErrorMsg('The Layout does not contain MAtricks!')
    end

    -- Create the Undo
    local matricksPickerUndo = CreateUndo("generate MAtricks Picker (TheauTools Plugin)")

    -- =============================================================
    -- Loop MAtricks
    for imatricks, matricksLayoutElement in pairs(matricksLayoutElements) do
        local matricks = matricksLayoutElement.object

        local seqsMatricks = {}
        table.insert(seqsMatricks, {
            ['property'] = 'XBlock',
            ['sequence'] = matrickSequenceProp(matricks, 'XBlock', matricksPickerDataPool),
        }
        )
        table.insert(seqsMatricks, {
            ['property'] = 'XGroup',
            ['sequence'] = matrickSequenceProp(matricks, 'XGroup', matricksPickerDataPool),
        })
        table.insert(seqsMatricks, {
            ['property'] = 'XWings',
            ['sequence'] = matrickSequenceProp(matricks, 'XWings', matricksPickerDataPool),
        })

        for iseqMatricks, seqMatricks in pairs(seqsMatricks) do
            local seqMatricksLayoutElementGoto = matricksPickerLayout:Aquire()
            seqMatricksLayoutElementGoto.object = seqMatricks.sequence
            seqMatricksLayoutElementGoto.action = 'Goto'
            seqMatricksLayoutElementGoto.customtexttext = seqMatricks.property

            seqMatricksLayoutElementGoto.posX = matricksLayoutElement.posX + iseqMatricks * (matricksLayoutElement.width + 10)
            seqMatricksLayoutElementGoto.posY = matricksLayoutElement.posY
            seqMatricksLayoutElementGoto.width = matricksLayoutElement.width
            seqMatricksLayoutElementGoto.height = matricksLayoutElement.height
            
            seqMatricksLayoutElementGoto.BORDERSIZE = 0
            seqMatricksLayoutElementGoto.VISIBILITYBAR = false
            seqMatricksLayoutElementGoto.VISIBILITYBORDER = false
            seqMatricksLayoutElementGoto.VISIBILITYOBJECTNAME = false
            seqMatricksLayoutElementGoto.VISIBILITYINDICATORBAR = false


            local seqMatricksLayoutElementPlus = matricksPickerLayout:Aquire()
            seqMatricksLayoutElementPlus.object = seqMatricks.sequence
            seqMatricksLayoutElementPlus.action = 'Go+'
            seqMatricksLayoutElementPlus.appearance = plusAppearance:Addr()

            seqMatricksLayoutElementPlus.posX = matricksLayoutElement.posX + iseqMatricks * (matricksLayoutElement.width + 10)
            seqMatricksLayoutElementPlus.posY = matricksLayoutElement.posY + ( matricksLayoutElement.height + 10)
            seqMatricksLayoutElementPlus.width = matricksLayoutElement.width
            seqMatricksLayoutElementPlus.height = matricksLayoutElement.height

            seqMatricksLayoutElementPlus.BORDERSIZE = 0
            seqMatricksLayoutElementPlus.VISIBILITYBAR = false
            seqMatricksLayoutElementPlus.VISIBILITYBORDER = false
            seqMatricksLayoutElementPlus.VISIBILITYOBJECTNAME = false
            seqMatricksLayoutElementPlus.VISIBILITYINDICATORBAR = false


            local seqMatricksLayoutElementMinus = matricksPickerLayout:Aquire()
            seqMatricksLayoutElementMinus.object = seqMatricks.sequence
            seqMatricksLayoutElementMinus.action = 'Go-'
            seqMatricksLayoutElementMinus.appearance = minusAppearance:Addr()

            seqMatricksLayoutElementMinus.posX = matricksLayoutElement.posX + iseqMatricks * (matricksLayoutElement.width + 10)
            seqMatricksLayoutElementMinus.posY = matricksLayoutElement.posY - ( matricksLayoutElement.height + 10)
            seqMatricksLayoutElementMinus.width = matricksLayoutElement.width
            seqMatricksLayoutElementMinus.height = matricksLayoutElement.height

            seqMatricksLayoutElementMinus.BORDERSIZE = 0
            seqMatricksLayoutElementMinus.VISIBILITYBAR = false
            seqMatricksLayoutElementMinus.VISIBILITYBORDER = false
            seqMatricksLayoutElementMinus.VISIBILITYOBJECTNAME = false
            seqMatricksLayoutElementMinus.VISIBILITYINDICATORBAR = false

        end

    end

end

function matrickSequenceProp(matricks, property, datapool)
    local seqMatricksName = string.format('%s %s', matricks.name, property)
    local seqMatricks = ObjectList(string.format('%s Sequence "%s"', datapool:ToAddr(), seqMatricksName))[1]
    if seqMatricks == nil then
        -- Create the Sequence
        seqMatricks = datapool.Sequences:Aquire(Sequence, matricksPickerUndo)
        seqMatricks.name = seqMatricksName
        seqMatricks.prefercueappearance = true
        seqMatricks.commandenable = true
        seqMatricks.swapprotect = true
        seqMatricks.killprotect = true
        seqMatricks.tracking = false
        seqMatricks.restartmode = "Current Cue"
        seqMatricks.wraparound = false
        seqMatricks.releasefirstcue = false
        -- seqMatricks.appearance = ObjectList('Appearance "theau_0"')[1]


        for i = 0, 9 do
            local seqMatricksCue = seqMatricks:Aquire()
            local seqMatricksPart = seqMatricksCue:Create(1)
            -- local seqMatricksRecipe = seqMatricksPart:Aquire()

            seqMatricksPart.appearance = ObjectList(string.format('Appearance "theau_%s"', i))[1]
            seqMatricksPart.name = string.format('%s %s', property, i)
            seqMatricksPart.command = string.format('Set %s "%s" %s', matricks:Addr(), property, i)
            -- seqMatricksRecipe.matricks = matricks
            -- seqMatricksRecipe.XBlock = i

        end
    end
    return seqMatricks
end

function ErrorMsg(message)
    local errorMsgBox = MessageBox({
        title = 'Error',
        message = message,
        icon = 'small_icon_error',
        backColor = "Global.AlertText",
        commands = {{
            value = 1,
            name = "Retry"
        }, {
            value = 0,
            name = "Abort"
        }}
    })
    if errorMsgBox.success == true and errorMsgBox.result == 1 then
        -- relauch function
        return 2
    end
    return 0
end

function log(msg)
    debuggee.print("log", msg)
end

return main
