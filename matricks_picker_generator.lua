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

    matricksPicker()

    debuggee.print("log", "done")
end

function matricksPicker()
    local matricksPickerOptionsBox = MessageBox({
        title = 'MAtrcicks Picker Options',
        commands = {{
            value = 1,
            name = "Ok"
        }},
        inputs = {{
            name = 'Layout',
            value = "15",
            maxTextLength = 4,
            vkPlugin = "NumericInput",
            whiteFilter = "0123456789"
        },
        {
            name = 'Destination DataPool',
            value = "3",
            maxTextLength = 4,
            vkPlugin = "NumericInput",
            whiteFilter = "0123456789"
        }}
    })

    if matricksPickerOptionsBox.success == false then
        ErrEcho('User Aborted')
        return 0
    end

    

end

return main
