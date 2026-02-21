local _G = _G
local type, pairs, ipairs = type, pairs, ipairs
local GetActionInfo = GetActionInfo
local GetPetActionInfo = GetPetActionInfo
local GetPetActionSlotUsable = GetPetActionSlotUsable
local GetPetActionCooldown = GetPetActionCooldown

-- Blizzard API Locals for performance
local C_ActionBar_IsUsableAction = C_ActionBar.IsUsableAction
local C_ActionBar_GetActionCooldown = C_ActionBar.GetActionCooldown
local C_ActionBar_GetActionCooldownDuration = C_ActionBar.GetActionCooldownDuration
local C_Item_GetItemCooldown = C_Item.GetItemCooldown
local C_Spell_IsSpellUsable = C_Spell.IsSpellUsable
local C_Spell_GetSpellCooldown = C_Spell.GetSpellCooldown
local C_Spell_GetSpellCooldownDuration = C_Spell.GetSpellCooldownDuration

local function IsActiveCategoryGCD(activeCategory)
	if type(activeCategory) ~= "number" then return false end
	-- Midnight 12.0.1: Compare via pcall to catch secret number errors.
	return muteCatQOL.SafeEqual(activeCategory, 2316)
end

function muteCatQOL.SafeGreater(val, threshold)
	if type(val) ~= "number" then return false end
	local res = false
	pcall(function() res = (val > threshold) end)
	return res
end

function muteCatQOL.SafeEqual(val1, val2)
	local res = false
	pcall(function() res = (val1 == val2) end)
	return res
end

function muteCatQOL.SafeNotEqual(val1, val2)
	local res = false
	pcall(function() res = (val1 ~= val2) end)
	return res
end


local function IsBar4ButtonName(buttonName)
	return buttonName ~= nil and buttonName:find("^MultiBarRightButton") ~= nil
end
local function IsNoTooltipBarButtonName(buttonName)
	return buttonName ~= nil and (
		buttonName:find("^MultiBarRightButton") ~= nil or
		buttonName:find("^MultiBar7Button") ~= nil or
		buttonName:find("^MultiBarLeftButton") ~= nil
	)
end
local function IsBottomRightStackBarName(buttonName)
	return buttonName ~= nil and (
		buttonName:find("^MultiBar7Button") ~= nil or
		buttonName:find("^MultiBar6Button") ~= nil
	)
end


local function IsBar5ButtonName(buttonName)
	return buttonName ~= nil and buttonName:find("^MultiBar5Button") ~= nil
end

muteCatQOL.ActionBarPrefixes = muteCatQOL.Constants.Assets.Prefixes

function muteCatQOL:UpdateAllActionButtons()
	for _, prefix in ipairs(muteCatQOL.ActionBarPrefixes) do
		for i = 1, muteCatQOL.NUM_ACTIONBAR_BUTTONS do
			local actionButton = _G[prefix..i]
			if (actionButton and actionButton.GOCUpdateCheck) then
				actionButton:GOCUpdateCheck()
			end
		end
	end
	for i = 1, 40 do
		local actionButton = _G["SpellFlyoutPopupButton"..i]
		if (actionButton and actionButton.GOCUpdateCheck) then
			actionButton:GOCUpdateCheck()
		end
	end
	for i = 1, muteCatQOL.NUM_PET_ACTION_SLOTS do
		local actionButton = _G["PetActionButton"..i]
		if (actionButton and actionButton.GOCUpdateCheck) then
			actionButton:GOCUpdateCheck()
		end
	end
end

