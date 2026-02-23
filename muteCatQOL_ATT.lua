--- @class muteCatQOL
local muteCatQOL = muteCatQOL
local _G = _G
local GetTime = GetTime
local InCombatLockdown = InCombatLockdown

-- Configuration
local ATT_HIDE_DELAY = 2.0
local ATT_FADE_DURATION = 0.3
local ATT_DIM_ALPHA = 0

local attFrames = {}
local cdFrames = {}
local pendingFadeOutAt = nil
local currentATTAlpha = 1

--- Check if the mouse is currently over any tracked ATT frame
local function IsMouseOverATT()
    for frame, _ in pairs(attFrames) do
        if frame:IsVisible() and frame:IsMouseOver() then
            return true
        end
    end
    if _G.ATTWindow and _G.ATTWindow:IsVisible() and _G.ATTWindow:IsMouseOver() then
        return true
    end
    return false
end

--- Locks the frame at its current position
local function LockATTFrame(frame)
    if not frame or frame:IsForbidden() then return end
    if frame.SetMovable then frame:SetMovable(false) end
    if frame.SetResizable then frame:SetResizable(false) end
    
    if frame.TitleBar and frame.TitleBar.SetEnabled then
        frame.TitleBar:SetEnabled(false)
    end
end

--- Scans for frames that belong to AllTheThings or CooldownViewers
local function ScanForManagedFrames()
    local children = { UIParent:GetChildren() }
    for _, child in ipairs(children) do
        if child and not child:IsForbidden() then
            local name = child:GetName()
            local isATT = (name and (name:find("AllTheThings") or name:find("ATT"))) or child.AllTheThings
            local isCD = (name == "EssentialCooldownViewer" or name == "UtilityCooldownViewer" or name == "BuffIconCooldownViewer")

            -- Fallback for AceGUI style windows used by ATT
            if not isATT and not isCD and child.Container and child.Center and not child:GetName() then
                isATT = true
            end

            if isATT then
                if not attFrames[child] then
                    attFrames[child] = true
                    LockATTFrame(child)
                end
            elseif isCD then
                if not cdFrames[child] then
                    cdFrames[child] = true
                end
            end
        end
    end
end

local function SetATTAlpha(alpha)
    if currentATTAlpha == alpha then return end
    currentATTAlpha = alpha
    for frame, _ in pairs(attFrames) do
        frame:SetAlpha(alpha)
    end
    if _G.ATTWindow then _G.ATTWindow:SetAlpha(alpha) end
end

function muteCatQOL:UpdateManagedFrames()
    if not _G.AllTheThings and not _G.EssentialCooldownViewer then return end
    
    -- Periodically scan (every few ticks)
    if (muteCatQOL.Runtime.State.TickCount or 0) % 20 == 0 then
        ScanForManagedFrames()
    end

    -- 1. Update ATT Frames (Mouseover Logic like MultiBarLeft)
    local isMouseOver = IsMouseOverATT()
    
    if isMouseOver then
        pendingFadeOutAt = nil
        SetATTAlpha(1)
    else
        local now = GetTime()
        if not pendingFadeOutAt then
            pendingFadeOutAt = now + ATT_HIDE_DELAY
        end

        if now < pendingFadeOutAt then
            SetATTAlpha(1)
        else
            if currentATTAlpha > ATT_DIM_ALPHA then
                local delta = (1 / ATT_FADE_DURATION) * (muteCatQOL.Constants.UI.FastTickInterval or 0.05)
                SetATTAlpha(math.max(ATT_DIM_ALPHA, currentATTAlpha - delta))
            end
        end
    end

    -- 2. Update CD Viewer Frames (Visibility Rules like MultiBar7)
    local cdHidden = self:ShouldHideByVisibilityRules()
    local cdAlpha = cdHidden and 0 or 1
    for frame, _ in pairs(cdFrames) do
        if frame:GetAlpha() ~= cdAlpha then
            frame:SetAlpha(cdAlpha)
        end
    end
end

function muteCatQOL:InitializeATTMouseover()
    ScanForManagedFrames()
end
