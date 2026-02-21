local _G = _G
local ipairs, pairs = ipairs, pairs
local C_Timer = C_Timer
local C_Container = C_Container
local C_ChallengeMode = C_ChallengeMode
local GetInstanceInfo = GetInstanceInfo
local select = select

muteCatQOL.MicroMenuIdleAlpha = muteCatQOL.Constants.UI.MicroMenuIdleAlpha
muteCatQOL.BuffBarHideDelay = muteCatQOL.Constants.UI.BuffBarHideDelay
muteCatQOL.UITickTime = muteCatQOL.Constants.UI.TickInterval

-- Helper: Get the relevant Micro Menu container for the current UI
function muteCatQOL:GetMicroMenuFrame()
	return _G["MicroMenuContainer"] or _G["MicroButtonAndBagsBar"] or _G["MicroButtonBar"]
end

-- Helper: Fetch all bag/backpack buttons across different UI setups
function muteCatQOL:GetBagButtons()
	local cachedButtons = muteCatQOL.Runtime.Buttons.Bags
	if (cachedButtons ~= nil and #cachedButtons > 0) then
		return cachedButtons
	end
    
    if muteCatQOL.Runtime.State.BagsScannedOnce then return nil end

	local names = {
		"MainMenuBarBackpackButton",
		"CharacterBag0Slot",
		"CharacterBag1Slot",
		"CharacterBag2Slot",
		"CharacterBag3Slot",
		"CharacterReagentBag0Slot",
	}

	local buttons = {}
	for _, name in ipairs(names) do
		local button = _G[name]
		if (button ~= nil) then
			table.insert(buttons, button)
		end
	end

	local bagsBar = _G["BagsBar"]
	if (bagsBar ~= nil) then
		local numChildren = bagsBar:GetNumChildren()
		for i = 1, numChildren do
			local child = select(i, bagsBar:GetChildren())
			if (child ~= nil and child.GetName ~= nil) then
				local childName = child:GetName()
				if (childName ~= nil and (childName:find("Bag") ~= nil or childName:find("Backpack") ~= nil)) then
					table.insert(buttons, child)
				end
			end
		end
	end

	muteCatQOL.Runtime.Buttons.Bags = buttons
    muteCatQOL.Runtime.State.BagsScannedOnce = true
	return buttons
end

-- Check if mouse is currently over a frame or its immediate children (zero-alloc)
function muteCatQOL:IsMouseOverFrameOrChildren(frame)
	if (frame == nil) then return false end
	if (frame.IsMouseOver ~= nil and frame:IsMouseOver()) then
		return true
	end
	if not frame.GetNumChildren then return false end
	local numChildren = frame:GetNumChildren()
	for i = 1, numChildren do
		local child = select(i, frame:GetChildren())
		if (child ~= nil and child.IsMouseOver ~= nil and child:IsMouseOver()) then
			return true
		end
	end
	return false
end

-- Pre-cache buff button references to avoid string concatenation in the ticker
local _buffButtonCache = nil
local function GetBuffButtonCache()
	if _buffButtonCache then return _buffButtonCache end
	_buffButtonCache = {}
	for i = 1, 40 do
		_buffButtonCache[i] = _G["BuffButton"..i]
	end
	return _buffButtonCache
end

-- Specifically check if mouse is over the Buff or TempEnchant frames
function muteCatQOL:IsBuffBarMouseOver()
	local buffFrame = _G["BuffFrame"]
	if (muteCatQOL:IsMouseOverFrameOrChildren(buffFrame)) then
		return true
	end
	local tempEnchantFrame = _G["TemporaryEnchantFrame"]
	if (muteCatQOL:IsMouseOverFrameOrChildren(tempEnchantFrame)) then
		return true
	end
	-- Scan active buff buttons (cached references)
	local buttons = GetBuffButtonCache()
	for i = 1, 40 do
		local buffButton = buttons[i]
		if (buffButton ~= nil and buffButton.IsMouseOver ~= nil and buffButton:IsMouseOver()) then
			return true
		end
	end
	return false
end

-- Aggressively hide the BagsBar and its buttons
function muteCatQOL:ApplyBagsBarHidden()
	local bagsBar = _G["BagsBar"]
	if (bagsBar ~= nil) then
		if (bagsBar:GetAlpha() ~= 0) then bagsBar:SetAlpha(0) end
		if (bagsBar.EnableMouse ~= nil and bagsBar:IsMouseEnabled()) then bagsBar:EnableMouse(false) end
		
		if not(muteCatQOL.Runtime.Hooks.BagsBarFrame) then
			bagsBar:HookScript("OnShow", function(self)
				if (self:GetAlpha() ~= 0) then self:SetAlpha(0) end
				if (self.EnableMouse ~= nil and self:IsMouseEnabled()) then self:EnableMouse(false) end
			end)
			muteCatQOL.Runtime.Hooks.BagsBarFrame = true
		end
	end

	local bagButtons = muteCatQOL:GetBagButtons()
	if (not bagButtons) then return end
	
	for _, button in ipairs(bagButtons) do
		if (button ~= nil) then
			if (button:GetAlpha() ~= 0) then button:SetAlpha(0) end
			if (button.EnableMouse ~= nil and button:IsMouseEnabled()) then button:EnableMouse(false) end
			
			if (muteCatQOL.Runtime.Hooks.BagsBarOnShow == nil) then
				muteCatQOL.Runtime.Hooks.BagsBarOnShow = {}
			end
			if not(muteCatQOL.Runtime.Hooks.BagsBarOnShow[button]) then
				button:HookScript("OnShow", function(self)
					if (self:GetAlpha() ~= 0) then self:SetAlpha(0) end
					if (self.EnableMouse ~= nil and self:IsMouseEnabled()) then self:EnableMouse(false) end
				end)
				muteCatQOL.Runtime.Hooks.BagsBarOnShow[button] = true
			end
		end
	end
end

-- Dynamic Alpha for Micro Menu on Hover
function muteCatQOL:UpdateMicroMenuAlpha()
	local microMenuFrame = muteCatQOL:GetMicroMenuFrame()
	if (microMenuFrame == nil) then return end
	
	local targetAlpha = muteCatQOL:IsMouseOverFrameOrChildren(microMenuFrame) and 1 or (muteCatQOL.MicroMenuIdleAlpha or 0.3)
	if (muteCatQOL.SafeNotEqual(microMenuFrame:GetAlpha(), targetAlpha)) then
		microMenuFrame:SetAlpha(targetAlpha)
	end
end

-- Fade Buff Bar Alpha
function muteCatQOL:SetBuffBarAlpha(alpha)
	local buffFrame = _G["BuffFrame"]
	if (buffFrame ~= nil and muteCatQOL.SafeNotEqual(buffFrame:GetAlpha(), alpha)) then buffFrame:SetAlpha(alpha) end
	local tempEnchantFrame = _G["TemporaryEnchantFrame"]
	if (tempEnchantFrame ~= nil and muteCatQOL.SafeNotEqual(tempEnchantFrame:GetAlpha(), alpha)) then tempEnchantFrame:SetAlpha(alpha) end
end

-- Update Buff Bar Fade State
function muteCatQOL:UpdateBuffBarAlpha()
	local now = GetTime()
	
	if (muteCatQOL:IsBuffBarMouseOver()) then
		muteCatQOL.Runtime.State.BuffBarHideAt = now + (muteCatQOL.BuffBarHideDelay or 1.0)
		muteCatQOL:SetBuffBarAlpha(1)
		return
	end
	
	if (muteCatQOL.Runtime.State.BuffBarHideAt == nil) then
		muteCatQOL.Runtime.State.BuffBarHideAt = now + (muteCatQOL.BuffBarHideDelay or 1.0)
	end
	
	if (now >= muteCatQOL.Runtime.State.BuffBarHideAt) then
		muteCatQOL:SetBuffBarAlpha(0)
	end
end

-- Entry point for UI tick updates
function muteCatQOL:UpdateUIUtilities()
	muteCatQOL:ApplyBagsBarHidden()
	muteCatQOL:UpdateMicroMenuAlpha()
	muteCatQOL:UpdateBuffBarAlpha()
end


function muteCatQOL:InitializeUIUtilities()
	-- Auto-Keystone removed as requested
end