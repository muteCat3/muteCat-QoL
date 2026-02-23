-- ============================================================ --
-- muteCat QOL                                                  --
-- ------------------------------------------------------------ --
-- Author: Ben                                                  --
-- Addon Version: 3.1.7                                         --
-- WoW Version: 12.0.1                                          --
-- License: GNU GENERAL PUBLIC LICENSE, Version 3, 29 June 2007 --
-- ============================================================ --

muteCatQOL = LibStub("AceAddon-3.0"):NewAddon("muteCatQOL")
muteCatQOL.frame = muteCatQOL.frame or CreateFrame("Frame", "muteCatQOLFrame")

-- ============================================================ --
-- Constants (defined here to guarantee availability)            --
-- ============================================================ --
muteCatQOL.Constants = {
	VERSION = "3.2.1",
	GCD = 1.88,
	
	-- Action Button Configurations
	NUM_ACTIONBAR_BUTTONS = 12,
	NUM_PET_ACTION_SLOTS = 10,
	
	-- Spell IDs
	Spells = {
		StanceHideForm = 465,
	},
	
	-- Related spells for cooldown updates
	RelatedSpells = {
		[372608] = { 372610 },
		[372610] = { 372608 },
		[403092] = { 372608, 372610 },
		[425782] = { 372608, 372610 },
		[372606] = { 372608, 372610 }
	},

	-- UI Configuration
	UI = {
		MicroMenuIdleAlpha = 0.3,
		BuffBarHideDelay = 1.0,
		TickInterval = 0.05,
		FastTickInterval = 0.05,
		EditModeTickInterval = 0.1,
	},

	-- Action Bar Assets
		Assets = {
			BorderTexture = "Interface\\AddOns\\muteCat QoL\\resources\\uiactionbar2x",
		Prefixes = {
			"ActionButton",
			"MultiBarBottomLeftButton",
			"MultiBarBottomRightButton",
			"MultiBarLeftButton",
			"MultiBarRightButton",
			"MultiBar5Button",
			"MultiBar6Button",
			"MultiBar7Button",
			"MultiBar8Button",
			"StanceButton",
			"PossessButton",
			"OverrideActionBarButton",
			"ExtraActionButton"
		},
		-- High-Res Atlas Remapping
		BorderReplacementAtlas = {
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
	}
}

-- ============================================================ --
-- Runtime State                                                 --
-- ============================================================ --
muteCatQOL.Runtime = {
	Tickers = {},
	Hooks = {},
	State = {},
	Buttons = {}
}

-- ============================================================ --
-- Convenience Aliases                                           --
-- ============================================================ --
muteCatQOL.VERSION = muteCatQOL.Constants.VERSION
muteCatQOL.GCD = muteCatQOL.Constants.GCD
muteCatQOL.NUM_ACTIONBAR_BUTTONS = muteCatQOL.Constants.NUM_ACTIONBAR_BUTTONS
muteCatQOL.NUM_PET_ACTION_SLOTS = muteCatQOL.Constants.NUM_PET_ACTION_SLOTS
muteCatQOL.RelatedActionSpells = muteCatQOL.Constants.RelatedSpells
muteCatQOL.RegisteredActionSpells = {}
muteCatQOL.HideStanceBarOnFormIndex = nil
muteCatQOL.HideStanceBarOnFormSpellID = muteCatQOL.Constants.Spells.StanceHideForm

-- ============================================================ --
-- Event Dispatcher                                              --
-- ============================================================ --
function muteCatQOL:OnEvent(event, ...)
	if (muteCatQOL[event] ~= nil) then
		muteCatQOL[event](muteCatQOL, ...)
	end
	if muteCatQOL.RequestMasterTickerBoost then
		muteCatQOL:RequestMasterTickerBoost(0.6)
	end
end
muteCatQOL.frame:SetScript("OnEvent", muteCatQOL.OnEvent)

-- ============================================================ --
-- Ace Lifecycle                                                 --
-- ============================================================ --
function muteCatQOL:OnInitialize()
	if _G.NUM_ACTIONBAR_BUTTONS ~= nil then
		muteCatQOL.NUM_ACTIONBAR_BUTTONS = _G.NUM_ACTIONBAR_BUTTONS
	end
	if _G.NUM_PET_ACTION_SLOTS ~= nil then
		muteCatQOL.NUM_PET_ACTION_SLOTS = _G.NUM_PET_ACTION_SLOTS
	end
end

function muteCatQOL:OnEnable()
	self:MainFunction()
end

function muteCatQOL:OnDisable()
	muteCatQOL.Runtime.State.MasterTickerEnabled = false
	muteCatQOL.Runtime.Tickers.Master = nil
end

-- ============================================================ --
-- Error Frame Filtering                                         --
-- ============================================================ --
function muteCatQOL:ApplyErrorMessageFilter()
	if (muteCatQOL.Runtime.Hooks.ErrorFilterApplied) then
		return
	end
	if (UIErrorsFrame == nil or UIErrorsFrame.GetScript == nil or UIErrorsFrame.SetScript == nil) then
		return
	end

	local originalHandler = UIErrorsFrame:GetScript("OnEvent")
	if (type(originalHandler) ~= "function") then
		return
	end

	muteCatQOL.Runtime.State.OriginalUIErrorsOnEvent = originalHandler
	UIErrorsFrame:SetScript("OnEvent", function(self, event, id, err, ...)
		if (event == "UI_INFO_MESSAGE") then
			return originalHandler(self, event, id, err, ...)
		end
		if (event ~= "UI_ERROR_MESSAGE") then
			return originalHandler(self, event, id, err, ...)
		end

		-- Keep a small allowlist of important messages (Leatrix-style behavior).
		if (
			err == ERR_INV_FULL or
			err == ERR_QUEST_LOG_FULL or
			err == ERR_RAID_GROUP_ONLY or
			err == ERR_PARTY_LFG_BOOT_LIMIT or
			err == ERR_PARTY_LFG_BOOT_DUNGEON_COMPLETE or
			err == ERR_PARTY_LFG_BOOT_IN_COMBAT or
			err == ERR_PARTY_LFG_BOOT_IN_PROGRESS or
			err == ERR_PARTY_LFG_BOOT_LOOT_ROLLS or
			err == ERR_PARTY_LFG_TELEPORT_IN_COMBAT or
			err == ERR_PET_SPELL_DEAD or
			err == ERR_PLAYER_DEAD or
			err == ERR_UNIT_IS_DEAD or
			err == SPELL_FAILED_TARGET_NO_POCKETS or
			err == ERR_ALREADY_PICKPOCKETED
		) then
			return originalHandler(self, event, id, err, ...)
		end
		if (type(err) == "string") then
			local pattern = format(ERR_PARTY_LFG_BOOT_NOT_ELIGIBLE_S, ".+")
			if (err:find(pattern)) then
				return originalHandler(self, event, id, err, ...)
			end
		end

		-- Suppress all other UI error messages.
		return
	end)

	if (UIParent ~= nil and UIParent.UnregisterEvent ~= nil) then
		pcall(UIParent.UnregisterEvent, UIParent, "PING_SYSTEM_ERROR")
	end

	muteCatQOL.Runtime.Hooks.ErrorFilterApplied = true
end

-- ============================================================ --
-- QoL CVars (Combat Text, Camera, UI)                          --
-- ============================================================ --
function muteCatQOL:ApplyDefaultCVars()
	local desiredCVars = {
		-- Floating Combat Text
		["enableFloatingCombatText"] = "0",
		["floatingCombatTextCombatDamage"] = "0",
		["floatingCombatTextCombatHealing"] = "0",
		["floatingCombatTextPetMeleeDamage"] = "0",
		["floatingCombatTextPetSpellDamage"] = "0",
		["floatingCombatTextAuras"] = "0",
		["floatingCombatTextCombatState"] = "0",
		["floatingCombatTextDodgeParryMiss"] = "0",
		["floatingCombatTextDamageReduction"] = "0",
		["floatingCombatTextReactives"] = "0",
		["floatingCombatTextFriendlyHealers"] = "0",
		["floatingCombatTextComboPoints"] = "0",
		["floatingCombatTextEnergyGains"] = "0",
		["floatingCombatTextPeriodicEnergyGains"] = "0",
		["floatingCombatTextHonorGains"] = "0",
		["floatingCombatTextRepChanges"] = "0",
		["floatingCombatTextLowManaHealth"] = "0",
		["floatingCombatTextCombatDamage_v2"] = "0",
		["floatingCombatTextCombatHealing_v2"] = "0",
		["floatingCombatTextPetMeleeDamage_v2"] = "0",
		["floatingCombatTextPetSpellDamage_v2"] = "0",
		["floatingCombatTextAuras_v2"] = "0",
		["floatingCombatTextCombatState_v2"] = "0",
		["floatingCombatTextDodgeParryMiss_v2"] = "0",
		["floatingCombatTextDamageReduction_v2"] = "0",
		["floatingCombatTextReactives_v2"] = "0",
		["floatingCombatTextFriendlyHealers_v2"] = "0",
		["floatingCombatTextComboPoints_v2"] = "0",
		["floatingCombatTextEnergyGains_v2"] = "0",
		["floatingCombatTextPeriodicEnergyGains_v2"] = "0",
		["floatingCombatTextHonorGains_v2"] = "0",
		["floatingCombatTextRepChanges_v2"] = "0",
		["floatingCombatTextLowManaHealth_v2"] = "0",

		-- Camera QoL
		["cameraReduceUnexpectedMovement"] = "1",
		["cameraYawSmoothSpeed"] = "180",
		["cameraPitchSmoothSpeed"] = "180",
		["cameraIndirectOffset"] = "0",
		["test_cameraDynamicPitch"] = "0",
		["cameraIndirectVisibility"] = "1",

		-- Interface / UI
		["AutoPushSpellToActionBar"] = "0",
		["UnitNamePlayerGuild"] = "0",
		["UnitNamePlayerPVPTitle"] = "0",
		["UnitNameGuildTitle"] = "0",
		["ResampleAlwaysSharpen"] = "1",
	}

	for cvar, value in pairs(desiredCVars) do
		pcall(SetCVar, cvar, value)
	end
end

function muteCatQOL:PLAYER_LOGIN()
	muteCatQOL:ApplyDefaultCVars()
	C_Timer.After(0, function()
		muteCatQOL:ApplyDefaultCVars()
	end)
end

function muteCatQOL:PLAYER_ENTERING_WORLD()
	muteCatQOL:ApplyDefaultCVars()
	C_Timer.After(1, function()
		muteCatQOL:ApplyDefaultCVars()
	end)
end

-- ============================================================ --
-- Main Initialization                                           --
-- ============================================================ --
function muteCatQOL:MainFunction()
	muteCatQOL.DesaturationCurve = C_CurveUtil.CreateCurve()
	muteCatQOL.DesaturationCurve:SetType(Enum.LuaCurveType.Step)
	muteCatQOL.DesaturationCurve:AddPoint(0, 0)
	muteCatQOL.DesaturationCurve:AddPoint(0.001, 1)

	muteCatQOL.DesaturationCurveGCD = C_CurveUtil.CreateCurve()
	muteCatQOL.DesaturationCurveGCD:SetType(Enum.LuaCurveType.Step)
	muteCatQOL.DesaturationCurveGCD:AddPoint(0, 0)
	muteCatQOL.DesaturationCurveGCD:AddPoint(muteCatQOL.GCD, 1)

	if not(muteCatQOL.Runtime.IsHooked) then
		ActionButton_muteCatQOL_UpdateCheck = muteCatQOL.GOCActionButtonUpdateCheck
		PetActionButton_muteCatQOL_UpdateCheck = muteCatQOL.GOCPetActionButtonUpdateCheck

		local events = {
			"SPELL_UPDATE_COOLDOWN",
			"UPDATE_SHAPESHIFT_FORM",
			"UPDATE_SHAPESHIFT_FORMS",
			"PLAYER_ENTERING_WORLD",
			"PLAYER_LOGIN",
			"PLAYER_REGEN_ENABLED",
			"ADDON_LOADED"
		}

		for _, event in ipairs(events) do
			if not(muteCatQOL.frame:IsEventRegistered(event)) then
				muteCatQOL.frame:RegisterEvent(event)
			end
		end

		muteCatQOL:HookGOCActionButtons()
		muteCatQOL:HookGOCPetActionButtons()
		muteCatQOL:UpdateStanceBarVisibility()
		muteCatQOL:InitializeServiceChannelAutoLeave()
		muteCatQOL:InitializeWorldMapMover()
		
		muteCatQOL:InitializeBarMouseoverBehavior()
		muteCatQOL:InitializeVisibilityEvents()
		muteCatQOL:InitializeUIUtilities()
		muteCatQOL:InitializeAutomation()
		muteCatQOL:InitializeConsumableMacro()
		muteCatQOL:InitializeFishingHelper()
		muteCatQOL:InitializeEditModeCoords()
		muteCatQOL:InitializeATTMouseover()

		muteCatQOL:InitializeMasterTicker()

		muteCatQOL.Runtime.IsHooked = true
	end
end

-- ============================================================ --
-- Master Ticker                                                 --
-- ============================================================ --
function muteCatQOL:OnMasterTick()
	if self.UpdateBarMouseoverBehavior then self:UpdateBarMouseoverBehavior() end
	if self.UpdateManagedFrames then self:UpdateManagedFrames() end

	muteCatQOL.Runtime.State.TickCount = (muteCatQOL.Runtime.State.TickCount or 0) + 1
	if (muteCatQOL.Runtime.State.TickCount % 2 == 0) then
		if self.UpdateUIUtilities then self:UpdateUIUtilities() end
		if self.UpdateEditModeCoords then self:UpdateEditModeCoords() end
		if self.EnforceAutomationState then self:EnforceAutomationState() end
	end
end

function muteCatQOL:RequestMasterTickerBoost(duration)
	local now = GetTime()
	local untilTime = now + (tonumber(duration) or 0.6)
	local current = muteCatQOL.Runtime.State.MasterBoostUntil or 0
	if untilTime > current then
		muteCatQOL.Runtime.State.MasterBoostUntil = untilTime
	end
end

function muteCatQOL:ShouldUseFastMasterTick()
	if InCombatLockdown and InCombatLockdown() then
		return true
	end

	if self.IsEditModeActive and self:IsEditModeActive() then
		return true
	end

	local now = GetTime()
	local boostUntil = muteCatQOL.Runtime.State.MasterBoostUntil or 0
	if now < boostUntil then
		return true
	end

	local hideAt = muteCatQOL.Runtime.State.BuffBarHideAt
	if hideAt and now < (hideAt + 0.25) then
		return true
	end

	return false
end

function muteCatQOL:InitializeMasterTicker()
	if muteCatQOL.Runtime.State.MasterTickerEnabled then
		return
	end

	muteCatQOL.Runtime.State.MasterTickerEnabled = true
	muteCatQOL:RequestMasterTickerBoost(2.0)

	local function TickLoop()
		if not muteCatQOL.Runtime.State.MasterTickerEnabled then
			muteCatQOL.Runtime.Tickers.Master = nil
			return
		end

		muteCatQOL:OnMasterTick()

		local slow = muteCatQOL.Constants.UI.TickInterval or 0.2
		local fast = muteCatQOL.Constants.UI.FastTickInterval or 0.05
		local nextInterval = muteCatQOL:ShouldUseFastMasterTick() and fast or slow
		muteCatQOL.Runtime.Tickers.Master = C_Timer.After(nextInterval, TickLoop)
	end

	muteCatQOL.Runtime.Tickers.Master = C_Timer.After(0, TickLoop)
end
