-- ==========================================
-- 1. CONFIGURATION
-- ==========================================
local Config = {
    Enabled = true,
    TeamCheck = false,
    LimitDistance = true,
    MaxDistance = 1000,
    RefreshRate = 360,
    TextCasing = "Capitalized",
    TextSize = 11,

    Names = {
        Enabled = true,
        Color = Color3.fromRGB(255, 255, 255),
        OutlineColor = Color3.fromRGB(0, 0, 0),
    },

    Boxes = {
        Enabled = true,
        Dynamic = true,
        Mode = "Full", -- "Full" or "Corner", Corner looks weird though
        IncludeAccessories = true,
        MiddleColor = Color3.fromRGB(255, 255, 255),
        OutlineColor = Color3.fromRGB(0, 0, 0),

        -- Box Fill
        Fill = {
            Enabled = true,
            Color1 = Color3.fromRGB(255, 255, 200),
            Color2 = Color3.fromRGB(122, 122, 255),
            Transparency = 0.5,
            Rotation = 90,
        },

        -- Box Glow
        Glow = {
            Enabled = true,
            Color1 = Color3.fromRGB(255, 255, 200),
            Color2 = Color3.fromRGB(122, 122, 255),
            Transparency = 0.8,
            Rotation = 90,
        }
    },

    Healthbars = {
        Enabled = true,
        ColorMode = "Regular", -- "Regular" = static 3-color gradient, "Health-Based" = single color shifts
        TopColor = Color3.fromRGB(0, 255, 0),
        MidColor = Color3.fromRGB(255, 255, 0),
        BottomColor = Color3.fromRGB(255, 0, 0),
        OutlineColor = Color3.fromRGB(0, 0, 0),
    },

    Distance = {
        Enabled = true,
        Suffix = " studs",
        DecimalPlaces = 0,
        Color = Color3.fromRGB(255, 255, 255),
        OutlineColor = Color3.fromRGB(0, 0, 0),
    },

    Weapon = {
        Enabled = true,
        Color = Color3.fromRGB(255, 255, 255),
        OutlineColor = Color3.fromRGB(0, 0, 0),
    },

    Flags = {
        Enabled = true,
        Color = Color3.fromRGB(255, 255, 255),
        OutlineColor = Color3.fromRGB(0, 0, 0),
        Movement = { Enabled = true },
        Avatar = { Enabled = true },
    }
}

-- ==========================================
-- 2. LOCALIZED GLOBALS
-- ==========================================
local Vector2_new = Vector2.new
local Vector3_new = Vector3.new
local UDim2_new = UDim2.new
local UDim2_fromOffset = UDim2.fromOffset
local Color3_fromRGB = Color3.fromRGB
local Color3_new = Color3.new
local Font_new = Font.new
local ColorSequence_new = ColorSequence.new
local ColorSequenceKeypoint_new = ColorSequenceKeypoint.new
local task_spawn = task.spawn
local table_insert = table.insert
local table_concat = table.concat
local math_min = math.min
local math_max = math.max
local math_clamp = math.clamp
local math_floor = math.floor
local string_format = string.format
local string_match = string.match
local string_gsub = string.gsub
local string_find = string.find
local ipairs = ipairs
local pairs = pairs
local pcall = pcall
local warn = warn

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local parentGui
if gethui then
    parentGui = gethui()
elseif game:GetService("CoreGui") then
    parentGui = game:GetService("CoreGui")
else
    parentGui = LocalPlayer:WaitForChild("PlayerGui", 5)
end

-- ==========================================
-- 3. MINECRAFTIA FONT LOADER (direct .ttf)
-- ==========================================
local minecraftiaFont = nil
local fontLoaded = false

local function loadMinecraftiaFont()
    local ok, err = pcall(function()
        -- Direct .ttf download — no base64 needed
        if not isfile("Minecraftia_ESP1.ttf") then
            local ttfData = game:HttpGet("https://github.com/sametexe001/luas/raw/refs/heads/main/fonts/MinecraftStandard.ttf")
            writefile("Minecraftia_ESP1.ttf", ttfData)
        end

        if not isfile("Minecraftia_ESP1.json") then
            local descriptor = {
                name = "Minecraftia_ESP1",
                faces = {{
                    name = "Regular",
                    weight = 400,
                    style = "normal",
                    assetId = getcustomasset("Minecraftia_ESP1.ttf")
                }}
            }
            writefile("Minecraftia_ESP1.json", HttpService:JSONEncode(descriptor))
        end

        minecraftiaFont = Font_new(getcustomasset("Minecraftia_ESP1.json"), Enum.FontWeight.Regular)
        fontLoaded = true
    end)
    if not ok then
        warn("[ESP] Minecraftia font failed: " .. tostring(err))
    end