-- Function to update the RegisteredActionSpells table (ActionButtons)
muteCatQOL.UpdateActionButtonAction = function(button)
	local action = button.action
	if (action) then
		local actionInfoType, actionInfoID, actionInfoSubType = GetActionInfo(action)
		if (actionInfoType == "spell" or actionInfoSubType == "spell" or actionInfoSubType == "pet") then
			if (actionInfoID ~= button._actionSpellId) then
				if (button._actionSpellId and muteCatQOL.RegisteredActionSpells[button._actionSpellId]) then
					muteCatQOL.RegisteredActionSpells[button._actionSpellId][button] = nil
				end
				if (muteCatQOL.RegisteredActionSpells[actionInfoID] == nil) then
					muteCatQOL.RegisteredActionSpells[actionInfoID] = { }
				end
				muteCatQOL.RegisteredActionSpells[actionInfoID][button] = true
				button._actionSpellId = actionInfoID
			end
		else
			if (button._actionSpellId and muteCatQOL.RegisteredActionSpells[button._actionSpellId]) then
				muteCatQOL.RegisteredActionSpells[button._actionSpellId][button] = nil
			end
			button._actionSpellId = nil
		end
	else
		if (button._actionSpellId and muteCatQOL.RegisteredActionSpells[button._actionSpellId]) then
			muteCatQOL.RegisteredActionSpells[button._actionSpellId][button] = nil
		end
		button._actionSpellId = nil
	end
	if (button.GOCUpdateCheck) then
		button:GOCUpdateCheck()
	end
end

-- Function to update the RegisteredActionSpells table (PetActionButtons)
muteCatQOL.UpdatePetActionButtonAction = function(button)
	local index = button.index or button.id
	if (index) then
		local _, _, _, _, _, _, spellID = GetPetActionInfo(index)
		if (spellID ~= nil) then
			if (spellID ~= button._actionSpellId) then
				if (button._actionSpellId and muteCatQOL.RegisteredActionSpells[button._actionSpellId]) then
					muteCatQOL.RegisteredActionSpells[button._actionSpellId][button] = nil
				end
				if (muteCatQOL.RegisteredActionSpells[spellID] == nil) then
					muteCatQOL.RegisteredActionSpells[spellID] = { }
				end
				muteCatQOL.RegisteredActionSpells[spellID][button] = true
				button._actionSpellId = spellID
			end
		else
			if (button._actionSpellId and muteCatQOL.RegisteredActionSpells[button._actionSpellId]) then
				muteCatQOL.RegisteredActionSpells[button._actionSpellId][button] = nil
			end
			button._actionSpellId = nil
		end
	else
		if (button._actionSpellId and muteCatQOL.RegisteredActionSpells[button._actionSpellId]) then
			muteCatQOL.RegisteredActionSpells[button._actionSpellId][button] = nil
		end
		button._actionSpellId = nil
	end
	if (button.GOCUpdateCheck) then
		button:GOCUpdateCheck()
	end
end

