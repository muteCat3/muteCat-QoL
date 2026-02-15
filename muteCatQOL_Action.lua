local _G = _G
local type = type
local pairs = pairs
local ipairs = ipairs
local GetActionInfo = GetActionInfo
local GetPetActionInfo = GetPetActionInfo
local GetPetActionSlotUsable = GetPetActionSlotUsable
local GetPetActionCooldown = GetPetActionCooldown
local C_ActionBar_IsUsableAction = C_ActionBar.IsUsableAction
local C_ActionBar_GetActionCooldown = C_ActionBar.GetActionCooldown
local C_ActionBar_GetActionCooldownDuration = C_ActionBar.GetActionCooldownDuration
local C_ActionBar_GetActionUseCount = C_ActionBar.GetActionUseCount
local C_Item_GetItemCooldown = C_Item.GetItemCooldown
local C_Spell_IsSpellUsable = C_Spell.IsSpellUsable
local C_Spell_GetSpellCooldown = C_Spell.GetSpellCooldown
local C_Spell_GetSpellCooldownDuration = C_Spell.GetSpellCooldownDuration
local function IsActiveCategoryGCD(activeCategory)
	return type(activeCategory) == "number" and activeCategory == 2316
end


local function IsBar4ButtonName(buttonName)
	return buttonName ~= nil and buttonName:find("^MultiBarRightButton") ~= nil
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
function muteCatQOL:UpdateAllActionButtons()
	for i = 1, muteCatQOL.NUM_ACTIONBAR_BUTTONS do
		local actionButton
		actionButton = _G["ExtraActionButton"..i]
		if (actionButton and actionButton.GOCUpdateCheck) then
			actionButton:GOCUpdateCheck()
		end
		actionButton = _G["ActionButton"..i]
		if (actionButton and actionButton.GOCUpdateCheck) then
			actionButton:GOCUpdateCheck()
		end
		actionButton = _G["MultiBarBottomLeftButton"..i]
		if (actionButton and actionButton.GOCUpdateCheck) then
			actionButton:GOCUpdateCheck()
		end
		actionButton = _G["MultiBarBottomRightButton"..i]
		if (actionButton and actionButton.GOCUpdateCheck) then
			actionButton:GOCUpdateCheck()
		end
		actionButton = _G["MultiBarLeftButton"..i]
		if (actionButton and actionButton.GOCUpdateCheck) then
			actionButton:GOCUpdateCheck()
		end
		actionButton = _G["MultiBarRightButton"..i]
		if (actionButton and actionButton.GOCUpdateCheck) then
			actionButton:GOCUpdateCheck()
		end
		actionButton = _G["MultiBar5Button"..i]
		if (actionButton and actionButton.GOCUpdateCheck) then
			actionButton:GOCUpdateCheck()
		end
		actionButton = _G["MultiBar6Button"..i]
		if (actionButton and actionButton.GOCUpdateCheck) then
			actionButton:GOCUpdateCheck()
		end
		actionButton = _G["MultiBar7Button"..i]
		if (actionButton and actionButton.GOCUpdateCheck) then
			actionButton:GOCUpdateCheck()
		end
		actionButton = _G["MultiBar8Button"..i]
		if (actionButton and actionButton.GOCUpdateCheck) then
			actionButton:GOCUpdateCheck()
		end
		actionButton = _G["StanceButton"..i]
		if (actionButton and actionButton.GOCUpdateCheck) then
			actionButton:GOCUpdateCheck()
		end
		actionButton = _G["PossessButton"..i]
		if (actionButton and actionButton.GOCUpdateCheck) then
			actionButton:GOCUpdateCheck()
		end
		actionButton = _G["OverrideActionBarButton"..i]
		if (actionButton and actionButton.GOCUpdateCheck) then
			actionButton:GOCUpdateCheck()
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
		duration = C_ActionBar_GetActionCooldownDuration(action)
		if duration:HasSecretValues() then
			local actionInfoType, actionInfoID, actionInfoSubType = GetActionInfo(action)
			if actionInfoType == "item" then
				local _, durationSeconds, enableCooldownTimer = C_Item_GetItemCooldown(actionInfoID)
				if (isOnGCD == nil) then
					isOnGCD = (enableCooldownTimer and durationSeconds > 0 and durationSeconds <= muteCatQOL.GCD) or false
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
						isOnGCD = actionCooldownInfo.isOnGCD or false
						if not(isOnGCD) then
							if actionInfoType == "macro" and actionInfoSubType=="item" then
								useGCDCurve = true
							end
						end
					end
				end
				if isOnGCD then
					duration = nil
				end
			end
		else
			if not(isOnGCD) then
				local actionCooldownInfo = C_ActionBar_GetActionCooldown(action)
				if actionCooldownInfo then
					isOnGCD = actionCooldownInfo.isOnGCD or IsActiveCategoryGCD(actionCooldownInfo.activeCategory) or false
					if not(isOnGCD) then
						local actionInfoType, _, actionInfoSubType = GetActionInfo(action)
						if actionInfoType ~= "spell" and actionInfoSubType~="spell" and actionInfoSubType~="pet" then
							isOnGCD = (actionCooldownInfo.isEnabled and duration:GetRemainingDuration() > 0 and duration:GetTotalDuration() <= muteCatQOL.GCD) or false
						end
					end
				end
			end
			if isOnGCD then
				duration = nil
			end
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
	if duration then
		if type(duration)=="number" then
			if (duration > 0) then
				self.icon:SetDesaturation(1)
			else
				self.icon:SetDesaturation(0)
			end
		else
			if duration:HasSecretValues() then
				if not(useGCDCurve) then
					self.icon:SetDesaturation(duration:EvaluateRemainingDuration(muteCatQOL.DesaturationCurve))
				else
					self.icon:SetDesaturation(duration:EvaluateRemainingDuration(muteCatQOL.DesaturationCurveGCD))
				end
			else
				if (duration:GetRemainingDuration() > 0) then
					self.icon:SetDesaturation(1)
				else
					self.icon:SetDesaturation(0)
				end
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
	if (enable and duration and duration > 0 and duration > muteCatQOL.GCD) then
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
	if (button == nil or button.Count == nil) then
		return
	end
	local countText = button.Count
	local buttonName = button.GetName ~= nil and button:GetName() or nil
	local isActionBar4Button = IsBar4ButtonName(buttonName)
	local isActionBar7Button = IsBottomRightStackBarName(buttonName)
	local isBar5Button = IsBar5ButtonName(buttonName)

	local function GetSafeDisplayCount()
		if (button.action ~= nil and C_ActionBar_GetActionUseCount ~= nil) then
			return C_ActionBar_GetActionUseCount(button.action)
		end
		return nil
	end

	local function UpdateStackCountVisibility()
		local count = GetSafeDisplayCount()
		if (count ~= nil) then
			local ok, isZeroOrLess = pcall(function()
				return count <= 0
			end)
			if (ok and isZeroOrLess) then
				countText:Hide()
				return
			end
		end
		countText:Show()
	end

	if (MUTECATQOL_COUNT_ONSHOW_HOOKED == nil) then
		MUTECATQOL_COUNT_ONSHOW_HOOKED = {}
	end
	if not(MUTECATQOL_COUNT_ONSHOW_HOOKED[countText]) then
		countText:HookScript("OnShow", function(self)
			local parent = self:GetParent()
			if (parent ~= nil) then
				muteCatQOL.ApplyStackCountStyle(parent)
			end
		end)
		MUTECATQOL_COUNT_ONSHOW_HOOKED[countText] = true
	end

	if (countText.HasScript ~= nil and countText:HasScript("OnTextChanged")) then
		if (MUTECATQOL_COUNT_ONTEXTCHANGED_HOOKED == nil) then
			MUTECATQOL_COUNT_ONTEXTCHANGED_HOOKED = {}
		end
		if not(MUTECATQOL_COUNT_ONTEXTCHANGED_HOOKED[countText]) then
			countText:HookScript("OnTextChanged", function(self)
				local parent = self:GetParent()
				if (parent ~= nil) then
					muteCatQOL.ApplyStackCountStyle(parent)
				end
			end)
			MUTECATQOL_COUNT_ONTEXTCHANGED_HOOKED[countText] = true
		end
	end

	if (isActionBar4Button) then
		countText:Hide()
		return
	end

	countText:ClearAllPoints()
	if (isActionBar7Button) then
		countText:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 3, 0)
		countText:SetJustifyH("RIGHT")
		countText:SetJustifyV("BOTTOM")
	else
		if (isBar5Button) then
			countText:SetPoint("TOPRIGHT", button, "TOPRIGHT", 1, 0)
		else
			countText:SetPoint("TOPRIGHT", button, "TOPRIGHT", 4, 0)
		end
		countText:SetJustifyH("RIGHT")
		countText:SetJustifyV("TOP")
	end
	countText:SetTextColor(1, 0, 1, 1)
	local font, _, flags = countText:GetFont()
	if (font ~= nil) then
		countText:SetFont(font, 18, flags)
	end
	UpdateStackCountVisibility()
