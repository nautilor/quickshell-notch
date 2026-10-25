-- Hyprland config for the greetd login screen (Hyprland 0.55+ with Lua config).
-- greetd starts Hyprland with this file; Hyprland starts the greeter and exits when it is done.
hl.config({
    misc = {
        disable_hyprland_logo     = true,
        disable_splash_rendering  = true,
        force_default_wallpaper   = 0,
    },
    animations = { enabled = false },
})

-- every monitor at its preferred mode
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

hl.on("hyprland.start", function()
    hl.exec_cmd("sh -c 'quickshell -p /etc/quickshell-notch/greeter.qml; hyprctl dispatch \"hl.dsp.exit()\"'")
end)