-- Main GOC ActionButton Update function to desaturate the entire action icon when the spell is on cooldown or unusable
muteCatQOL.GOCActionButtonUpdateCheck = function(self, isOnGCD)
	if not(self.icon) then return end
	local duration
	local useGCDCurve = false
	local action = self.action
	local spellID = self.spellID

	if (action) then
		local isUsable, notEnoughMana = C_ActionBar_IsUsableAction(action)
		if not(isUsable or notEnoughMana) then
			self.icon:SetDesaturation(1)
			return
		end
		
		-- Nil-Safe duration fetch for 12.0.1
		duration = C_ActionBar_GetActionCooldownDuration(action)
		if (not duration) then 
			self.icon:SetDesaturation(0)
			return 
		end

		if duration:HasSecretValues() then
			local actionInfoType, actionInfoID, actionInfoSubType = GetActionInfo(action)
			if (actionInfoType == "item") then
				local _, durationSeconds, enableCooldownTimer = C_Item_GetItemCooldown(actionInfoID)
				if (isOnGCD == nil) then
					isOnGCD = (enableCooldownTimer and muteCatQOL.SafeGreater(durationSeconds, 0) and not muteCatQOL.SafeGreater(durationSeconds, muteCatQOL.GCD)) or false
				end
				if not(isOnGCD) then
					duration = durationSeconds
				else
					duration = nil
				end
			else
				if (isOnGCD == nil) then
					local actionCooldownInfo = C_ActionBar_GetActionCooldown(action)
					if actionCooldownInfo then
						isOnGCD = actionCooldownInfo.isOnGCD or IsActiveCategoryGCD(actionCooldownInfo.activeCategory) or false
						if not(isOnGCD) then
							-- Midnight Macro/Item hybrid check
							if (actionInfoType == "macro" or actionInfoSubType == "item") then
								useGCDCurve = true
							end
						end
					end
				end
				if (isOnGCD) then duration = nil end
			end
		else
			if (isOnGCD == nil) then
				local actionCooldownInfo = C_ActionBar_GetActionCooldown(action)
				if actionCooldownInfo then
					isOnGCD = actionCooldownInfo.isOnGCD or IsActiveCategoryGCD(actionCooldownInfo.activeCategory) or false
					if not(isOnGCD) then
						local actionType, _, actionSubType = GetActionInfo(action)
						if actionType ~= "spell" and actionSubType ~= "spell" and actionSubType ~= "pet" then
							-- Fallback for items with non-secret but short durations
							isOnGCD = (actionCooldownInfo.isEnabled and duration:GetRemainingDuration() > 0 and duration:GetTotalDuration() <= muteCatQOL.GCD) or false
						end
					end
				end
			end
			if (isOnGCD) then duration = nil end
		end
	elseif (spellID) then
		local isUsable, notEnoughMana = C_Spell_IsSpellUsable(spellID)
		if not(isUsable or notEnoughMana) then
			self.icon:SetDesaturation(1)
			return
		end
		if (isOnGCD == nil) then
			local spellCooldownInfo = C_Spell_GetSpellCooldown(spellID)
			if spellCooldownInfo then
				isOnGCD = spellCooldownInfo.isOnGCD or IsActiveCategoryGCD(spellCooldownInfo.activeCategory) or false
			end
		end
		if not(isOnGCD) then
			duration = C_Spell_GetSpellCooldownDuration(spellID)
		end
	end

	-- Evaluation logic
	if (duration) then
		if (type(duration) == "number") then
			self.icon:SetDesaturation(muteCatQOL.SafeGreater(duration, 0) and 1 or 0)
		else
			-- Midnight safe duration evaluation
			if (duration:HasSecretValues()) then
				local curve = useGCDCurve and muteCatQOL.DesaturationCurveGCD or muteCatQOL.DesaturationCurve
				self.icon:SetDesaturation(duration:EvaluateRemainingDuration(curve) or 0)
			else
				self.icon:SetDesaturation((duration:GetRemainingDuration() > 0) and 1 or 0)
			end
		end
	else
		self.icon:SetDesaturation(0)
	end
end

-- Main GOC PetActionButton Update function to desaturate the entire action icon when the spell is on cooldown or unusable
muteCatQOL.GOCPetActionButtonUpdateCheck = function(self)
	local index = self.index or self.id
	if not(self.icon and index and GetPetActionInfo(index)) then return end
	if not(GetPetActionSlotUsable(index)) then
		self.icon:SetDesaturation(1)
		return
	end
	local _, duration, enable = GetPetActionCooldown(index)
	if (enable and duration and muteCatQOL.SafeGreater(duration, muteCatQOL.GCD)) then
		self.icon:SetDesaturation(1)
	else
		self.icon:SetDesaturation(0)
	end
end

-- Hook function to update the ActionButton (self)
muteCatQOL.ButtonUpdateHookFunc = function(self)
	if (self.GOCUpdateCheck) then
		self:GOCUpdateCheck()
	end
end

-- Hook function to update the ActionButton (self:GetParent())
muteCatQOL.ButtonParentUpdateHookFunc = function(self)
	if (self:GetParent().GOCUpdateCheck) then
		self:GetParent():GOCUpdateCheck()
	end
end

muteCatQOL.ApplyStackCountStyle = function(button)
	-- Actionbar stack styling intentionally disabled (Cooldown Viewer styling remains separate).
	return
end
muteCatQOL.BorderReplacementTexture = muteCatQOL.Constants.Assets.BorderTexture
muteCatQOL.BorderReplacementAtlas = muteCatQOL.Constants.Assets.BorderReplacementAtlas

muteCatQOL.RemapOverlayTexture = function(texture)
	if (texture == nil or texture.GetAtlas == nil) then
		return
	end
	local okAtlas, atlasId = pcall(texture.GetAtlas, texture)
	if (not okAtlas or type(atlasId) ~= "string" or atlasId == "") then
		return
	end
	local atlas = muteCatQOL.BorderReplacementAtlas[atlasId]
	if (atlas == nil) then
		return
	end
	local width = texture:GetWidth()
	local height = texture:GetHeight()
	texture:SetTexture(muteCatQOL.BorderReplacementTexture)
	texture:SetTexCoord(atlas[3], atlas[4], atlas[5], atlas[6])
	texture:SetWidth(width)
	texture:SetHeight(height)
