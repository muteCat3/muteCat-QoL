local _G = _G
local C_Container = C_Container
local GetItemCountFn = (C_Container and C_Container.GetItemCount) or GetItemCount

local AUTO_POTION_MACRO_NAME = "muteCatAutoPotion"
local FISHING_SPELL_ID = 131474
local FISHING_DOUBLECLICK_MIN = 0.04
local FISHING_DOUBLECLICK_MAX = 0.20

-- Prioritized by expansion/newness. Fallback is first available in bags.
local HEALING_POTION_IDS = {
	211878, -- Algari Healing Potion
	191380, -- Refreshing Healing Potion
	171267, -- Spiritual Healing Potion
	152615, -- Astral Healing Potion
	127834, -- Ancient Healing Potion
	109223, -- Healing Tonic
	76098,  -- Master Healing Potion
	57191,  -- Mythical Healing Potion
	41166,  -- Runic Healing Potion
	33447,  -- Runic Healing Potion (legacy variant)
	22829,  -- Super Healing Potion
	13446,  -- Major Healing Potion
	3928,   -- Superior Healing Potion
	1710,   -- Greater Healing Potion
	929,    -- Healing Potion
	858,    -- Lesser Healing Potion
	118,    -- Minor Healing Potion
}

local function GetBestHealingPotionID()
	if type(GetItemCountFn) ~= "function" then
		return nil
	end

	local bestID
	for _, itemID in ipairs(HEALING_POTION_IDS) do
		local totalCount = GetItemCountFn(itemID, false, false, false) or 0
		if totalCount > 0 then
			bestID = itemID
			break
		end
	end

	return bestID
end