end
muteCatQOL.BorderReplacementTexture = "Interface\\AddOns\\muteCatQOL\\resources\\uiactionbar2x"
muteCatQOL.BorderReplacementAtlas = {
	["UI-HUD-ActionBar-IconFrame-Slot"] = { 64, 31, 0.701172, 0.951172, 0.102051, 0.162598, false, false, "2x" },
	["UI-HUD-ActionBar-IconFrame"] = { 46, 22, 0.701172, 0.880859, 0.316895, 0.36084, false, false, "2x" },
	["UI-HUD-ActionBar-IconFrame-AddRow"] = { 51, 25, 0.701172, 0.900391, 0.215332, 0.265137, false, false, "2x" },
	["UI-HUD-ActionBar-IconFrame-Down"] = { 46, 22, 0.701172, 0.880859, 0.430176, 0.474121, false, false, "2x" },
	["UI-HUD-ActionBar-IconFrame-Flash"] = { 46, 22, 0.701172, 0.880859, 0.475098, 0.519043, false, false, "2x" },
	["UI-HUD-ActionBar-IconFrame-FlyoutBorderShadow"] = { 52, 26, 0.701172, 0.904297, 0.163574, 0.214355, false, false, "2x" },
	["UI-HUD-ActionBar-IconFrame-Mouseover"] = { 46, 22, 0.701172, 0.880859, 0.52002, 0.563965, false, false, "2x" },
	["UI-HUD-ActionBar-IconFrame-Border"] = { 46, 22, 0.701172, 0.880859, 0.361816, 0.405762, false, false, "2x" },
	["UI-HUD-ActionBar-IconFrame-AddRow-Down"] = { 51, 25, 0.701172, 0.900391, 0.266113, 0.315918, false, false, "2x" },
}