end

muteCatQOL.ApplyBorderlessStyle = function(button)
	if (button == nil) then
		return
	end
	local function SuppressTexture(tex, hookTableKey)
		if (tex == nil) then return end
		tex:SetAlpha(0)
		tex:Hide()
		if (muteCatQOL.Runtime.Hooks[hookTableKey] == nil) then
			muteCatQOL.Runtime.Hooks[hookTableKey] = {}
		end
		if not(muteCatQOL.Runtime.Hooks[hookTableKey][tex]) then
			tex:HookScript("OnShow", function(self)
				self:SetAlpha(0)
				self:Hide()
			end)
			muteCatQOL.Runtime.Hooks[hookTableKey][tex] = true
		end
	end
	if (button.NormalTexture ~= nil) then
		button.NormalTexture:Hide()
		if (muteCatQOL.Runtime.Hooks.NormalTextureOnShow == nil) then
			muteCatQOL.Runtime.Hooks.NormalTextureOnShow = {}
		end
		if not(muteCatQOL.Runtime.Hooks.NormalTextureOnShow[button.NormalTexture]) then
			button.NormalTexture:HookScript("OnShow", function(self)
				self:Hide()
			end)
			muteCatQOL.Runtime.Hooks.NormalTextureOnShow[button.NormalTexture] = true
		end
	end
	if (button.icon ~= nil and button.IconMask ~= nil and button.icon.RemoveMaskTexture ~= nil) then
		button.icon:RemoveMaskTexture(button.IconMask)
	end
	if (button.cooldown ~= nil and button.cooldown.SetAllPoints ~= nil) then
		button.cooldown:SetAllPoints(button)
	end
	SuppressTexture(button.HighlightTexture, "HighlightTextureOnShow")
	SuppressTexture(button.Flash, "FlashTextureOnShow")
	SuppressTexture(button.SpellHighlightTexture, "SpellHighlightTextureOnShow")
	SuppressTexture(button.PushedTexture, "PushedTextureOnShow")
	SuppressTexture(button.CheckedTexture, "CheckedTextureOnShow")
	SuppressTexture(button.NewActionTexture, "NewActionTextureOnShow")
	muteCatQOL.RemapOverlayTexture(button.HighlightTexture)
	muteCatQOL.RemapOverlayTexture(button.CheckedTexture)
	muteCatQOL.RemapOverlayTexture(button.SpellHighlightTexture)
	muteCatQOL.RemapOverlayTexture(button.NewActionTexture)
	muteCatQOL.RemapOverlayTexture(button.PushedTexture)
	muteCatQOL.RemapOverlayTexture(button.Border)
	if (button.SlotBackground ~= nil and button.SlotBackground.SetDrawLayer ~= nil) then
		button.SlotBackground:SetDrawLayer("BACKGROUND", -1)
	end
	if (button.SpellCastAnimFrame ~= nil) then
		button.SpellCastAnimFrame:SetScript("OnShow", function(self)
			self:Hide()
		end)
	end
	if (button.SpellActivationAlert ~= nil) then
		button.SpellActivationAlert:SetScript("OnShow", function(self)
			self:Hide()
		end)
	end
	if (button.InterruptDisplay ~= nil) then
		button.InterruptDisplay:SetScript("OnShow", function(self)
			self:Hide()
		end)
	end

	-- Disable hover tooltips for MultiBarRight and MultiBar7 only.
	if (button.GetName ~= nil) then
		local buttonName = button:GetName()
		if (IsNoTooltipBarButtonName(buttonName)) then
			if (muteCatQOL.Runtime.Hooks.NoTooltipOnEnter == nil) then
				muteCatQOL.Runtime.Hooks.NoTooltipOnEnter = {}
			end
			if not(muteCatQOL.Runtime.Hooks.NoTooltipOnEnter[button]) then
				button:HookScript("OnEnter", function()
					if GameTooltip then GameTooltip:Hide() end
				end)
				button:HookScript("OnLeave", function()
					if GameTooltip then GameTooltip:Hide() end
				end)
				muteCatQOL.Runtime.Hooks.NoTooltipOnEnter[button] = true
			end
		end
	end
