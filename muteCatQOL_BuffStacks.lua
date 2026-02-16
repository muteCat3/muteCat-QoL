local _G = _G
local pairs = pairs
local ipairs = ipairs

local BUFF_STACK_SIZE = 18
local BUFF_STACK_POINT = "TOP"
local BUFF_STACK_OFFSET_X = 1
local BUFF_STACK_OFFSET_Y = 7
local ICON_CROP = 0.10
local COOLDOWN_SWIPE_TEXTURE = "Interface\\Buttons\\WHITE8x8"

local TRACKED_VIEWER_NAMES = {
	"BuffIconCooldownViewer",
	"BuffBarCooldownViewer",
	"EssentialCooldownViewer",
	"UtilityCooldownViewer",
}

local muteCatBorderFrames = {}
local muteCatBorderBackdrop = {
	edgeFile = "Interface\\Buttons\\WHITE8x8",
	edgeSize = 1,
}

local function IsAddonLoadedSafe(addonName)
	if (C_AddOns ~= nil and C_AddOns.IsAddOnLoaded ~= nil) then
		return C_AddOns.IsAddOnLoaded(addonName)
	end
	if (IsAddOnLoaded ~= nil) then
		return IsAddOnLoaded(addonName)
	end
	return false
end

local function SafeEquals(a, b)
	return a == b
end