end

-- ==========================================
-- 4. HELPERS
-- ==========================================
local function formatText(str)
    if not str then return "" end
    local c = Config.TextCasing
    if c == "Lowercase" then return string.lower(str)
    elseif c == "Uppercase" then return string.upper(str)
    elseif c == "Capitalized" then
        if #str == 0 then return "" end
        return string.upper(string.sub(str, 1, 1)) .. string.lower(string.sub(str, 2))
    end
    return str
end

local function applyFont(label)
    if fontLoaded and minecraftiaFont then
        label.FontFace = minecraftiaFont
    else
        label.Font = Enum.Font.Code
    end
    label.TextSize = Config.TextSize
    label.TextScaled = false
end

local function calculateBox(character, includeAccessories, isDynamic)
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil end
    local rootPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
    if not onScreen then return nil end

    if isDynamic then
        local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
        local found = false
        for _, part in ipairs(character:GetChildren()) do
            local target
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" and part.Transparency < 1 then
                target = part
            elseif includeAccessories and part:IsA("Accessory") then
                local h = part:FindFirstChild("Handle")
                if h and h:IsA("BasePart") and h.Transparency < 1 then target = h end
            end
            if target then
                found = true
                local sz, cf = target.Size, target.CFrame
                local hx, hy, hz = sz.X/2, sz.Y/2, sz.Z/2
                for _, o in ipairs({
                    Vector3_new(-hx,-hy,-hz), Vector3_new(hx,-hy,-hz),
                    Vector3_new(-hx,hy,-hz),  Vector3_new(hx,hy,-hz),
                    Vector3_new(-hx,-hy,hz),  Vector3_new(hx,-hy,hz),
                    Vector3_new(-hx,hy,hz),   Vector3_new(hx,hy,hz),
                }) do
                    local sp = Camera:WorldToViewportPoint(cf * o)
                    minX = math_min(minX, sp.X); maxX = math_max(maxX, sp.X)
                    minY = math_min(minY, sp.Y); maxY = math_max(maxY, sp.Y)
                end
            end
        end
        if not found then return nil end
        return Vector2_new(minX, minY), Vector2_new(maxX - minX, maxY - minY), true
    else
        local scale = (rootPart.Size.Y * Camera.ViewportSize.Y) / (rootPos.Z * 2)
        local bw, bh = 3.2 * scale, 4.5 * scale
        return Vector2_new(rootPos.X - bw/2, rootPos.Y - bh/2), Vector2_new(bw, bh), true
    end
end

local function getHealthColor(frac)
    if frac >= 0.5 then
        return Config.Healthbars.MidColor:Lerp(Config.Healthbars.TopColor, (frac - 0.5) * 2)
    else
        return Config.Healthbars.BottomColor:Lerp(Config.Healthbars.MidColor, frac * 2)
    end
end

local function makeLabel(parent)
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.BorderSizePixel = 0
    lbl.AutomaticSize = Enum.AutomaticSize.XY
    lbl.Size = UDim2_new(0, 0, 0, 0)
    lbl.Parent = parent
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Color = Color3_new(0, 0, 0)
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
    stroke.LineJoinMode = Enum.LineJoinMode.Miter
    stroke.Parent = lbl
    return lbl, stroke
end

-- ==========================================
-- 5. ESP OBJECT CLASS
-- ==========================================
local ESPObject = {}
ESPObject.__index = ESPObject

function ESPObject.new(player)
    local self = setmetatable({}, ESPObject)
    self.Player = player
    self.Connections = {}
    self.Character = player.Character
    self.CachedParts = {}
    self.LastUpdate = 0
    self:CreateUI()
    table_insert(self.Connections, player.CharacterAdded:Connect(function(char)
        self.Character = char; self:CacheCharacterParts(char)
    end))
    table_insert(self.Connections, player.CharacterRemoving:Connect(function()
        self.Character = nil; self.CachedParts = {}
    end))
    if self.Character then self:CacheCharacterParts(self.Character) end
    return self
