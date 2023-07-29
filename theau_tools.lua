local function main(displayHandle)

    require("gma3_helpers")

    -- local resIndex, resName = PopupInput({
    --     title = "Tool",
    --     caller = displayHandle,
    --     items = {"Preset Picker Generator", "Color picker generator", "MAtrix picker generator"},
    --     backColor = "Assignment.Plugin"
    -- })

    local toolSelectBox = MessageBox(
        {
            title = 'Theau Tools',
            message = 'Please Select a Tool',
            commands = {{value = 1, name = "Preset Picker Generator"}, {value = 2, name = "Color picker generator"},{value = 3, name = "MAtrix picker generator"}},
            backColor = "Assignment.Plugin",
            timeout = 10000,
            timeoutResultCancel = true,
            icon = "wizard",
        })
    if toolSelectBox.success == false then return end

    if toolSelectBox.result == 3 then
        Cmd("plugin ThéauTools.ColorPickerGenerator")
    elseif toolSelectBox.result == 2 then
        Cmd("plugin ThéauTools.MAtricksPickerGenerator")
    elseif toolSelectBox.result == 1 then
        Cmd("plugin ThéauTools.PresetPickerGenerator")
    end
end

return main