end

-- Hide Blizzard's action button text/targetability overlay (range/not targetable icon/text).
muteCatQOL.HideActionButtonOverlay = function(button)
	if (button == nil) then
		return
	end
	local textOverlayContainer = button.TextOverlayContainer
	if (textOverlayContainer == nil and button.GetName ~= nil) then
		local buttonName = button:GetName()
		if (buttonName ~= nil) then
			textOverlayContainer = _G[buttonName.."TextOverlayContainer"]
		end
	end
	if (textOverlayContainer == nil) then
		return
	end

	local function HideUnwantedOverlayRegion(region)
		if (region == nil) then
			return
		end
		-- Never hide the stack/charge counter.
		if (button.Count ~= nil and region == button.Count) then
			return
		end
		-- Never hide the keybind text.
		if (button.HotKey ~= nil and region == button.HotKey) then
			return
		end
		if (region.IsObjectType == nil) then
			return
		end
		if (region:IsObjectType("Texture")) then
			region:Hide()
			if (muteCatQOL.Runtime.Hooks.OverlayRegionOnShow == nil) then
				muteCatQOL.Runtime.Hooks.OverlayRegionOnShow = {}
			end
			if not(muteCatQOL.Runtime.Hooks.OverlayRegionOnShow[region]) then
				region:HookScript("OnShow", function(self)
					self:Hide()
				end)
				muteCatQOL.Runtime.Hooks.OverlayRegionOnShow[region] = true
			end
		elseif (region:IsObjectType("FontString")) then
			local regionName = region.GetName and region:GetName() or nil
			if (regionName ~= nil and regionName:find("HotKey")) then
				return
			end
			local text = region:GetText()
			local isNumericText = (text ~= nil and text ~= "" and tonumber(text) ~= nil)
			if not(isNumericText) then
				region:Hide()
				if (muteCatQOL.Runtime.Hooks.OverlayRegionOnShow == nil) then
					muteCatQOL.Runtime.Hooks.OverlayRegionOnShow = {}
				end
				if not(muteCatQOL.Runtime.Hooks.OverlayRegionOnShow[region]) then
					region:HookScript("OnShow", function(self)
						local currentText = self:GetText()
						if not(currentText ~= nil and currentText ~= "" and tonumber(currentText) ~= nil) then
							self:Hide()
						end
					end)
					muteCatQOL.Runtime.Hooks.OverlayRegionOnShow[region] = true
				end
			end
		end
	end

	local regions = { textOverlayContainer:GetRegions() }
	for _, region in ipairs(regions) do
		HideUnwantedOverlayRegion(region)
	end

	local children = { textOverlayContainer:GetChildren() }
	for _, child in ipairs(children) do
		local childRegions = { child:GetRegions() }
		for _, region in ipairs(childRegions) do
			HideUnwantedOverlayRegion(region)
		end
	end
end