muteCatQOL.RemapOverlayTexture = function(texture)
	if (texture == nil or texture.GetAtlas == nil) then
		return
	end
	local atlasId = texture:GetAtlas()
	if (atlasId == nil) then
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
	if (button.NormalTexture ~= nil) then
		button.NormalTexture:Hide()
		if (MUTECATQOL_NORMALTEXTURE_ONSHOW_HOOKED == nil) then
			MUTECATQOL_NORMALTEXTURE_ONSHOW_HOOKED = {}
		end
		if not(MUTECATQOL_NORMALTEXTURE_ONSHOW_HOOKED[button.NormalTexture]) then
			button.NormalTexture:HookScript("OnShow", function(self)
				self:Hide()
			end)
			MUTECATQOL_NORMALTEXTURE_ONSHOW_HOOKED[button.NormalTexture] = true
		end
	end
	if (button.icon ~= nil and button.IconMask ~= nil and button.icon.RemoveMaskTexture ~= nil) then
		button.icon:RemoveMaskTexture(button.IconMask)
	end
	if (button.cooldown ~= nil and button.cooldown.SetAllPoints ~= nil) then
		button.cooldown:SetAllPoints(button)
	end
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
	if (button.InterruptDisplay ~= nil) then
		button.InterruptDisplay:SetScript("OnShow", function(self)
			self:Hide()
		end)
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
		if (region.IsObjectType == nil) then
			return
		end
		if (region:IsObjectType("Texture")) then
			region:Hide()
			if (MUTECATQOL_OVERLAY_REGION_ONSHOW_HOOKED == nil) then
				MUTECATQOL_OVERLAY_REGION_ONSHOW_HOOKED = {}
			end
			if not(MUTECATQOL_OVERLAY_REGION_ONSHOW_HOOKED[region]) then
				region:HookScript("OnShow", function(self)
					self:Hide()
				end)
				MUTECATQOL_OVERLAY_REGION_ONSHOW_HOOKED[region] = true
			end
		elseif (region:IsObjectType("FontString")) then
			local text = region:GetText()
			local isNumericText = (text ~= nil and text ~= "" and tonumber(text) ~= nil)
			if not(isNumericText) then
				region:Hide()
				if (MUTECATQOL_OVERLAY_REGION_ONSHOW_HOOKED == nil) then
					MUTECATQOL_OVERLAY_REGION_ONSHOW_HOOKED = {}
				end
				if not(MUTECATQOL_OVERLAY_REGION_ONSHOW_HOOKED[region]) then
					region:HookScript("OnShow", function(self)
						local currentText = self:GetText()
						if not(currentText ~= nil and currentText ~= "" and tonumber(currentText) ~= nil) then
							self:Hide()
						end
					end)
					MUTECATQOL_OVERLAY_REGION_ONSHOW_HOOKED[region] = true
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
	if (MUTECATQOL_STATIC_STYLE_APPLIED_AB == nil) then
		MUTECATQOL_STATIC_STYLE_APPLIED_AB = {}
	end
	if not(MUTECATQOL_STATIC_STYLE_APPLIED_AB[button]) then
		muteCatQOL.ApplyBorderlessStyle(button)
		muteCatQOL.ApplyStackCountStyle(button)
		muteCatQOL.HideActionButtonOverlay(button)
		MUTECATQOL_STATIC_STYLE_APPLIED_AB[button] = true
	end
	-- Establish the main GOC ActionButton Update function
	if (MUTECATQOL_UPDATECHECK_SET_AB == nil) then
		MUTECATQOL_UPDATECHECK_SET_AB = {}
	end
	if not(MUTECATQOL_UPDATECHECK_SET_AB[button]) then
		button.GOCUpdateCheck = ActionButton_muteCatQOL_UpdateCheck
		MUTECATQOL_UPDATECHECK_SET_AB[button] = true
	end
	-- ActionButton essentials GOC hooks (AB hooks: OnCooldownDone, OnShow, OnHide, Update, UpdateUsable)
	if button.cooldown then
		if (MUTECATQOL_ONCOOLDOWNDONE_HOOKED_ABC == nil) then
			MUTECATQOL_ONCOOLDOWNDONE_HOOKED_ABC = {}
		end
		if not(MUTECATQOL_ONCOOLDOWNDONE_HOOKED_ABC[button]) then
			button.cooldown:HookScript("OnCooldownDone", muteCatQOL.ButtonParentUpdateHookFunc)
			MUTECATQOL_ONCOOLDOWNDONE_HOOKED_ABC[button] = true
		end
		if (MUTECATQOL_ONSHOW_HOOKED_ABC == nil) then
			MUTECATQOL_ONSHOW_HOOKED_ABC = {}
		end
		if not(MUTECATQOL_ONSHOW_HOOKED_ABC[button]) then
			button.cooldown:HookScript("OnShow", muteCatQOL.ButtonParentUpdateHookFunc)
			MUTECATQOL_ONSHOW_HOOKED_ABC[button] = true
		end
		if (MUTECATQOL_ONHIDE_HOOKED_ABC == nil) then
			MUTECATQOL_ONHIDE_HOOKED_ABC = {}
		end
		if not(MUTECATQOL_ONHIDE_HOOKED_ABC[button]) then
			button.cooldown:HookScript("OnHide", muteCatQOL.ButtonParentUpdateHookFunc)
			MUTECATQOL_ONHIDE_HOOKED_ABC[button] = true
		end
	end
	if type(button.Update)=="function" then
		if (MUTECATQOL_UPDATE_HOOKED_AB == nil) then
			MUTECATQOL_UPDATE_HOOKED_AB = {}
		end
		if not(MUTECATQOL_UPDATE_HOOKED_AB[button]) then
			hooksecurefunc(button, "Update", muteCatQOL.ButtonUpdateHookFunc)
			MUTECATQOL_UPDATE_HOOKED_AB[button] = true
		end
	end
	if type(button.UpdateUsable)=="function" then
		if (MUTECATQOL_UPDATEUSABLE_HOOKED_AB == nil) then
			MUTECATQOL_UPDATEUSABLE_HOOKED_AB = {}
		end
		if not(MUTECATQOL_UPDATEUSABLE_HOOKED_AB[button]) then
			hooksecurefunc(button, "UpdateUsable", muteCatQOL.ButtonUpdateHookFunc)
			MUTECATQOL_UPDATEUSABLE_HOOKED_AB[button] = true
		end
	end
	-- ActionButton GOC hooks to update the RegisteredActionSpells when needed (AB hooks: UpdateAction)
	if type(button.UpdateAction) == "function" then
		if (MUTECATQOL_UPDATEACTION_HOOKED_AB == nil) then
			MUTECATQOL_UPDATEACTION_HOOKED_AB = {}
		end
		if not(MUTECATQOL_UPDATEACTION_HOOKED_AB[button]) then
			hooksecurefunc(button, "UpdateAction", muteCatQOL.UpdateActionButtonAction)
			MUTECATQOL_UPDATEACTION_HOOKED_AB[button] = true
		end
	end
	if type(button.UpdateCount) == "function" then
		if (MUTECATQOL_UPDATECOUNT_HOOKED_AB == nil) then
			MUTECATQOL_UPDATECOUNT_HOOKED_AB = {}
		end
		if not(MUTECATQOL_UPDATECOUNT_HOOKED_AB[button]) then
			hooksecurefunc(button, "UpdateCount", muteCatQOL.ApplyStackCountStyle)
			MUTECATQOL_UPDATECOUNT_HOOKED_AB[button] = true
		end
	end
	muteCatQOL.UpdateActionButtonAction(button)
