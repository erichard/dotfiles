-- Monitor wiki https://wiki.hypr.land/Configuring/Basics/Monitors/
-- Example: output can be found with hyprctl monitors. Edit variables.lua for the monitor outputs instead of here directly
-- hl.monitor({
--     output    = "MONITOR1",
--     mode      = "1920x1080@60",
--     position  = "0x0",
--     scale     = "1",
-- })

hl.monitor({
    output    = MONITOR1,
    mode      = "preferred",
    position  = "auto",
    scale     = "1.25",
})

hl.monitor({
    output    = "DP-4",
    mode      = "preferred",
    position  = "auto",
    scale     = "1.50",
})

-- Un seul écran à la fois : l'externe dès qu'il est branché, le portable sinon.
-- Le déclencheur est le branchement, pas le capot — docké, l'écran interne reste
-- éteint capot ouvert ; nomade, c'est logind qui suspend à la fermeture.

local INTERNAL = "eDP-1"

local function apply_exclusive()
    local externals = 0
    local internal_on = false

    for _, monitor in ipairs(hl.get_monitors()) do
        if monitor.name == INTERNAL then
            internal_on = true
        elseif not monitor.name:match("^HEADLESS") and not monitor.name:match("^FALLBACK") then
            externals = externals + 1
        end
    end

    local want_on = 0 == externals
    if want_on == internal_on then
        return
    end

    hl.monitor({
        output   = INTERNAL,
        disabled = not want_on,
        mode     = "preferred",
        position = "auto",
        scale    = "1.25",
    })
end

local function schedule()
    hl.timer(apply_exclusive, { timeout = 500, type = "oneshot" })
end

hl.on("monitor.added",   schedule)
hl.on("monitor.removed", schedule)
hl.on("hyprland.start",  schedule)

apply_exclusive()
