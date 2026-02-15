-- ============================================================ --
-- muteCat QOL                                                  --
-- ------------------------------------------------------------ --
-- Author: Ben                                                  --
-- Addon Version: 3.0.0                                         --
-- WoW Version: 12.0.1                                          --
-- License: GNU GENERAL PUBLIC LICENSE, Version 3, 29 June 2007 --
-- ============================================================ --

muteCatQOL = LibStub("AceAddon-3.0"):NewAddon("muteCatQOL")
muteCatQOL.frame = muteCatQOL.frame or CreateFrame("Frame", "muteCatQOLFrame")

function muteCatQOL:OnEvent(event, ...)
	if (muteCatQOL[event] ~= nil) then
		muteCatQOL[event](muteCatQOL, ...)
	end
end
muteCatQOL.frame:SetScript("OnEvent", muteCatQOL.OnEvent)

muteCatQOL.VERSION = "2.0.0"
muteCatQOL.GCD = 1.88
muteCatQOL.NUM_ACTIONBAR_BUTTONS = NUM_ACTIONBAR_BUTTONS or 12
muteCatQOL.NUM_PET_ACTION_SLOTS = NUM_PET_ACTION_SLOTS or 10
muteCatQOL.RelatedActionSpells = {
	[372608] = { 372610 },
	[372610] = { 372608 },
	[403092] = { 372608, 372610 },
	[425782] = { 372608, 372610 },
	[372606] = { 372608, 372610 }
}
muteCatQOL.RegisteredActionSpells = {}
muteCatQOL.HideStanceBarOnFormIndex = nil
muteCatQOL.HideStanceBarOnFormSpellID = 465

function muteCatQOL:OnInitialize()
	if NUM_ACTIONBAR_BUTTONS ~= nil then
		muteCatQOL.NUM_ACTIONBAR_BUTTONS = NUM_ACTIONBAR_BUTTONS
	end
	if NUM_PET_ACTION_SLOTS ~= nil then
		muteCatQOL.NUM_PET_ACTION_SLOTS = NUM_PET_ACTION_SLOTS
	end
end

function muteCatQOL:OnEnable()
	self:MainFunction()
end

function muteCatQOL:OnDisable()
	if (MUTECATQOL_BAR_MOUSEOVER_TICKER ~= nil) then
		MUTECATQOL_BAR_MOUSEOVER_TICKER:Cancel()
		MUTECATQOL_BAR_MOUSEOVER_TICKER = nil
	end
	if (MUTECATQOL_UI_TICKER ~= nil) then
		MUTECATQOL_UI_TICKER:Cancel()
		MUTECATQOL_UI_TICKER = nil
	end
end

function muteCatQOL:MainFunction()
	muteCatQOL.DesaturationCurve = C_CurveUtil.CreateCurve()
	muteCatQOL.DesaturationCurve:SetType(Enum.LuaCurveType.Step)
	muteCatQOL.DesaturationCurve:AddPoint(0, 0)
	muteCatQOL.DesaturationCurve:AddPoint(0.001, 1)

	muteCatQOL.DesaturationCurveGCD = C_CurveUtil.CreateCurve()
	muteCatQOL.DesaturationCurveGCD:SetType(Enum.LuaCurveType.Step)
	muteCatQOL.DesaturationCurveGCD:AddPoint(0, 0)
	muteCatQOL.DesaturationCurveGCD:AddPoint(muteCatQOL.GCD, 1)

	if not(MUTECATQOL_HOOKED) then
		ActionButton_muteCatQOL_UpdateCheck = muteCatQOL.GOCActionButtonUpdateCheck
		PetActionButton_muteCatQOL_UpdateCheck = muteCatQOL.GOCPetActionButtonUpdateCheck

		if not(muteCatQOL.frame:IsEventRegistered("SPELL_UPDATE_COOLDOWN")) then
			muteCatQOL.frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
		end
		if not(muteCatQOL.frame:IsEventRegistered("UPDATE_SHAPESHIFT_FORM")) then
			muteCatQOL.frame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
		end
		if not(muteCatQOL.frame:IsEventRegistered("UPDATE_SHAPESHIFT_FORMS")) then
			muteCatQOL.frame:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
		end
		if not(muteCatQOL.frame:IsEventRegistered("PLAYER_ENTERING_WORLD")) then
			muteCatQOL.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
		end
		if not(muteCatQOL.frame:IsEventRegistered("PLAYER_LOGIN")) then
			muteCatQOL.frame:RegisterEvent("PLAYER_LOGIN")
		end
		if not(muteCatQOL.frame:IsEventRegistered("QUEST_LOG_UPDATE")) then
			muteCatQOL.frame:RegisterEvent("QUEST_LOG_UPDATE")
		end
		if not(muteCatQOL.frame:IsEventRegistered("ZONE_CHANGED_NEW_AREA")) then
			muteCatQOL.frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
		end
		if not(muteCatQOL.frame:IsEventRegistered("UI_SCALE_CHANGED")) then
			muteCatQOL.frame:RegisterEvent("UI_SCALE_CHANGED")
		end
		if not(muteCatQOL.frame:IsEventRegistered("PLAYER_REGEN_ENABLED")) then
			muteCatQOL.frame:RegisterEvent("PLAYER_REGEN_ENABLED")
		end
		if not(muteCatQOL.frame:IsEventRegistered("ADDON_LOADED")) then
			muteCatQOL.frame:RegisterEvent("ADDON_LOADED")
		end

		muteCatQOL:HookGOCActionButtons()
		muteCatQOL:HookGOCPetActionButtons()
		muteCatQOL:UpdateStanceBarVisibility()
		muteCatQOL:InitializeBarMouseoverBehavior()
		muteCatQOL:ScheduleNoTrackerMinimizeApply()
		muteCatQOL:InitializeUIUtilities()
		muteCatQOL:InitializeDefaultCVars()
		muteCatQOL:InitializeCombatTextHider()
		muteCatQOL:InitializeWorldMapMover()
		MUTECATQOL_HOOKED = muteCatQOL or true
	end
end