end

function ESPObject:CacheCharacterParts(character)
    task_spawn(function()
        local hrp = character:WaitForChild("HumanoidRootPart", 5)
        local hum = character:WaitForChild("Humanoid", 5)
        if self.Character == character then
            self.CachedParts.HumanoidRootPart = hrp
            self.CachedParts.Humanoid = hum
        end
    end)
end

function ESPObject:CreateUI()
    local gui = getgenv().AntigravityESP_ScreenGui

    -- HOLDER: represents inner content area
    self.Holder = Instance.new("Frame")
    self.Holder.BackgroundTransparency = 1
    self.Holder.BorderSizePixel = 0
    self.Holder.Visible = false
    self.Holder.Parent = gui

    -- ====================
    -- BOX: 3 concentric frames
    -- Visual extends 3px beyond holder on each side:
    --   Outer black at (-2,-2) size (+4,+4) with 1px stroke = visual edge at -3
    --   White middle at (-1,-1) size (+2,+2) with 1px stroke
    --   Inner black at (0,0) size (1,1) scale with 1px stroke
    -- ====================
    -- Layer 1: Outer black
    self.BoxOuter = Instance.new("Frame")
    self.BoxOuter.BackgroundTransparency = 1
    self.BoxOuter.BorderSizePixel = 0
    self.BoxOuter.Position = UDim2_new(0, -2, 0, -2)
    self.BoxOuter.Size = UDim2_new(1, 4, 1, 4)
    self.BoxOuter.Parent = self.Holder
    self.BoxOuterStroke = Instance.new("UIStroke")
    self.BoxOuterStroke.Thickness = 1
    self.BoxOuterStroke.LineJoinMode = Enum.LineJoinMode.Miter
    self.BoxOuterStroke.Parent = self.BoxOuter

    -- Layer 2: White middle
    self.BoxMiddle = Instance.new("Frame")
    self.BoxMiddle.BackgroundTransparency = 1
    self.BoxMiddle.BorderSizePixel = 0
    self.BoxMiddle.Position = UDim2_new(0, -1, 0, -1)
    self.BoxMiddle.Size = UDim2_new(1, 2, 1, 2)
    self.BoxMiddle.Parent = self.Holder
    self.BoxMiddleStroke = Instance.new("UIStroke")
    self.BoxMiddleStroke.Thickness = 1
    self.BoxMiddleStroke.LineJoinMode = Enum.LineJoinMode.Miter
    self.BoxMiddleStroke.Parent = self.BoxMiddle

    -- Layer 3: Inner black
    self.BoxInner = Instance.new("Frame")
    self.BoxInner.BackgroundTransparency = 1
    self.BoxInner.BorderSizePixel = 0
    self.BoxInner.Size = UDim2_new(1, 0, 1, 0)
    self.BoxInner.Parent = self.Holder
    self.BoxInnerStroke = Instance.new("UIStroke")
    self.BoxInnerStroke.Thickness = 1
    self.BoxInnerStroke.LineJoinMode = Enum.LineJoinMode.Miter
    self.BoxInnerStroke.Parent = self.BoxInner

    -- Box Fill
    self.BoxFill = Instance.new("Frame")
    self.BoxFill.BorderSizePixel = 0
    self.BoxFill.ZIndex = -1
    self.BoxFill.Size = UDim2_new(1, 0, 1, 0)
    self.BoxFill.Parent = self.Holder
    self.BoxFillGradient = Instance.new("UIGradient")
    self.BoxFillGradient.Parent = self.BoxFill

    -- Box Glow
    self.BoxGlow = Instance.new("ImageLabel")
    self.BoxGlow.BackgroundTransparency = 1
    self.BoxGlow.BorderSizePixel = 0
    self.BoxGlow.Image = "rbxassetid://110204605000367"
    self.BoxGlow.ScaleType = Enum.ScaleType.Slice
    self.BoxGlow.SliceCenter = Rect.new(21, 21, 79, 79)
    self.BoxGlow.Position = UDim2_new(0, -21, 0, -21)
    self.BoxGlow.Size = UDim2_new(1, 42, 1, 42)
    self.BoxGlow.ZIndex = -2
    self.BoxGlow.Parent = self.Holder
    self.BoxGlowGradient = Instance.new("UIGradient")
    self.BoxGlowGradient.Parent = self.BoxGlow

    -- Corner mode container
    self.CornerHolder = Instance.new("Frame")
    self.CornerHolder.BackgroundTransparency = 1
    self.CornerHolder.BorderSizePixel = 0
    self.CornerHolder.Size = UDim2_new(1, 0, 1, 0)
    self.CornerHolder.Visible = false
    self.CornerHolder.Parent = self.Holder
    self.Corners = {}
    for i = 1, 8 do
        local line = Instance.new("Frame")
        line.BorderSizePixel = 0
        line.BackgroundColor3 = Config.Boxes.MiddleColor
        local s = Instance.new("UIStroke")
        s.Thickness = 1; s.Color = Config.Boxes.OutlineColor
        s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
        s.LineJoinMode = Enum.LineJoinMode.Miter
        s.Parent = line; line.Parent = self.CornerHolder
        self.Corners[i] = { Frame = line, Stroke = s }
    end

    -- ====================
    -- HEALTHBAR
    -- Outer black frame (background = black) matches box visual height exactly.
    -- Box visual extends 3px above and 3px below holder, so:
    --   Position Y = -3, Size Y = (1, 6) to cover holder + 6px
    -- Width = 3px (1px border + 1px fill + 1px border)
    -- Gap = 1px from box outer left visual edge (which is at X = -3)
    --   So healthbar right edge = -4, healthbar X = -4 - 3 = -7
    -- ====================
    self.HealthBarOutline = Instance.new("Frame")
    self.HealthBarOutline.BackgroundColor3 = Config.Healthbars.OutlineColor
    self.HealthBarOutline.BorderSizePixel = 0
    self.HealthBarOutline.Position = UDim2_new(0, -7, 0, -3)
    self.HealthBarOutline.Size = UDim2_new(0, 3, 1, 6)
    self.HealthBarOutline.Parent = self.Holder

    -- Fill bar: 1px wide, anchored at bottom, height = health fraction
    self.HealthBarFill = Instance.new("Frame")
    self.HealthBarFill.BorderSizePixel = 0
    self.HealthBarFill.BackgroundColor3 = Color3_new(1, 1, 1) -- tinted by gradient
    self.HealthBarFill.AnchorPoint = Vector2_new(0, 1)
    self.HealthBarFill.Position = UDim2_new(0, 1, 1, -1) -- 1px inset from left and bottom
    self.HealthBarFill.Size = UDim2_new(0, 1, 1, -2) -- full minus 2px borders
    self.HealthBarFill.Parent = self.HealthBarOutline

    -- UIGradient on fill for 3-color healthbar (green top → yellow mid → red bottom)
    self.HealthBarGradient = Instance.new("UIGradient")
    self.HealthBarGradient.Rotation = 90
    self.HealthBarGradient.Color = ColorSequence_new({
        ColorSequenceKeypoint_new(0, Config.Healthbars.TopColor),
        ColorSequenceKeypoint_new(0.5, Config.Healthbars.MidColor),
        ColorSequenceKeypoint_new(1, Config.Healthbars.BottomColor),
    })
    self.HealthBarGradient.Parent = self.HealthBarFill

    -- ====================
    -- TOP CONTAINER — name centered above box
    -- ====================
    self.TopContainer = Instance.new("Frame")
    self.TopContainer.BackgroundTransparency = 1
    self.TopContainer.BorderSizePixel = 0
    self.TopContainer.Position = UDim2_new(0.5, 0, 0, -5)
    self.TopContainer.AnchorPoint = Vector2_new(0.5, 1)
    self.TopContainer.AutomaticSize = Enum.AutomaticSize.XY
    self.TopContainer.Size = UDim2_new(0, 0, 0, 0)
    self.TopContainer.Parent = self.Holder
    Instance.new("UIListLayout", self.TopContainer).HorizontalAlignment = Enum.HorizontalAlignment.Center

    self.NameLabel, self.NameStroke = makeLabel(self.TopContainer)

    -- ====================
    -- BOTTOM CONTAINER — distance + weapon centered below box
    -- ====================
    self.BottomContainer = Instance.new("Frame")
    self.BottomContainer.BackgroundTransparency = 1
    self.BottomContainer.BorderSizePixel = 0
    self.BottomContainer.Position = UDim2_new(0.5, 0, 1, 5)
    self.BottomContainer.AnchorPoint = Vector2_new(0.5, 0)
    self.BottomContainer.AutomaticSize = Enum.AutomaticSize.XY
    self.BottomContainer.Size = UDim2_new(0, 0, 0, 0)
    self.BottomContainer.Parent = self.Holder
    local bl = Instance.new("UIListLayout")
    bl.HorizontalAlignment = Enum.HorizontalAlignment.Center
    bl.Parent = self.BottomContainer

    self.DistanceLabel, self.DistanceStroke = makeLabel(self.BottomContainer)
    self.WeaponLabel, self.WeaponStroke = makeLabel(self.BottomContainer)

    -- ====================
    -- RIGHT CONTAINER — flags top-right, top aligned with box top
    -- Offset Y = -3 to align with box visual top edge
    -- ====================
    self.RightContainer = Instance.new("Frame")
    self.RightContainer.BackgroundTransparency = 1
    self.RightContainer.BorderSizePixel = 0
    self.RightContainer.Position = UDim2_new(1, 5, 0, -4)
    self.RightContainer.AnchorPoint = Vector2_new(0, 0)
    self.RightContainer.AutomaticSize = Enum.AutomaticSize.XY
    self.RightContainer.Size = UDim2_new(0, 0, 0, 0)
    self.RightContainer.Parent = self.Holder
    local rl = Instance.new("UIListLayout")
    rl.HorizontalAlignment = Enum.HorizontalAlignment.Left
    rl.Parent = self.RightContainer

    self.FlagsLabel, self.FlagsStroke = makeLabel(self.RightContainer)
    self.FlagsLabel.RichText = true
    self.FlagsLabel.LineHeight = 0.8
    self.FlagsLabel.TextXAlignment = Enum.TextXAlignment.Left