-- Function that establishes the needed GOC hooks for an ActionButton
function muteCatQOL:HookGOCActionButtonUpdate(button)
	if (muteCatQOL.Runtime.Hooks.StaticStyleApplied == nil) then
		muteCatQOL.Runtime.Hooks.StaticStyleApplied = {}
	end
	if not(muteCatQOL.Runtime.Hooks.StaticStyleApplied[button]) then
		muteCatQOL.ApplyBorderlessStyle(button)
		muteCatQOL.ApplyStackCountStyle(button)
		muteCatQOL.HideActionButtonOverlay(button)
		muteCatQOL.Runtime.Hooks.StaticStyleApplied[button] = true
	end
	-- Establish the main GOC ActionButton Update function
	if (muteCatQOL.Runtime.Hooks.UpdateCheckSet == nil) then
		muteCatQOL.Runtime.Hooks.UpdateCheckSet = {}
	end
	if not(muteCatQOL.Runtime.Hooks.UpdateCheckSet[button]) then
		button.GOCUpdateCheck = ActionButton_muteCatQOL_UpdateCheck
		muteCatQOL.Runtime.Hooks.UpdateCheckSet[button] = true
	end
	-- ActionButton essentials GOC hooks (AB hooks: OnCooldownDone, OnShow, OnHide, Update, UpdateUsable)
	if button.cooldown then
		if (muteCatQOL.Runtime.Hooks.OnCooldownDone == nil) then
			muteCatQOL.Runtime.Hooks.OnCooldownDone = {}
		end
		if not(muteCatQOL.Runtime.Hooks.OnCooldownDone[button]) then
			button.cooldown:HookScript("OnCooldownDone", muteCatQOL.ButtonParentUpdateHookFunc)
			muteCatQOL.Runtime.Hooks.OnCooldownDone[button] = true
		end
		if (muteCatQOL.Runtime.Hooks.OnShow == nil) then
			muteCatQOL.Runtime.Hooks.OnShow = {}
		end
		if not(muteCatQOL.Runtime.Hooks.OnShow[button]) then
			button.cooldown:HookScript("OnShow", muteCatQOL.ButtonParentUpdateHookFunc)
			muteCatQOL.Runtime.Hooks.OnShow[button] = true
		end
		if (muteCatQOL.Runtime.Hooks.OnHide == nil) then
			muteCatQOL.Runtime.Hooks.OnHide = {}
		end
		if not(muteCatQOL.Runtime.Hooks.OnHide[button]) then
			button.cooldown:HookScript("OnHide", muteCatQOL.ButtonParentUpdateHookFunc)
			muteCatQOL.Runtime.Hooks.OnHide[button] = true
		end
	end
	if type(button.Update)=="function" then
		if (muteCatQOL.Runtime.Hooks.Update == nil) then
			muteCatQOL.Runtime.Hooks.Update = {}
		end
		if not(muteCatQOL.Runtime.Hooks.Update[button]) then
			hooksecurefunc(button, "Update", muteCatQOL.ButtonUpdateHookFunc)
			muteCatQOL.Runtime.Hooks.Update[button] = true
		end
	end
	if type(button.UpdateUsable)=="function" then
		if (muteCatQOL.Runtime.Hooks.UpdateUsable == nil) then
			muteCatQOL.Runtime.Hooks.UpdateUsable = {}
		end
		if not(muteCatQOL.Runtime.Hooks.UpdateUsable[button]) then
			hooksecurefunc(button, "UpdateUsable", muteCatQOL.ButtonUpdateHookFunc)
			muteCatQOL.Runtime.Hooks.UpdateUsable[button] = true
		end
	end
	-- ActionButton GOC hooks to update the RegisteredActionSpells when needed (AB hooks: UpdateAction)
	if type(button.UpdateAction) == "function" then
		if (muteCatQOL.Runtime.Hooks.UpdateAction == nil) then
			muteCatQOL.Runtime.Hooks.UpdateAction = {}
		end
		if not(muteCatQOL.Runtime.Hooks.UpdateAction[button]) then
			hooksecurefunc(button, "UpdateAction", muteCatQOL.UpdateActionButtonAction)
			muteCatQOL.Runtime.Hooks.UpdateAction[button] = true
		end
	end
	if type(button.UpdateCount) == "function" then
		if (muteCatQOL.Runtime.Hooks.UpdateCount == nil) then
			muteCatQOL.Runtime.Hooks.UpdateCount = {}
		end
		if not(muteCatQOL.Runtime.Hooks.UpdateCount[button]) then
			hooksecurefunc(button, "UpdateCount", muteCatQOL.ApplyStackCountStyle)
			muteCatQOL.Runtime.Hooks.UpdateCount[button] = true
		end
	end
	muteCatQOL.UpdateActionButtonAction(button)
end