end

-- Function that establishes the needed GOC hooks for an PetActionButton
function muteCatQOL:HookGOCPetActionButtonUpdate(button)
	if (MUTECATQOL_STATIC_STYLE_APPLIED_AB == nil) then
		MUTECATQOL_STATIC_STYLE_APPLIED_AB = {}
	end
	if not(MUTECATQOL_STATIC_STYLE_APPLIED_AB[button]) then
		muteCatQOL.ApplyBorderlessStyle(button)
		muteCatQOL.HideActionButtonOverlay(button)
		MUTECATQOL_STATIC_STYLE_APPLIED_AB[button] = true
	end
	-- Establish the main GOC PetActionButton Update function
	if (MUTECATQOL_UPDATECHECK_SET_AB == nil) then
		MUTECATQOL_UPDATECHECK_SET_AB = {}
	end
	if not(MUTECATQOL_UPDATECHECK_SET_AB[button]) then
		button.GOCUpdateCheck = PetActionButton_muteCatQOL_UpdateCheck
		MUTECATQOL_UPDATECHECK_SET_AB[button] = true
	end
	-- PetActionButton essentials GOC hooks (AB hooks: OnCooldownDone, OnShow, OnHide, Update, UpdateCooldowns)
	if button.cooldown then
		if (MUTECATQOL_ONCOOLDOWNDONE_HOOKED_ABC == nil) then
			MUTECATQOL_ONCOOLDOWNDONE_HOOKED_ABC = {}
		end
		if not(MUTECATQOL_ONCOOLDOWNDONE_HOOKED_ABC[button]) then
			button.cooldown:HookScript("OnCooldownDone", muteCatQOL.ButtonParentUpdateHookFunc)
			MUTECATQOL_ONCOOLDOWNDONE_HOOKED_ABC[button] = true
		end
		if (MUTECATQOL_ONSHOW_HOOKED_ABC == nil) then
			MUTECATQOL_ONSHOW_HOOKED_ABC = {}
		end
		if not(MUTECATQOL_ONSHOW_HOOKED_ABC[button]) then
			button.cooldown:HookScript("OnShow", muteCatQOL.ButtonParentUpdateHookFunc)
			MUTECATQOL_ONSHOW_HOOKED_ABC[button] = true
		end
		if (MUTECATQOL_ONHIDE_HOOKED_ABC == nil) then
			MUTECATQOL_ONHIDE_HOOKED_ABC = {}
		end
		if not(MUTECATQOL_ONHIDE_HOOKED_ABC[button]) then
			button.cooldown:HookScript("OnHide", muteCatQOL.ButtonParentUpdateHookFunc)
			MUTECATQOL_ONHIDE_HOOKED_ABC[button] = true
		end
	end
	if type(button.Update)=="function" then
		if (MUTECATQOL_UPDATE_HOOKED_AB == nil) then
			MUTECATQOL_UPDATE_HOOKED_AB = {}
		end
		if not(MUTECATQOL_UPDATE_HOOKED_AB[button]) then
			hooksecurefunc(button, "Update", muteCatQOL.ButtonUpdateHookFunc)
			MUTECATQOL_UPDATE_HOOKED_AB[button] = true
		end
	end
	if not(MUTECATQOL_UPDATECOOLDOWNS_HOOKED_PAB) then
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
		MUTECATQOL_UPDATECOOLDOWNS_HOOKED_PAB = true
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
	if not(MUTECATQOL_SPELLFLYOUT_HOOKED) then
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
		MUTECATQOL_SPELLFLYOUT_HOOKED = true
	end
