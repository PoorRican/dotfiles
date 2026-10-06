-- SUPER+W window controls, kept separate from the main Hyprland config.
-- setup() is safe to call more than once in one Lua state; normal config
-- reloads recreate the Lua state and clear its keybinds before loading again.

local ROOT = "cbox-window-controls"
local MOVE = ROOT .. "-move"
local RESIZE = ROOT .. "-resize"
local GAPS = ROOT .. "-gaps"
local STATE_KEY = "__cboxWindowControlsState"

local state = rawget(_G, STATE_KEY)
if type(state) ~= "table" then
    state = { installed = false, workspaces = {}, selectedGap = "inner" }
    rawset(_G, STATE_KEY, state)
end
state.workspaces = state.workspaces or {}

local actions = state.actions or {}
state.actions = actions
local M = { actions = actions }

local function activeWorkspace()
    return hl.get_active_special_workspace() or hl.get_active_workspace()
end

local function dismissHelp()
    if state.notification then
        state.notification:dismiss()
        state.notification = nil
    end
end

local function showHelp(text)
    dismissHelp()
    -- Pause a finite-duration native Hyprland notification so it remains
    -- visible for the whole submap without taking keyboard focus.
    state.notification = hl.notification.create({
        text = text,
        duration = 60000,
        icon = "info",
        color = state.helpColor,
        font_size = 12,
    })
    state.notification:pause()
end

local ROOT_HELP = [[WINDOW CONTROLS
h/j/k/l  focus left/down/up/right
m        move submenu     r  resize submenu
f        fullscreen       t  toggle floating
y        cycle this workspace's layout
b        toggle this workspace's border
g        inner/outer gap controls
?  passive modal help    /  searchable keybinding list
s  sysadmin --toggle
Escape or any unmapped key exits.]]

local FULL_HELP = [[SUPER+W WINDOW CONTROLS
h / j / k / l    Focus left / down / up / right
m, then h/j/k/l  Move the focused window
r, then h/j/k/l  Resize by 40 px per step
f                Toggle fullscreen
t                Toggle floating
y                Cycle this workspace: dwindle -> master -> scrolling
b                Toggle this workspace's border; restores its prior size
g                Gap controls: i=inner, o=outer, -/= change by 1 px, 0 off/on
s                Run sysadmin --toggle
Shift+/ (?)      Show this help without opening a focus-taking menu
/                Open the searchable list of all keybindings
Escape or any unmapped key exits and clears the help notification.
Direct Super+F and Super+/ fullscreen binds remain available outside this mode.]]

local function currentRootHelp()
    local workspace = activeWorkspace()
    if workspace then
        return ROOT_HELP .. "\nCurrent layout: " .. tostring(workspace.tiled_layout)
    end
    return ROOT_HELP
end

local function gapCopy(value, fallback)
    local function side(name)
        if type(value) == "number" then
            return value
        end
        if type(value) == "table" and type(value[name]) == "number" then
            return value[name]
        end
        return fallback
    end
    return { top = side("top"), right = side("right"), bottom = side("bottom"), left = side("left") }
end

local function copyGap(value)
    return { top = value.top, right = value.right, bottom = value.bottom, left = value.left }
end

local function hasPositiveGap(value)
    return value.top > 0 or value.right > 0 or value.bottom > 0 or value.left > 0
end

local function workspaceState(workspace)
    local key = workspace.config_name
    local saved = state.workspaces[key]
    if saved then
        return saved, key
    end

    -- The current config has only layout overrides on workspaces 1 and 4;
    -- gap and border defaults therefore come from general.* until changed here.
    local inner = gapCopy(hl.get_config("general.gaps_in") or 5)
    local outer = gapCopy(hl.get_config("general.gaps_out") or 20)
    local border = hl.get_config("general.border_size")
    if type(border) ~= "number" then
        border = 3
    end

    saved = {
        inner = { value = inner, restore = copyGap(inner), off = false },
        outer = { value = outer, restore = copyGap(outer), off = false },
        border = { value = border, restore = border, off = false },
    }
    state.workspaces[key] = saved
    return saved, key
end

local function activeWorkspaceState()
    local workspace = activeWorkspace()
    if not workspace then
        return nil
    end
    local saved, key = workspaceState(workspace)
    return workspace, saved, key
end

local function applyGap(workspaceKey, which)
    local saved = state.workspaces[workspaceKey]
    local gap = saved[which]
    local rule = { workspace = workspaceKey }
    rule[which == "inner" and "gaps_in" or "gaps_out"] = gap.off and 0 or gap.value
    hl.workspace_rule(rule)