-- Function that establishes the needed GOC hooks for an PetActionButton
function muteCatQOL:HookGOCPetActionButtonUpdate(button)
	if (muteCatQOL.Runtime.Hooks.StaticStyleApplied == nil) then
		muteCatQOL.Runtime.Hooks.StaticStyleApplied = {}
	end
	if not(muteCatQOL.Runtime.Hooks.StaticStyleApplied[button]) then
		muteCatQOL.ApplyBorderlessStyle(button)
		muteCatQOL.HideActionButtonOverlay(button)
		muteCatQOL.Runtime.Hooks.StaticStyleApplied[button] = true
	end
	-- Establish the main GOC PetActionButton Update function
	if (muteCatQOL.Runtime.Hooks.UpdateCheckSet == nil) then
		muteCatQOL.Runtime.Hooks.UpdateCheckSet = {}
	end
	if not(muteCatQOL.Runtime.Hooks.UpdateCheckSet[button]) then
		button.GOCUpdateCheck = PetActionButton_muteCatQOL_UpdateCheck
		muteCatQOL.Runtime.Hooks.UpdateCheckSet[button] = true
	end
	-- PetActionButton essentials GOC hooks (AB hooks: OnCooldownDone, OnShow, OnHide, Update, UpdateCooldowns)
	if button.cooldown then
		if (muteCatQOL.Runtime.Hooks.OnCooldownDone == nil) then
			muteCatQOL.Runtime.Hooks.OnCooldownDone = {}
		end
		if not(muteCatQOL.Runtime.Hooks.OnCooldownDone[button]) then
			button.cooldown:HookScript("OnCooldownDone", muteCatQOL.ButtonParentUpdateHookFunc)
			muteCatQOL.Runtime.Hooks.OnCooldownDone[button] = true
		end
		if (muteCatQOL.Runtime.Hooks.OnShow == nil) then
			muteCatQOL.Runtime.Hooks.OnShow = {}
		end
		if not(muteCatQOL.Runtime.Hooks.OnShow[button]) then
			button.cooldown:HookScript("OnShow", muteCatQOL.ButtonParentUpdateHookFunc)
			muteCatQOL.Runtime.Hooks.OnShow[button] = true
		end
		if (muteCatQOL.Runtime.Hooks.OnHide == nil) then
			muteCatQOL.Runtime.Hooks.OnHide = {}
		end
		if not(muteCatQOL.Runtime.Hooks.OnHide[button]) then
			button.cooldown:HookScript("OnHide", muteCatQOL.ButtonParentUpdateHookFunc)
			muteCatQOL.Runtime.Hooks.OnHide[button] = true
		end
	end
	if type(button.Update)=="function" then
		if (muteCatQOL.Runtime.Hooks.Update == nil) then
			muteCatQOL.Runtime.Hooks.Update = {}
		end
		if not(muteCatQOL.Runtime.Hooks.Update[button]) then
			hooksecurefunc(button, "Update", muteCatQOL.ButtonUpdateHookFunc)
			muteCatQOL.Runtime.Hooks.Update[button] = true
		end
	end
	if not(muteCatQOL.Runtime.Hooks.UpdateCooldowns) then
		if (PetActionBar ~= nil and type(PetActionBar.UpdateCooldowns) == "function") then
			hooksecurefunc(PetActionBar, "UpdateCooldowns", function(self)
				for i = 1, muteCatQOL.NUM_PET_ACTION_SLOTS do
					local button = self.actionButtons[i]
					if button then
						muteCatQOL.UpdatePetActionButtonAction(button)
					end
				end
			end)
		end
		muteCatQOL.Runtime.Hooks.UpdateCooldowns = true
	end
	muteCatQOL.UpdatePetActionButtonAction(button)
end

-- Function to handle the SPELL_UPDATE_COOLDOWN event
function muteCatQOL:SPELL_UPDATE_COOLDOWN(spellID, baseSpellID, category, startRecoveryCategory)
	if (spellID == nil) then
		spellID = baseSpellID
		if (spellID == nil) then
			return
		end
	end
	local spellCooldownInfo = C_Spell_GetSpellCooldown(spellID)
	if (spellCooldownInfo) then
		if (muteCatQOL.RegisteredActionSpells[spellID]) then
			for k, _ in pairs(muteCatQOL.RegisteredActionSpells[spellID]) do
				if (k.GOCUpdateCheck) then
					k:GOCUpdateCheck(spellCooldownInfo.isOnGCD or false)
				end
			end
		end
	end
	if (muteCatQOL.RelatedActionSpells[spellID] ~= nil) then
		for _, relatedSpellID in pairs(muteCatQOL.RelatedActionSpells[spellID]) do
			spellCooldownInfo = C_Spell_GetSpellCooldown(relatedSpellID)
			if (spellCooldownInfo) then
				if (muteCatQOL.RegisteredActionSpells[relatedSpellID]) then
					for k, _ in pairs(muteCatQOL.RegisteredActionSpells[relatedSpellID]) do
						if (k.GOCUpdateCheck) then
							k:GOCUpdateCheck(spellCooldownInfo.isOnGCD or false)
						end
					end
				end
			end
		end
	end
