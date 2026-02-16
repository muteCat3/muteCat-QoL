local _G = _G
local next = next
local floor = math.floor
local format = string.format
local LibStub = LibStub

local UPDATE_INTERVAL = 0.1
local OVERLAY_OFFSET_Y = 10

local function Round(value)
	return floor(value + 0.5)
end

local function GetCenteredCoords(frame)
	if (frame == nil or frame.GetCenter == nil) then
		return 0, 0
	end

	local fx, fy = frame:GetCenter()
	local ux, uy = UIParent:GetCenter()
	if (fx == nil or fy == nil or ux == nil or uy == nil) then
		return 0, 0
	end

	local frameScale = frame:GetEffectiveScale()
	local uiScale = UIParent:GetEffectiveScale()
	if (frameScale == nil or uiScale == nil or uiScale == 0) then
		return 0, 0
	end

	local x = (fx - ux) * frameScale / uiScale
	local y = (fy - uy) * frameScale / uiScale
	return Round(x), Round(y)
end

function muteCatQOL:GetLibEditMode()
	if (muteCatQOL.LibEditMode ~= nil) then
		return muteCatQOL.LibEditMode
	end
	if (type(LibStub) ~= "function") then
		return nil
	end

	local ok, lib = pcall(LibStub, "LibEditMode", true)
	if (ok and lib ~= nil) then
		muteCatQOL.LibEditMode = lib
		return lib
	end
	return nil
end

function muteCatQOL:GetLibEditModeSelectedFrame()
	local lib = muteCatQOL:GetLibEditMode()
	if (lib == nil or type(lib.frameSelections) ~= "table") then
		return nil
	end

	for frame, selection in next, lib.frameSelections do
		if (frame ~= nil and selection ~= nil and selection.isSelected == true) then
			return frame
		end
	end

	return nil
end

function muteCatQOL:GetEditModeCoordsTarget()
	local libTarget = muteCatQOL:GetLibEditModeSelectedFrame()
	if (libTarget ~= nil) then
		muteCatQOL.EditModeCoordsTarget = libTarget
		return libTarget
	end

	return muteCatQOL.EditModeCoordsTarget
end

function muteCatQOL:CreateEditModeCoordsFrame()
	if (muteCatQOL.EditModeCoordsFrame ~= nil) then
		return muteCatQOL.EditModeCoordsFrame
	end

	local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
	frame:SetFrameStrata("FULLSCREEN_DIALOG")
	frame:SetSize(126, 42)
	frame:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 8,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	frame:SetBackdropColor(0, 0, 0, 1)
	frame:Hide()

	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("TOP", frame, "TOP", 0, -2)
	title:SetText("Coordinates")

	local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	text:SetPoint("TOP", title, "BOTTOM", 0, -2)
	text:SetJustifyH("CENTER")
	text:SetText("X: 0\nY: 0")

	frame.title = title
	frame.text = text
	muteCatQOL.EditModeCoordsFrame = frame
	return frame
end

function muteCatQOL:IsEditModeActive()
	local lib = muteCatQOL:GetLibEditMode()
	if (lib ~= nil and type(lib.IsInEditMode) == "function") then
		return lib:IsInEditMode()
	end

	local manager = _G["EditModeManagerFrame"]
	return manager ~= nil and manager.editModeActive == true
end

function muteCatQOL:ResetEditModeCoordsState()
	muteCatQOL.EditModeCoordsTarget = nil
	muteCatQOL.EditModeCoordsLastTarget = nil
	muteCatQOL.EditModeCoordsLastX = nil
	muteCatQOL.EditModeCoordsLastY = nil
end

function muteCatQOL:UpdateEditModeCoords()
	local display = muteCatQOL.EditModeCoordsFrame
	if (display == nil) then
		return
	end

	if (not muteCatQOL:IsEditModeActive()) then
		display:Hide()
		muteCatQOL:ResetEditModeCoordsState()
		return
	end

	local target = muteCatQOL:GetEditModeCoordsTarget()
	if (target == nil or target.GetCenter == nil) then
		display:Hide()
		muteCatQOL:ResetEditModeCoordsState()
		return
	end

	if (target ~= muteCatQOL.EditModeCoordsLastTarget) then
		display:ClearAllPoints()
		display:SetPoint("BOTTOM", target, "TOP", 0, OVERLAY_OFFSET_Y)
		muteCatQOL.EditModeCoordsLastTarget = target
	end

	local x, y = GetCenteredCoords(target)
	if (x ~= muteCatQOL.EditModeCoordsLastX or y ~= muteCatQOL.EditModeCoordsLastY) then
		display.text:SetText(format("X: %d\nY: %d", x, y))
		muteCatQOL.EditModeCoordsLastX = x
		muteCatQOL.EditModeCoordsLastY = y
	end

	if (not display:IsShown()) then
		display:Show()
	end
end

function muteCatQOL:StartEditModeCoordsTicker()
	if (MUTECATQOL_EDITMODE_COORDS_TICKER ~= nil) then
		return
	end
	MUTECATQOL_EDITMODE_COORDS_TICKER = C_Timer.NewTicker(UPDATE_INTERVAL, function()
		muteCatQOL:UpdateEditModeCoords()
	end)
end

function muteCatQOL:HookEditModeCoordsSelection()
	local manager = _G["EditModeManagerFrame"]
	if (manager == nil or MUTECATQOL_EDITMODE_COORDS_HOOKED) then
		return
	end

	hooksecurefunc(manager, "SelectSystem", function(_, systemFrame)
		if (muteCatQOL:GetLibEditModeSelectedFrame() == nil) then
			muteCatQOL.EditModeCoordsTarget = systemFrame
		end
		muteCatQOL:UpdateEditModeCoords()
	end)

	hooksecurefunc(manager, "ClearSelectedSystem", function()
		if (muteCatQOL:GetLibEditModeSelectedFrame() == nil) then
			muteCatQOL:ResetEditModeCoordsState()
			if (muteCatQOL.EditModeCoordsFrame ~= nil) then
				muteCatQOL.EditModeCoordsFrame:Hide()
			end
		end
	end)

	MUTECATQOL_EDITMODE_COORDS_HOOKED = true
end

function muteCatQOL:RegisterLibEditModeCallbacks()
	if (MUTECATQOL_EDITMODE_LIB_CALLBACKS_REGISTERED) then
		return
	end

	local lib = muteCatQOL:GetLibEditMode()
	if (lib == nil or type(lib.RegisterCallback) ~= "function") then
		return
	end

	lib:RegisterCallback("enter", function()
		muteCatQOL:UpdateEditModeCoords()
	end)
	lib:RegisterCallback("layout", function()
		muteCatQOL:UpdateEditModeCoords()
	end)
	lib:RegisterCallback("exit", function()
		muteCatQOL:ResetEditModeCoordsState()
		if (muteCatQOL.EditModeCoordsFrame ~= nil) then
			muteCatQOL.EditModeCoordsFrame:Hide()
		end
	end)

	MUTECATQOL_EDITMODE_LIB_CALLBACKS_REGISTERED = true
end

function muteCatQOL:InitializeEditModeCoords()
	muteCatQOL:CreateEditModeCoordsFrame()
	muteCatQOL:RegisterLibEditModeCallbacks()
	muteCatQOL:HookEditModeCoordsSelection()
	muteCatQOL:StartEditModeCoordsTicker()
	muteCatQOL:UpdateEditModeCoords()
end