end

local function gapHelp()
    local workspace, saved = activeWorkspaceState()
    if not workspace then
        showHelp("Gap controls\nNo active workspace. Escape exits; any unmapped key exits.")
        return
    end

    local which = state.selectedGap
    local gap = saved[which]
    local value = gap.off and gap.restore or gap.value
    local status = gap.off and "OFF (saved T/R/B/L " or "ON (T/R/B/L "
    status = status .. string.format("%d/%d/%d/%d)", value.top, value.right, value.bottom, value.left)
    showHelp(string.format(
        "GAP CONTROLS — workspace %s\ni  inner gaps     o  outer gaps\n- / =  decrease/increase by 1 px (clamped at 0)\n0  toggle selected gaps off/on; last values are restored\nSelected: %s %s\nEscape or any unmapped key exits.",
        workspace.config_name, which, status
    ))
end

local function showModeHelp(mode)
    if mode == ROOT then
        showHelp(currentRootHelp())
    elseif mode == MOVE then
        showHelp("MOVE WINDOW\nh/j/k/l  move focused window left/down/up/right\nEscape or any unmapped key exits.")
    elseif mode == RESIZE then
        showHelp("RESIZE WINDOW\nh/j/k/l  resize by 40 px left/down/up/right\nEscape or any unmapped key exits.")
    elseif mode == GAPS then
        gapHelp()
    else
        dismissHelp()
    end
end

function actions.enter()
    hl.dispatch(hl.dsp.submap(ROOT))
    showModeHelp(ROOT)
end

function actions.exit()
    hl.dispatch(hl.dsp.submap("reset"))
    dismissHelp()
end

function actions.enterMove()
    hl.dispatch(hl.dsp.submap(MOVE))
    showModeHelp(MOVE)
end

function actions.enterResize()
    hl.dispatch(hl.dsp.submap(RESIZE))
    showModeHelp(RESIZE)
end

function actions.enterGaps()
    state.selectedGap = "inner"
    hl.dispatch(hl.dsp.submap(GAPS))
    showModeHelp(GAPS)
end

function actions.selectGap(which)
    state.selectedGap = which
    gapHelp()
end

function actions.toggleSysadmin()
    actions.exit()
    hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/sysadmin --toggle")
end

function actions.openKeybindings()
    actions.exit()
    hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/hypr-keybindings-menu")
end

function actions.showFullHelp()
    showHelp(FULL_HELP)
end

function actions.focus(direction)
    hl.dispatch(hl.dsp.focus({ direction = direction }))
end

function actions.move(direction)
    hl.dispatch(hl.dsp.window.move({ direction = direction }))
end

function actions.resize(direction)
    local delta = ({
        left = { x = -40, y = 0 },
        right = { x = 40, y = 0 },
        up = { x = 0, y = -40 },
        down = { x = 0, y = 40 },
    })[direction]
    if delta then
        delta.relative = true
        hl.dispatch(hl.dsp.window.resize(delta))
    end
end

function actions.toggleFullscreen()
    hl.dispatch(hl.dsp.window.fullscreen({ action = "toggle" }))
end

function actions.toggleFloat()
    hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
end