end

-- Function to set hooks for SpellFlyout frame to detect the newly created SpellFlyoutButtons
function muteCatQOL:HookGOCSpellFlyout()
	if not(muteCatQOL.Runtime.Hooks.SpellFlyout) then
		hooksecurefunc(SpellFlyout, "Toggle", function(self, flyoutButton, flyoutID, isActionBar, specID, showFullTooltip, reason)
			if (not(self:IsShown()) and self.glyphActivating) then
				return
			end
			if (not(self:IsShown()) and self.flyoutButton == nil) then
				return
			end
			local offSpec = specID and (specID ~= 0)
			local _, _, numSlots, isKnown = GetFlyoutInfo(flyoutID)
			if ((not isKnown and not offSpec) or numSlots == 0) then
				return
			end
			local numButtons = 0
			for i = 1, numSlots do
				local spellID, _, isKnownSlot, _, slotSpecID = GetFlyoutSlotInfo(flyoutID, i)
				local visible = true
				local petIndex, petName = GetCallPetSpellInfo(spellID)
				if (isActionBar and petIndex and (not petName or petName == "")) then
					visible = false
				end
				if (((not offSpec or slotSpecID == 0) and visible and isKnownSlot) or (offSpec and slotSpecID == specID)) then
					local button = _G["SpellFlyoutPopupButton"..numButtons+1]
					if (button ~= nil) then
						muteCatQOL:HookGOCActionButtonUpdate(button)
					end
					numButtons = numButtons+1
				end
			end
		end)
		muteCatQOL.Runtime.Hooks.SpellFlyout = true
	end
end

-- Function to iterate through ActionButtons and hook them
function muteCatQOL:HookGOCActionButtons()
	for _, prefix in ipairs(muteCatQOL.ActionBarPrefixes) do
		for i = 1, muteCatQOL.NUM_ACTIONBAR_BUTTONS do
			local actionButton = _G[prefix..i]
			if (actionButton) then
				muteCatQOL:HookGOCActionButtonUpdate(actionButton)
			end
		end
	end
	for i = 1, 40 do
		local actionButton = _G["SpellFlyoutPopupButton"..i]
		if (actionButton) then
			muteCatQOL:HookGOCActionButtonUpdate(actionButton)
		end
	end
	-- SpellFlyoutButtons are created dynamically as needed. This needs to be monitored to apply GOC hooks to new ones.
	muteCatQOL:HookGOCSpellFlyout()
end

-- Function to iterate through PetActionButtons and hook them
function muteCatQOL:HookGOCPetActionButtons()
	for i = 1, muteCatQOL.NUM_PET_ACTION_SLOTS do
		local petActionButton = _G["PetActionButton"..i]
		if (petActionButton) then
			muteCatQOL:HookGOCPetActionButtonUpdate(petActionButton)
		end
	end
end

if not(muteCatQOL.Runtime.Hooks.ActionButtonUpdateCooldown) then
	if (type(ActionButton_UpdateCooldown) == "function") then
		hooksecurefunc("ActionButton_UpdateCooldown", muteCatQOL.ButtonUpdateHookFunc)
		muteCatQOL.Runtime.Hooks.ActionButtonUpdateCooldown = true
	end
end
if not(muteCatQOL.Runtime.Hooks.MultiCastSpellButtonUpdateCooldown) then
	if (type(MultiCastSpellButton_UpdateCooldown) == "function") then
		hooksecurefunc("MultiCastSpellButton_UpdateCooldown", muteCatQOL.ButtonUpdateHookFunc)
		muteCatQOL.Runtime.Hooks.MultiCastSpellButtonUpdateCooldown = true
	end
end
