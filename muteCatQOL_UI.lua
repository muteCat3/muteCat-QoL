local _G = _G
local ipairs = ipairs

muteCatQOL.MicroMenuIdleAlpha = 0.3
muteCatQOL.BuffBarHideDelay = 1.0
muteCatQOL.UITickTime = 0.1

function muteCatQOL:GetMicroMenuFrame()
	return _G["MicroMenuContainer"] or _G["MicroButtonAndBagsBar"] or _G["MicroButtonBar"]
end

function muteCatQOL:GetBagButtons()
	local cachedButtons = MUTECATQOL_BAG_BUTTONS
	if (cachedButtons ~= nil and #cachedButtons > 0) then
		return cachedButtons
	end

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
			buttons[#buttons + 1] = button
		end
	end

	local bagsBar = _G["BagsBar"]
	if (bagsBar ~= nil) then
		for _, child in ipairs({ bagsBar:GetChildren() }) do
			if (child ~= nil and child.GetName ~= nil) then
				local childName = child:GetName()
				if (childName ~= nil and (childName:find("Bag") ~= nil or childName:find("Backpack") ~= nil)) then
					buttons[#buttons + 1] = child
				end
			end
		end
	end

	MUTECATQOL_BAG_BUTTONS = buttons
	return buttons
end

function muteCatQOL:IsMouseOverFrameOrChildren(frame)
	if (frame == nil) then
		return false
	end
	if (frame.IsMouseOver ~= nil and frame:IsMouseOver()) then
		return true
	end
	for _, child in ipairs({ frame:GetChildren() }) do
		if (child ~= nil and child.IsMouseOver ~= nil and child:IsMouseOver()) then
			return true
		end
	end
	return false
end

function muteCatQOL:IsBuffBarMouseOver()
	local buffFrame = _G["BuffFrame"]
	if (muteCatQOL:IsMouseOverFrameOrChildren(buffFrame)) then
		return true
	end
	local tempEnchantFrame = _G["TemporaryEnchantFrame"]
	if (muteCatQOL:IsMouseOverFrameOrChildren(tempEnchantFrame)) then
		return true
	end
	return false
end

function muteCatQOL:ApplyBagsBarHidden()
	local bagsBar = _G["BagsBar"]
	if (bagsBar ~= nil) then
		if not(bagsBar.__muteCatQOLHidden) then
			bagsBar:SetAlpha(0)
			bagsBar.__muteCatQOLHidden = true
		end
		if (bagsBar.EnableMouse ~= nil) then
			bagsBar:EnableMouse(false)
		end
		if not(MUTECATQOL_BAGSBAR_FRAME_HOOKED) then
			bagsBar:HookScript("OnShow", function(self)
				self:SetAlpha(0)
				if (self.EnableMouse ~= nil) then
					self:EnableMouse(false)
				end
			end)
			MUTECATQOL_BAGSBAR_FRAME_HOOKED = true
		end
	end

	local bagButtons = muteCatQOL:GetBagButtons()
	if (bagButtons == nil) then
		return
	end
	if (MUTECATQOL_BAGSBAR_ONSHOW_HOOKED == nil) then
		MUTECATQOL_BAGSBAR_ONSHOW_HOOKED = {}
	end
	for _, button in ipairs(bagButtons) do
		if (button ~= nil) then
			if not(button.__muteCatQOLHidden) then
				button:SetAlpha(0)
				button.__muteCatQOLHidden = true
			end
			if (button.EnableMouse ~= nil) then
				button:EnableMouse(false)
			end
			if not(MUTECATQOL_BAGSBAR_ONSHOW_HOOKED[button]) then
				button:HookScript("OnShow", function(self)
					self:SetAlpha(0)
					if (self.EnableMouse ~= nil) then
						self:EnableMouse(false)
					end
				end)
				MUTECATQOL_BAGSBAR_ONSHOW_HOOKED[button] = true
			end
		end
	end
end

function muteCatQOL:UpdateMicroMenuAlpha()
	local microMenuFrame = muteCatQOL:GetMicroMenuFrame()
	if (microMenuFrame == nil) then
		return
	end
	local targetAlpha = muteCatQOL:IsMouseOverFrameOrChildren(microMenuFrame) and 1 or (muteCatQOL.MicroMenuIdleAlpha or 0.3)
	if (microMenuFrame:GetAlpha() ~= targetAlpha) then
		microMenuFrame:SetAlpha(targetAlpha)
	end
end

function muteCatQOL:SetBuffBarAlpha(alpha)
	local buffFrame = _G["BuffFrame"]
	if (buffFrame ~= nil) then
		buffFrame:SetAlpha(alpha)
	end
	local tempEnchantFrame = _G["TemporaryEnchantFrame"]
	if (tempEnchantFrame ~= nil) then
		tempEnchantFrame:SetAlpha(alpha)
	end
end

function muteCatQOL:UpdateBuffBarAlpha()
	local isMouseOver = muteCatQOL:IsBuffBarMouseOver()
	if (isMouseOver) then
		MUTECATQOL_BUFFBAR_HIDE_AT = nil
		muteCatQOL:SetBuffBarAlpha(1)
		return
	end
	local now = GetTime()
	if (MUTECATQOL_BUFFBAR_HIDE_AT == nil) then
		MUTECATQOL_BUFFBAR_HIDE_AT = now + (muteCatQOL.BuffBarHideDelay or 1.0)
	end
	if (now >= MUTECATQOL_BUFFBAR_HIDE_AT) then
		muteCatQOL:SetBuffBarAlpha(0)
	end
end

function muteCatQOL:UpdateUIUtilities()
	muteCatQOL:ApplyBagsBarHidden()
	muteCatQOL:UpdateMicroMenuAlpha()
	muteCatQOL:UpdateBuffBarAlpha()
end

function muteCatQOL:InitializeUIUtilities()
	muteCatQOL:UpdateUIUtilities()
	if (MUTECATQOL_UI_TICKER == nil) then
		MUTECATQOL_UI_TICKER = C_Timer.NewTicker(muteCatQOL.UITickTime or 0.1, function()
			muteCatQOL:UpdateUIUtilities()
		end)
	end
end