function actions.cycleLayout()
    local workspace = activeWorkspace()
    if not workspace then
        return
    end

    local layouts = { "dwindle", "master", "scrolling" }
    local nextLayout = layouts[1]
    for index, layout in ipairs(layouts) do
        if workspace.tiled_layout == layout then
            nextLayout = layouts[index % #layouts + 1]
            break
        end
    end

    local rule = { workspace = workspace.config_name, layout = nextLayout }
    if nextLayout == "scrolling" then
        rule.layout_opts = { direction = "right" }
    end
    hl.workspace_rule(rule)
    showHelp(currentRootHelp() .. "\nSelected layout: " .. nextLayout)
end

function actions.toggleBorder()
    local workspace, saved, key = activeWorkspaceState()
    if not workspace then
        return
    end

    local border = saved.border
    if border.off then
        border.off = false
        border.value = border.restore
    else
        if border.value > 0 then
            border.restore = border.value
        end
        border.off = true
        border.value = 0
    end
    hl.workspace_rule({ workspace = key, border_size = border.off and 0 or border.value, no_border = false })
    showHelp(currentRootHelp() .. (border.off and "\nBorder: off" or "\nBorder: restored to " .. border.value))
end

function actions.toggleSelectedGap()
    local workspace, saved, key = activeWorkspaceState()
    if not workspace then
        return
    end
    local gap = saved[state.selectedGap]
    if gap.off then
        gap.off = false
        gap.value = copyGap(gap.restore)
    else
        if hasPositiveGap(gap.value) then
            gap.restore = copyGap(gap.value)
        end
        gap.off = true
    end
    applyGap(key, state.selectedGap)
    gapHelp()
end

function actions.adjustSelectedGap(delta)
    local workspace, saved, key = activeWorkspaceState()
    if not workspace then
        return
    end

    local gap = saved[state.selectedGap]
    local target = gap.off and gap.restore or gap.value
    local changed = {}
    for _, side in ipairs({ "top", "right", "bottom", "left" }) do
        changed[side] = math.max(0, target[side] + delta)
    end
    if gap.off then
        gap.restore = changed
    else
        gap.value = changed
        if hasPositiveGap(changed) then
            gap.restore = copyGap(changed)
        end
    end
    applyGap(key, state.selectedGap)
    gapHelp()
end

function M.setup(palette)
    if palette then
        state.helpColor = palette.accent
    end
    -- Bind once. Existing callbacks look up this shared actions table, so
    -- reloading the module updates behavior without removing live keybind
    -- userdata (unsafe in Hyprland 0.56.2).
    if state.installed then
        return M
    end

    local function bind(key, callback, description, options)
        options = options or {}
        options.description = description
        if type(callback) == "string" then
            local action = callback
            callback = function() actions[action]() end
        end
        if key ~= "catchall" and key ~= "SUPER + W" then
            local actionCallback = callback
            callback = function()
                state.handledModalKey = true
                actionCallback()
            end
        end
        hl.bind(key, callback, options)
    end
    local function bindExitKeys()
        bind("Escape", "exit", "Exit window controls and clear help")
        -- Hyprland 0.56.2 queues catchall alongside mapped Lua callbacks.
        -- Register it last and ignore events already handled by this submap.
        bind("catchall", function()
            local handled = state.handledModalKey
            state.handledModalKey = false
            if not handled then
                actions.exit()
            end
        end, "Exit window controls on an unmapped key", { ignore_mods = true })
    end
    local directions = {
        h = "left",
        j = "down",
        k = "up",
        l = "right",
    }

    hl.define_submap(ROOT, function()
        for key, direction in pairs(directions) do
            local keyName, dir = key, direction
            bind(keyName, function() actions.focus(dir) end, "Focus " .. dir .. " window")
        end
        bind("m", "enterMove", "Enter move-window controls")
        bind("r", "enterResize", "Enter resize-window controls")
        bind("f", "toggleFullscreen", "Toggle focused window fullscreen")
        bind("t", "toggleFloat", "Toggle focused window floating")
        bind("y", "cycleLayout", "Cycle this workspace layout")
        bind("b", "toggleBorder", "Toggle this workspace border")
        bind("g", "enterGaps", "Enter this workspace gap controls")
        bind("Shift_L", function() end, "Allow Shift for passive help", { ignore_mods = true })
        bind("Shift_R", function() end, "Allow Shift for passive help", { ignore_mods = true })
        bind("SHIFT + slash", "showFullHelp", "Show passive window-controls help")
        bind("slash", "openKeybindings", "Open searchable keybinding help")
        bind("s", "toggleSysadmin", "Toggle sysadmin terminal")
        bindExitKeys()
    end)

    hl.define_submap(MOVE, function()
        for key, direction in pairs(directions) do
            local keyName, dir = key, direction
            bind(keyName, function() actions.move(dir) end, "Move focused window " .. dir)
        end
        bindExitKeys()
    end)

    hl.define_submap(RESIZE, function()
        for key, direction in pairs(directions) do
            local keyName, dir = key, direction
            bind(keyName, function() actions.resize(dir) end, "Resize focused window " .. dir)
        end
        bindExitKeys()
    end)

    hl.define_submap(GAPS, function()
        bind("i", function() actions.selectGap("inner") end, "Select inner gaps")
        bind("o", function() actions.selectGap("outer") end, "Select outer gaps")
        bind("minus", function() actions.adjustSelectedGap(-1) end, "Decrease selected gaps by 1 px")
        bind("equal", function() actions.adjustSelectedGap(1) end, "Increase selected gaps by 1 px")
        bind("0", "toggleSelectedGap", "Toggle selected gaps off/on")
        bindExitKeys()
    end)

    bind("SUPER + W", "enter", "Enter modal window controls")
    state.installed = true
    return M
end

return M