local function BuildAutoPotionMacroText()
	local potionID = GetBestHealingPotionID()
	local lines = {
		"#showtooltip",
		"/use item:5512", -- Healthstone
	}

	if potionID then
		lines[#lines + 1] = "/use item:" .. potionID
	end

	return table.concat(lines, "\n")
end

local function GetFishingSpellName()
	if C_Spell and C_Spell.GetSpellName then
		return C_Spell.GetSpellName(FISHING_SPELL_ID)
	end
	return GetSpellInfo(FISHING_SPELL_ID)
end

local function IsTaintable()
	return (InCombatLockdown and InCombatLockdown()) or UnitAffectingCombat("player") or UnitAffectingCombat("pet")
end

local function IsFishingKnown()
	if IsSpellKnown then
		return IsSpellKnown(FISHING_SPELL_ID)
	end
	if C_SpellBook and C_SpellBook.IsSpellKnown then
		return C_SpellBook.IsSpellKnown(FISHING_SPELL_ID)
	end
	return GetFishingSpellName() ~= nil
end

local function AllowFishingDoubleClick()
	if not IsFishingKnown() then return false end
	if IsMounted and IsMounted() then return false end
	if IsFlying and IsFlying() then return false end
	if IsFalling and IsFalling() then return false end
	if IsSwimming and IsSwimming() then return false end
	if IsStealthed and IsStealthed() then return false end
	if UnitHasVehicleUI and UnitHasVehicleUI("player") then return false end
	if HasFullControl and not HasFullControl() then return false end
	if IsPlayerMoving and IsPlayerMoving() then return false end
	return true
end

function muteCatQOL:UpdateAutoPotionMacro()
	if InCombatLockdown and InCombatLockdown() then
		muteCatQOL.Runtime.State.AutoPotionMacroPending = true
		return
	end

	local macroText = BuildAutoPotionMacroText()
	local macroIndex = GetMacroIndexByName(AUTO_POTION_MACRO_NAME)
	if macroIndex and macroIndex > 0 then
		EditMacro(macroIndex, AUTO_POTION_MACRO_NAME, "INV_Potion_51", macroText, 0)
	else
		CreateMacro(AUTO_POTION_MACRO_NAME, "INV_Potion_51", macroText, false)
	end
end

function muteCatQOL:InitializeAutoPotionMacro()
	if muteCatQOL.Runtime.Hooks.AutoPotionMacroEventFrame then
		return
	end

	local frame = CreateFrame("Frame")
	local events = {
		"PLAYER_LOGIN",
		"PLAYER_ENTERING_WORLD",
		"BAG_UPDATE_DELAYED",
		"UNIT_INVENTORY_CHANGED",
		"PLAYER_REGEN_ENABLED",
	}
	for _, eventName in ipairs(events) do
		frame:RegisterEvent(eventName)
	end

	frame:SetScript("OnEvent", function(_, eventName, unit)
		if eventName == "UNIT_INVENTORY_CHANGED" and unit ~= "player" then
			return
		end
		if eventName == "PLAYER_REGEN_ENABLED" then
			if muteCatQOL.Runtime.State.AutoPotionMacroPending then
				muteCatQOL.Runtime.State.AutoPotionMacroPending = false
				muteCatQOL:UpdateAutoPotionMacro()
			end
			return
		end
		muteCatQOL:UpdateAutoPotionMacro()
	end)

	muteCatQOL.Runtime.Hooks.AutoPotionMacroEventFrame = frame
	C_Timer.After(0.25, function()
		muteCatQOL:UpdateAutoPotionMacro()
	end)
end

local function UpdateFishingButtonSpell()
	if not _G.muteCatQOLFishingButton then
		return
	end

	if IsFishingKnown() then
		_G.muteCatQOLFishingButton:SetAttribute("type", "spell")
		_G.muteCatQOLFishingButton:SetAttribute("spell", FISHING_SPELL_ID)
	else
		_G.muteCatQOLFishingButton:SetAttribute("type", nil)
		_G.muteCatQOLFishingButton:SetAttribute("spell", nil)
	end
end

function muteCatQOL:InitializeFishingHelper()
	if not _G.muteCatQOLFishingButton then
		local button = CreateFrame("Button", "muteCatQOLFishingButton", UIParent, "SecureActionButtonTemplate")
		button:RegisterForClicks("AnyDown", "AnyUp")
		button:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -1000, 1000)
		button:SetSize(1, 1)
	end

	_G["BINDING_HEADER_MUTECATQOL"] = "muteCat QoL"
	_G["BINDING_NAME_CLICK muteCatQOLFishingButton:LeftButton"] = "Cast Fishing"

	UpdateFishingButtonSpell()

	if not muteCatQOL.Runtime.Hooks.FishingHelperEventFrame then
		local frame = CreateFrame("Frame")
		frame:RegisterEvent("SPELLS_CHANGED")
		frame:RegisterEvent("PLAYER_LOGIN")
		frame:RegisterEvent("GLOBAL_MOUSE_DOWN")
		frame:RegisterEvent("GLOBAL_MOUSE_UP")
		frame:RegisterEvent("PLAYER_REGEN_ENABLED")
		frame:SetScript("OnEvent", function(_, eventName, arg1)
			if eventName == "SPELLS_CHANGED" or eventName == "PLAYER_LOGIN" then
				UpdateFishingButtonSpell()
				return
			end

			local button = _G.muteCatQOLFishingButton
			if not button then
				return
			end

			if eventName == "PLAYER_REGEN_ENABLED" then
				if muteCatQOL.Runtime.State.FishingClearBindingsPending then
					muteCatQOL.Runtime.State.FishingClearBindingsPending = false
					ClearOverrideBindings(button)
				end
				return
			end

			if eventName == "GLOBAL_MOUSE_DOWN" then
				if arg1 ~= "RightButton" then
					return
				end
				if IsMouseButtonDown and IsMouseButtonDown("LeftButton") then
					return
				end
				if IsModifierKeyDown and IsModifierKeyDown() then
					return
				end
				if IsTaintable() then
					return
				end

				local now = GetTime()
				local last = muteCatQOL.Runtime.State.FishingLastRightClickTime or 0
				local delta = now - last
				muteCatQOL.Runtime.State.FishingLastRightClickTime = now

				if delta >= FISHING_DOUBLECLICK_MIN and delta <= FISHING_DOUBLECLICK_MAX and AllowFishingDoubleClick() then
					SetOverrideBindingClick(button, true, "BUTTON2", "muteCatQOLFishingButton")
				end
				return
			end

			if eventName == "GLOBAL_MOUSE_UP" and arg1 == "RightButton" then
				if IsTaintable() then
					muteCatQOL.Runtime.State.FishingClearBindingsPending = true
					return
				end
				ClearOverrideBindings(button)
			end
		end)
		muteCatQOL.Runtime.Hooks.FishingHelperEventFrame = frame
	end

	if not SLASH_MUTECATQOLFISH1 then
		SLASH_MUTECATQOLFISH1 = "/mcfish"
		SlashCmdList.MUTECATQOLFISH = function()
			local spellName = GetFishingSpellName()
			if spellName then
				CastSpellByID(FISHING_SPELL_ID)
			end
		end
	end
end