end

-- Function to iterate through ActionButtons and hook them
function muteCatQOL:HookGOCActionButtons()
	for i = 1, muteCatQOL.NUM_ACTIONBAR_BUTTONS do
		local actionButton
		actionButton = _G["ExtraActionButton"..i]
		if (actionButton) then
			muteCatQOL:HookGOCActionButtonUpdate(actionButton)
		end
		actionButton = _G["ActionButton"..i]
		if (actionButton) then
			muteCatQOL:HookGOCActionButtonUpdate(actionButton)
		end
		actionButton = _G["MultiBarBottomLeftButton"..i]
		if (actionButton) then
			muteCatQOL:HookGOCActionButtonUpdate(actionButton)
		end
		actionButton = _G["MultiBarBottomRightButton"..i]
		if (actionButton) then
			muteCatQOL:HookGOCActionButtonUpdate(actionButton)
		end
		actionButton = _G["MultiBarLeftButton"..i]
		if (actionButton) then
			muteCatQOL:HookGOCActionButtonUpdate(actionButton)
		end
		actionButton = _G["MultiBarRightButton"..i]
		if (actionButton) then
			muteCatQOL:HookGOCActionButtonUpdate(actionButton)
		end
		actionButton = _G["MultiBar5Button"..i]
		if (actionButton) then
			muteCatQOL:HookGOCActionButtonUpdate(actionButton)
		end
		actionButton = _G["MultiBar6Button"..i]
		if (actionButton) then
			muteCatQOL:HookGOCActionButtonUpdate(actionButton)
		end
		actionButton = _G["MultiBar7Button"..i]
		if (actionButton) then
			muteCatQOL:HookGOCActionButtonUpdate(actionButton)
		end
		actionButton = _G["MultiBar8Button"..i]
		if (actionButton) then
			muteCatQOL:HookGOCActionButtonUpdate(actionButton)
		end
		actionButton = _G["StanceButton"..i]
		if (actionButton) then
			muteCatQOL:HookGOCActionButtonUpdate(actionButton)
		end
		actionButton = _G["PossessButton"..i]
		if (actionButton) then
			muteCatQOL:HookGOCActionButtonUpdate(actionButton)
		end
		actionButton = _G["OverrideActionBarButton"..i]
		if (actionButton) then
			muteCatQOL:HookGOCActionButtonUpdate(actionButton)
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
	if not(MUTECATQOL_ACTIONBUTTON_UPDATECOOLDOWN_HOOKED) then
		if (type(ActionButton_UpdateCooldown) == "function") then
			hooksecurefunc("ActionButton_UpdateCooldown", muteCatQOL.ButtonUpdateHookFunc)
			MUTECATQOL_ACTIONBUTTON_UPDATECOOLDOWN_HOOKED = true
		end
	end
	if not(MUTECATQOL_MULTICASTSPELLBUTTON_UPDATECOOLDOWN_HOOKED) then
		if (type(MultiCastSpellButton_UpdateCooldown) == "function") then
			hooksecurefunc("MultiCastSpellButton_UpdateCooldown", muteCatQOL.ButtonUpdateHookFunc)
			MUTECATQOL_MULTICASTSPELLBUTTON_UPDATECOOLDOWN_HOOKED = true
		end
	end
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