end

function ESPObject:Update(camera, localPlayer)
    if not Config.Enabled or not self.Player or not self.Character then
        self.Holder.Visible = false; return
    end
    if self.Player == localPlayer then
        self.Holder.Visible = false; return
    end
    if Config.TeamCheck and self.Player.Team == localPlayer.Team then
        self.Holder.Visible = false; return
    end

    local rootPart = self.CachedParts.HumanoidRootPart
    local humanoid = self.CachedParts.Humanoid
    if not rootPart or not humanoid or humanoid.Health <= 0 then
        self.Holder.Visible = false; return
    end

    local now = os.clock()
    if (now - self.LastUpdate) < (1 / Config.RefreshRate) then return end
    self.LastUpdate = now

    local localHrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
    local dist = localHrp and (localHrp.Position - rootPart.Position).Magnitude
        or (camera.CFrame.Position - rootPart.Position).Magnitude

    if Config.LimitDistance and dist > Config.MaxDistance then
        self.Holder.Visible = false; return
    end

    local screenPos, size, onScreen = calculateBox(self.Character, Config.Boxes.IncludeAccessories, Config.Boxes.Dynamic)
    if not onScreen or not screenPos then
        self.Holder.Visible = false; return
    end

    local x, y = math_floor(screenPos.X), math_floor(screenPos.Y)
    local w, h = math_floor(size.X), math_floor(size.Y)
    self.Holder.Position = UDim2_fromOffset(x, y)
    self.Holder.Size = UDim2_fromOffset(w, h)
    self.Holder.Visible = true

    -- BOX
    if Config.Boxes.Enabled then
        if Config.Boxes.Mode == "Full" then
            self.BoxOuter.Visible = true
            self.BoxMiddle.Visible = true
            self.BoxInner.Visible = true
            self.CornerHolder.Visible = false
            self.BoxOuterStroke.Color = Config.Boxes.OutlineColor
            self.BoxMiddleStroke.Color = Config.Boxes.MiddleColor
            self.BoxInnerStroke.Color = Config.Boxes.OutlineColor
        else
            self.BoxOuter.Visible = false
            self.BoxMiddle.Visible = false
            self.BoxInner.Visible = false
            self.CornerHolder.Visible = true
            local cl = math_clamp(math_floor(math_min(w, h) * 0.2), 6, 15)
            self.Corners[1].Frame.Size = UDim2_fromOffset(cl, 1)
            self.Corners[1].Frame.Position = UDim2_fromOffset(0, 0)
            self.Corners[2].Frame.Size = UDim2_fromOffset(1, cl)
            self.Corners[2].Frame.Position = UDim2_fromOffset(0, 0)
            self.Corners[3].Frame.Size = UDim2_fromOffset(cl, 1)
            self.Corners[3].Frame.Position = UDim2_fromOffset(w - cl, 0)
            self.Corners[4].Frame.Size = UDim2_fromOffset(1, cl)
            self.Corners[4].Frame.Position = UDim2_fromOffset(w - 1, 0)
            self.Corners[5].Frame.Size = UDim2_fromOffset(cl, 1)
            self.Corners[5].Frame.Position = UDim2_fromOffset(0, h - 1)
            self.Corners[6].Frame.Size = UDim2_fromOffset(1, cl)
            self.Corners[6].Frame.Position = UDim2_fromOffset(0, h - cl)
            self.Corners[7].Frame.Size = UDim2_fromOffset(cl, 1)
            self.Corners[7].Frame.Position = UDim2_fromOffset(w - cl, h - 1)
            self.Corners[8].Frame.Size = UDim2_fromOffset(1, cl)
            self.Corners[8].Frame.Position = UDim2_fromOffset(w - 1, h - cl)
            for _, item in ipairs(self.Corners) do
                item.Stroke.Color = Config.Boxes.OutlineColor
                item.Frame.BackgroundColor3 = Config.Boxes.MiddleColor
            end
        end

        -- Box Fill & Glow
        if Config.Boxes.Fill.Enabled and Config.Boxes.Mode == "Full" then
            self.BoxFill.Visible = true
            self.BoxFill.BackgroundTransparency = Config.Boxes.Fill.Transparency
            self.BoxFillGradient.Rotation = math_clamp(Config.Boxes.Fill.Rotation, 0, 90)
            self.BoxFillGradient.Color = ColorSequence_new({
                ColorSequenceKeypoint_new(0, Config.Boxes.Fill.Color1),
                ColorSequenceKeypoint_new(1, Config.Boxes.Fill.Color2),
            })
        else
            self.BoxFill.Visible = false
        end

        if Config.Boxes.Glow.Enabled then
            self.BoxGlow.Visible = true
            self.BoxGlow.ImageTransparency = Config.Boxes.Glow.Transparency
            self.BoxGlowGradient.Rotation = math_clamp(Config.Boxes.Glow.Rotation, 0, 90)
            self.BoxGlowGradient.Color = ColorSequence_new({
                ColorSequenceKeypoint_new(0, Config.Boxes.Glow.Color1),
                ColorSequenceKeypoint_new(1, Config.Boxes.Glow.Color2),
            })
        else
            self.BoxGlow.Visible = false
        end
    else
        self.BoxOuter.Visible = false
        self.BoxMiddle.Visible = false
        self.BoxInner.Visible = false
        self.CornerHolder.Visible = false
        self.BoxFill.Visible = false
        self.BoxGlow.Visible = false
    end

    -- HEALTHBAR
    if Config.Healthbars.Enabled then
        self.HealthBarOutline.Visible = true
        local frac = math_clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
        -- Fill height = fraction of outline interior
        self.HealthBarFill.Size = UDim2_new(0, 1, frac, -2)

        if Config.Healthbars.ColorMode == "Health-Based" then
            -- Single solid color shifting with HP
            self.HealthBarGradient.Enabled = false
            self.HealthBarFill.BackgroundColor3 = getHealthColor(frac)
        else
            -- Static 3-color gradient (green top → yellow mid → red bottom)
            self.HealthBarGradient.Enabled = true
            self.HealthBarFill.BackgroundColor3 = Color3_new(1, 1, 1)
            self.HealthBarGradient.Color = ColorSequence_new({
                ColorSequenceKeypoint_new(0, Config.Healthbars.TopColor),
                ColorSequenceKeypoint_new(0.5, Config.Healthbars.MidColor),
                ColorSequenceKeypoint_new(1, Config.Healthbars.BottomColor),
            })
        end
    else
        self.HealthBarOutline.Visible = false
    end

    -- NAME (white text, black outline)
    if Config.Names.Enabled then
        self.NameLabel.Visible = true
        self.NameLabel.Text = formatText(self.Player.Name)
        self.NameLabel.TextColor3 = Config.Names.Color
        self.NameStroke.Color = Config.Names.OutlineColor
        applyFont(self.NameLabel)
    else
        self.NameLabel.Visible = false
    end

    -- DISTANCE
    if Config.Distance.Enabled then
        self.DistanceLabel.Visible = true
        local fmt = "%." .. Config.Distance.DecimalPlaces .. "f"
        self.DistanceLabel.Text = formatText(string_format(fmt, dist) .. Config.Distance.Suffix)
        self.DistanceLabel.TextColor3 = Config.Distance.Color
        self.DistanceStroke.Color = Config.Distance.OutlineColor
        applyFont(self.DistanceLabel)
    else
        self.DistanceLabel.Visible = false
    end

    -- WEAPON
    if Config.Weapon.Enabled then
        self.WeaponLabel.Visible = true
        local tool = self.Character:FindFirstChildWhichIsA("Tool")
        self.WeaponLabel.Text = formatText(tool and tool.Name or "None")
        self.WeaponLabel.TextColor3 = Config.Weapon.Color
        self.WeaponStroke.Color = Config.Weapon.OutlineColor
        applyFont(self.WeaponLabel)
    else
        self.WeaponLabel.Visible = false
    end

    -- FLAGS (top-right, vertical, white text)
    if Config.Flags.Enabled then
        self.FlagsLabel.Visible = true
        local flags = {}
        if Config.Flags.Movement.Enabled then
            local moving = humanoid.MoveDirection.Magnitude > 0.05
            local jumping = humanoid.FloorMaterial == Enum.Material.Air and rootPart.AssemblyLinearVelocity.Y > 0.5
            table_insert(flags, formatText(moving and "moving" or (jumping and "jumping" or "idle")))
        end
        if Config.Flags.Avatar.Enabled then
            local isR6 = humanoid.RigType == Enum.HumanoidRigType.R6
            table_insert(flags, formatText(isR6 and "R6" or "R15"))
        end
        self.FlagsLabel.Text = table_concat(flags, "\n")
        self.FlagsLabel.TextColor3 = Config.Flags.Color
        self.FlagsStroke.Color = Config.Flags.OutlineColor
        applyFont(self.FlagsLabel)
    else
        self.FlagsLabel.Visible = false
    end
