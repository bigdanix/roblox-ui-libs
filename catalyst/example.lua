local _Catalyst = loadstring(game:HttpGet("https://raw.githubusercontent.com/bigdanix/roblox-ui-libs/refs/heads/main/catalyst/source"))()

local Window = _Catalyst:Window({
    Title        = "main",
    SubTitle     = "sub",
    Accent       = Color3.fromRGB(255, 42, 74),
    ConfigFolder = "_CatalystConfigs",
    ToggleKey    = Enum.KeyCode.RightAlt,
})

local State = { aimFov = 120, multiplier = 2, ping = 15 }

local Combat = Window:Tab("Combat", "rbxassetid://6034509993")

Combat:Section("Aim Assist")

Combat:Toggle("Enabled", "Master switch for aim assist", false, function(on)
    Window:Notify("Combat", "Aim assist " .. (on and "ON" or "OFF"))
end, "aim_enabled", { Keybind = Enum.KeyCode.V })

Combat:Slider("FOV", "Targeting radius", 0, 500, 120, function(v)
    State.aimFov = v
end, "aim_fov", { Suffix = " px" })

Combat:Slider("Smoothness", "Lower is snappier", 0.1, 5, 1.5, function(v)
    print("smoothness", v)
end, "aim_smooth", { Decimals = 2, Suffix = "x" })

Combat:Slider("Speed Multiplier", "Front suffix example", 1, 10, 2, function(v)
    State.multiplier = v
end, "aim_mult", { Prefix = "x" })

Combat:Dropdown("Target Part", { "Head", "Torso", "HumanoidRootPart", "Random" }, function(v)
    print("part", v)
end, "aim_part", "Head")

Combat:Section("Keybinds")

Combat:Bind("Trigger (press)", Enum.KeyCode.E, function()
    Window:Notify("Bind", "Press fired once")
end, "bind_press", { Mode = "Press" })

Combat:Bind("Hold To Aim", Enum.KeyCode.F, function(held)
    print("holding:", held)
end, "bind_hold", { Mode = "Hold" })

Combat:Bind("Rage Toggle", Enum.KeyCode.R, function(state)
    Window:Notify("Bind", "Toggled to " .. tostring(state))
end, "bind_toggle", { Mode = "Toggle" })

local Visuals = Window:Tab("Visuals", "rbxassetid://6035067832")

Visuals:Section("ESP")
Visuals:Toggle("Box ESP", "Draw boxes around players", false, function(on) end,
    "esp_boxes", { Keybind = Enum.KeyCode.B })
Visuals:Toggle("Name Tags", "Show player names", true, function(on) end, "esp_names")
Visuals:Colorpicker("ESP Color", Color3.fromRGB(255, 0, 0), function(c) end, "esp_color")

Visuals:Section("Performance")
Visuals:Slider("Ping Display", "Network latency", 0, 300, 15, function(v)
    State.ping = v
end, "perf_ping", { Suffix = " ms" })

local Player = Window:Tab("Player", "rbxassetid://6034287594")

Player:Section("Movement")
Player:Slider("Walk Speed", "Humanoid WalkSpeed", 16, 250, 16, function(v)
    local char = game.Players.LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = v end
end, "walk_speed")
Player:Toggle("Infinite Jump", "Jump again while airborne", false, function(on) end,
    "inf_jump", { Keybind = Enum.KeyCode.J })
Player:Label("Drag a side panel by its header to re-dock it. Click a section to collapse it.")

Window:Init()
Window:Notify("_Catalyst GX", "Demo loaded - press Right Alt to hide.", 5)