local function ScanSlot(slot)
	if (slot.muteCatQOLScanned) then
		return
	end

	slot.muteCatQOLHidden = {}
	slot.muteCatQOLIcon = nil
	slot.muteCatQOLCooldown = nil

	for regionIndex = 1, slot:GetNumRegions() do
		local region = select(regionIndex, slot:GetRegions())
		if (region ~= nil and region.GetObjectType ~= nil) then
			local objectType = region:GetObjectType()
			if (objectType == "MaskTexture") then
				slot.muteCatQOLHidden[#slot.muteCatQOLHidden + 1] = region
			elseif (objectType == "Texture") then
				local okLayer, rawLayer = pcall(region.GetDrawLayer, region)
				if (okLayer and rawLayer ~= nil) then
					local okBorder, isBorder = pcall(SafeEquals, rawLayer, "BORDER")
					local okOverlay, isOverlay = pcall(SafeEquals, rawLayer, "OVERLAY")
					local okArtwork, isArtwork = pcall(SafeEquals, rawLayer, "ARTWORK")
					local okBackground, isBackground = pcall(SafeEquals, rawLayer, "BACKGROUND")

					if ((okBorder and isBorder) or (okOverlay and isOverlay)) then
						slot.muteCatQOLHidden[#slot.muteCatQOLHidden + 1] = region
					elseif (slot.muteCatQOLIcon == nil and ((okArtwork and isArtwork) or (okBackground and isBackground))) then
						slot.muteCatQOLIcon = region
					end
				end
			end
		end
	end

	for childIndex = 1, slot:GetNumChildren() do
		local child = select(childIndex, slot:GetChildren())
		if (child ~= nil and child.GetObjectType ~= nil) then
			local objectType = child:GetObjectType()
			if (objectType == "MaskTexture") then
				slot.muteCatQOLHidden[#slot.muteCatQOLHidden + 1] = child
			elseif (objectType == "Cooldown") then
				slot.muteCatQOLCooldown = child

				for cooldownChildIndex = 1, child:GetNumChildren() do
					local cooldownChild = select(cooldownChildIndex, child:GetChildren())
					if (cooldownChild ~= nil and cooldownChild.GetObjectType ~= nil and cooldownChild:GetObjectType() == "MaskTexture") then
						slot.muteCatQOLHidden[#slot.muteCatQOLHidden + 1] = cooldownChild
					end
				end

				for cooldownRegionIndex = 1, child:GetNumRegions() do
					local cooldownRegion = select(cooldownRegionIndex, child:GetRegions())
					if (cooldownRegion ~= nil and cooldownRegion.GetObjectType ~= nil and cooldownRegion:GetObjectType() == "MaskTexture") then
						slot.muteCatQOLHidden[#slot.muteCatQOLHidden + 1] = cooldownRegion
					end
				end
			end
		end
	end

	slot.muteCatQOLScanned = true
end

local function GetOrCreateSlotBorder(slot)
	if (muteCatBorderFrames[slot] ~= nil) then
		return muteCatBorderFrames[slot]
	end

	ScanSlot(slot)

	local iconSize = (slot.muteCatQOLIcon ~= nil and slot.muteCatQOLIcon.GetWidth ~= nil and slot.muteCatQOLIcon:GetWidth()) or (slot.GetWidth ~= nil and slot:GetWidth()) or 35
	local edgeSize = (iconSize < 35) and 2 or 1

	local border = CreateFrame("Frame", nil, slot, "BackdropTemplate")
	if (slot.muteCatQOLIcon ~= nil) then
		border:SetAllPoints(slot.muteCatQOLIcon)
	else
		border:SetAllPoints()
	end
	border:SetFrameLevel(slot:GetFrameLevel() + 5)

	muteCatBorderBackdrop.edgeSize = edgeSize
	border:SetBackdrop(muteCatBorderBackdrop)
	border:SetBackdropBorderColor(0, 0, 0, 1)

	muteCatBorderFrames[slot] = border
	return border
end

function muteCatQOL:ApplyBuffIconVisualStyle(itemFrame)
	if (itemFrame == nil) then
		return
	end

	local border = GetOrCreateSlotBorder(itemFrame)
	if (border ~= nil) then
		border:Show()
	end

	if (itemFrame.muteCatQOLIcon ~= nil) then
		itemFrame.muteCatQOLIcon:SetTexCoord(ICON_CROP, 1 - ICON_CROP, ICON_CROP, 1 - ICON_CROP)
	end

	if (itemFrame.muteCatQOLCooldown ~= nil and itemFrame.muteCatQOLCooldown.SetSwipeTexture ~= nil) then
		itemFrame.muteCatQOLCooldown:SetSwipeTexture(COOLDOWN_SWIPE_TEXTURE)
		if (itemFrame.muteCatQOLCooldown.SetDrawEdge ~= nil) then
			itemFrame.muteCatQOLCooldown:SetDrawEdge(false)
		end
	end

	for _, hidden in ipairs(itemFrame.muteCatQOLHidden or {}) do
		if (hidden ~= nil and hidden.Hide ~= nil) then
			hidden:Hide()
		end
	end

	if (itemFrame.DebuffBorder ~= nil and itemFrame.DebuffBorder.SetAlpha ~= nil) then
		itemFrame.DebuffBorder:SetAlpha(0)
	end
end

function muteCatQOL:ApplyBuffIconStackStyle(itemFrame)
	if (itemFrame == nil) then
		return
	end

	local stackText = nil
	if (itemFrame.Applications ~= nil and itemFrame.Applications.Applications ~= nil) then
		stackText = itemFrame.Applications.Applications
	elseif (itemFrame.Icon ~= nil and itemFrame.Icon.Applications ~= nil) then
		stackText = itemFrame.Icon.Applications
	end

	if (stackText == nil) then
		return
	end

	if (itemFrame.Applications ~= nil and itemFrame.Applications.SetFrameLevel ~= nil) then
		itemFrame.Applications:SetFrameLevel(itemFrame:GetFrameLevel() + 12)
	end

	local fontPath, _, fontFlags = stackText:GetFont()
	if (fontPath ~= nil) then
		stackText:SetFont(fontPath, BUFF_STACK_SIZE, fontFlags)
	end

	stackText:ClearAllPoints()
	stackText:SetPoint(BUFF_STACK_POINT, itemFrame, BUFF_STACK_POINT, BUFF_STACK_OFFSET_X, BUFF_STACK_OFFSET_Y)
	stackText:SetJustifyH("CENTER")
	stackText:SetJustifyV("TOP")
	stackText:SetTextColor(1, 0, 1, 1)
end

function muteCatQOL:ApplyBuffIconStyleAndStack(itemFrame)
	muteCatQOL:ApplyBuffIconVisualStyle(itemFrame)
	muteCatQOL:ApplyBuffIconStackStyle(itemFrame)

	if (itemFrame ~= nil and itemFrame.muteCatQOLBuffRefreshHooked ~= true and type(itemFrame.RefreshData) == "function") then
		hooksecurefunc(itemFrame, "RefreshData", function(self)
			muteCatQOL:ApplyBuffIconVisualStyle(self)
			muteCatQOL:ApplyBuffIconStackStyle(self)
		end)
		itemFrame.muteCatQOLBuffRefreshHooked = true
	end
end

function muteCatQOL:ApplyAllBuffIconStylesAndStacks(viewer)
	if (viewer == nil) then
		return
	end

	for _, child in pairs({ viewer:GetChildren() }) do
		if (child ~= nil and child.GetWidth ~= nil and child:GetWidth() > 5) then
			muteCatQOL:ApplyBuffIconStyleAndStack(child)
		end
	end
end

local function HookViewer(viewer)
	if (viewer == nil or viewer.muteCatQOLBuffStacksHooked == true) then
		return
	end

	if (type(viewer.OnAcquireItemFrame) == "function") then
		hooksecurefunc(viewer, "OnAcquireItemFrame", function(_, itemFrame)
			muteCatQOL:ApplyBuffIconStyleAndStack(itemFrame)
		end)
	end

	if (type(viewer.RefreshData) == "function") then
		hooksecurefunc(viewer, "RefreshData", function()
			muteCatQOL:ApplyAllBuffIconStylesAndStacks(viewer)
		end)
	end

	if (type(viewer.RefreshLayout) == "function") then
		hooksecurefunc(viewer, "RefreshLayout", function()
			muteCatQOL:ApplyAllBuffIconStylesAndStacks(viewer)
		end)
	end

	viewer:HookScript("OnShow", function()
		muteCatQOL:ApplyAllBuffIconStylesAndStacks(viewer)
	end)

	viewer.muteCatQOLBuffStacksHooked = true
end

function muteCatQOL:InitializeBuffIconStacks()
	if not IsAddonLoadedSafe("Blizzard_CooldownViewer") then
		return
	end

	local hookedAny = false
	for _, viewerName in ipairs(TRACKED_VIEWER_NAMES) do
		local viewer = _G[viewerName]
		if (viewer ~= nil) then
			HookViewer(viewer)
			muteCatQOL:ApplyAllBuffIconStylesAndStacks(viewer)
			hookedAny = true
		end
	end

	if (hookedAny) then
		MUTECATQOL_BUFF_STACKS_HOOKED = true
	end
end