end

function ESPObject:Destroy()
    for _, c in ipairs(self.Connections) do c:Disconnect() end
    self.Connections = {}; self.CachedParts = {}
    if self.Holder then self.Holder:Destroy(); self.Holder = nil end
end

-- ==========================================
-- 6. MAIN LIFECYCLE
-- ==========================================
local oldGui = parentGui:FindFirstChild("AntigravityESP")
if oldGui then oldGui:Destroy() end
if getgenv().AntigravityESP_Connection then
    getgenv().AntigravityESP_Connection:Disconnect()
    getgenv().AntigravityESP_Connection = nil
end
if getgenv().AntigravityESP_Objects then
    for _, esp in pairs(getgenv().AntigravityESP_Objects) do esp:Destroy() end
    getgenv().AntigravityESP_Objects = nil
end

getgenv().AntigravityESP_ScreenGui = Instance.new("ScreenGui")
getgenv().AntigravityESP_ScreenGui.Name = "AntigravityESP"
getgenv().AntigravityESP_ScreenGui.IgnoreGuiInset = true
getgenv().AntigravityESP_ScreenGui.DisplayOrder = 999
getgenv().AntigravityESP_ScreenGui.Parent = parentGui
getgenv().AntigravityESP_Objects = {}

loadMinecraftiaFont()

local function addPlayer(p)
    if p == LocalPlayer then return end
    getgenv().AntigravityESP_Objects[p] = ESPObject.new(p)
end
local function removePlayer(p)
    local esp = getgenv().AntigravityESP_Objects[p]
    if esp then esp:Destroy(); getgenv().AntigravityESP_Objects[p] = nil end
end

for _, p in ipairs(Players:GetPlayers()) do addPlayer(p) end
local joinCon = Players.PlayerAdded:Connect(addPlayer)
local leaveCon = Players.PlayerRemoving:Connect(removePlayer)
local loopCon = RunService.Heartbeat:Connect(function()
    Camera = Workspace.CurrentCamera
    if not Camera then return end
    for _, esp in pairs(getgenv().AntigravityESP_Objects) do
        esp:Update(Camera, LocalPlayer)
    end
end)

getgenv().AntigravityESP_Connection = {
    Disconnect = function()
        joinCon:Disconnect(); leaveCon:Disconnect(); loopCon:Disconnect()
    end
}

return Config
