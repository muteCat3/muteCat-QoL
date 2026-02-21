local _G = _G
local hooksecurefunc = hooksecurefunc

-- ============================================================ --
-- Error Filter                                                 --
-- ============================================================ --
local ignoredErrors = {}

local function AddIgnoredError(errorString)
	if errorString then
		ignoredErrors[errorString] = true
	end
end

local function CleanMsg(text)
	if type(text) ~= "string" then return "" end
	-- Strip color codes |c...|r
	local s = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
	-- Strip whitespace from ends
	s = s:gsub("^%s+", ""):gsub("%s+$", "")
	-- Strip trailing punctuation
	s = s:gsub("[%.!%?]+$", "")
	-- Strip leading %s formatter
	s = s:gsub("^%%s%s+", "")
	return s:lower()
end

local function PopulateIgnoredErrors()
	-- 1. Grab common Blizzard global strings
	local standardErrors = {
		"ERR_OUT_OF_RANGE", "ERR_ABILITY_COOLDOWN", "ERR_ATTACK_CHARMED", "ERR_ATTACK_CONFUSED",
		"ERR_ATTACK_DEAD", "ERR_ATTACK_FLEEING", "ERR_ATTACK_PACIFIED", "ERR_ATTACK_STUNNED",
		"ERR_AUTOFOLLOW_TOO_FAR", "ERR_BADATTACKFACING", "ERR_BADATTACKPOS", "ERR_ITEM_COOLDOWN",
		"ERR_NOT_IN_COMBAT", "ERR_SPELL_COOLDOWN", "ERR_SPELL_OUT_OF_RANGE", "ERR_GENERIC_NO_TARGET",
		"ERR_UNIT_NOT_IN_SIGHT", "ERR_UNIT_NOT_BEHIND", "ERR_INVALID_ATTACK_TARGET", 
		"ERR_SPELL_FAILED_ALREADY_AT_FULL_HEALTH", "ERR_SPELL_FAILED_INTERRUPTED",
		"ERR_SPELL_FAILED_INTERRUPTED_S", "ERR_SPELL_FAILED_MOVING", 
		"ERR_SPELL_FAILED_STUNNED", "ERR_SPELL_OUT_OF_RANGE", "ERR_GENERIC_NO_VALID_TARGETS"
	}
	
	for _, globalName in ipairs(standardErrors) do
		local str = _G[globalName]
		if str then
			ignoredErrors[CleanMsg(str)] = true
		end
	end
	
	-- 2. Hardcoded common German/English fallbacks (PVP/PVE Spam)
	local manualList = {
		"Außer Reichweite", "Out of range",
		"Fähigkeit ist noch nicht bereit", "Ability is not ready yet",
		"Nicht genügend Energie", "Not enough energy",
		"Nicht genügend Wut", "Not enough rage",
		"Nicht genügend Fokus", "Not enough focus",
		"Nicht genügend Mana", "Not enough mana",
		"Ziel muss vor Euch stehen", "Target must be in front of you",
		"Ihr seid zu weit entfernt", "You are too far away",
		"Ihr habt kein Ziel", "You have no target",
		"Ziel nicht in Sichtlinie", "Target not in line of sight",
		"Ziel ist nicht in Sichtlinie", "Target is not in line of sight",
		"Das könnt Ihr im Sitzen nicht tun", "Can't do that while sitting",
		"Das könnt Ihr während einer Bewegung nicht tun", "Can't do that while moving",
		"Ungültiges Ziel", "Invalid target",
		"Unterbrochen", "Interrupted",
		"Zauber unterbrochen", "Spell interrupted"
	}
	
	for _, str in ipairs(manualList) do
		ignoredErrors[CleanMsg(str)] = true
	end
end

local function MuteCat_AddMessage(self, text, ...)
	if not text then return end
	local cleaned = CleanMsg(text)
	if ignoredErrors[cleaned] then
		return
	end
	if self._oldAddMessage then
		return self._oldAddMessage(self, text, ...)
	end
end

function muteCatQOL:InitializeErrorFilter()
	self.Runtime = self.Runtime or {}
	self.Runtime.Hooks = self.Runtime.Hooks or {}

	PopulateIgnoredErrors()
	
	-- 1. Safely intercept UIErrorsFrame OnEvent (Leatrix Plus style - no taints)
	if UIErrorsFrame and not self.Runtime.Hooks.AutomationErrorFilter then
		local origOnEvent = UIErrorsFrame:GetScript("OnEvent")
		UIErrorsFrame:SetScript("OnEvent", function(self, event, arg1, arg2, ...)
			-- Depending on expansion, the message is arg1 or arg2
			local message = (event == "UI_ERROR_MESSAGE") and arg2 or arg1
			if message then
				local cleaned = CleanMsg(message)
				if ignoredErrors[cleaned] then
					return -- Silently filter out
				end
			end
			if origOnEvent then
				return origOnEvent(self, event, arg1, arg2, ...)
			end
		end)
		self.Runtime.Hooks.AutomationErrorFilter = true
	end

	-- 2. Force load Blizzard FCT so we can intercept it immediately
	if C_AddOns and C_AddOns.LoadAddOn then
		if not C_AddOns.IsAddOnLoaded("Blizzard_CombatText") then
			C_AddOns.LoadAddOn("Blizzard_CombatText")
		end
	end

	-- 3. Intercept FCT's AddMessage function
	-- We hook both the global and the CombatText frame if possible
	if _G.CombatText_AddMessage and not self.Runtime.Hooks.AutomationCombatTextFilter then
		local origCombatText_AddMessage = _G.CombatText_AddMessage
		_G.CombatText_AddMessage = function(text, ...)
			if text and type(text) == "string" then
				local cleaned = CleanMsg(text)
				if ignoredErrors[cleaned] then
					return -- Silently filter out
				end
			end
			return origCombatText_AddMessage(text, ...)
		end
		self.Runtime.Hooks.AutomationCombatTextFilter = true
	end
end

-- ============================================================ --
-- Easy Item Destroy                                            --
-- ============================================================ --
function muteCatQOL:InitializeEasyItemDestroy()
	-- Auto-fill "DELETE" for high quality items
	local function SkipDeleteConfirm(self)
		if self.editBox then
			self.editBox:SetText(DELETE_ITEM_CONFIRM_STRING)
		end
	end

	if StaticPopupDialogs["DELETE_GOOD_ITEM"] then
		hooksecurefunc(StaticPopupDialogs["DELETE_GOOD_ITEM"], "OnShow", SkipDeleteConfirm)
	end
	if StaticPopupDialogs["DELETE_GOOD_QUEST_ITEM"] then
		hooksecurefunc(StaticPopupDialogs["DELETE_GOOD_QUEST_ITEM"], "OnShow", SkipDeleteConfirm)
	end
end

---Aggressively enforces the hidden state of unwanted UI elements.
---Should be called on login, zone change, and leaving combat.
function muteCatQOL:EnforceAutomationState()
	-- Hide Zone Text
	muteCatQOL:ForceHideFrame(ZoneTextFrame, "ZoneTextFrameOnShow", true)
	muteCatQOL:ForceHideFrame(SubZoneTextFrame, "SubZoneTextFrameOnShow", true)
	muteCatQOL:ForceHideFrame(PVPTenantTextFrame, "PVPTenantTextFrameOnShow", true)
	muteCatQOL:ForceHideFrame(PVPInfoTextString, "PVPInfoTextStringOnShow", true)
	muteCatQOL:ForceHideFrame(PVPArenaTextString, "PVPArenaTextStringOnShow", true)
	muteCatQOL:ForceHideFrame(PVPTimerText, "PVPTimerTextOnShow", true)

	-- Talking Head Lockdown
	if TalkingHeadFrame then
		TalkingHeadFrame:UnregisterAllEvents()
		TalkingHeadFrame:Hide()
	end

	-- Boss Target Frames Lockdown
	if BossTargetFrameContainer then
		BossTargetFrameContainer:SetAlpha(0)
		BossTargetFrameContainer:SetScale(0.001)
	end
	for i = 1, 5 do
		local bf = _G["Boss"..i.."TargetFrame"]
		if bf then
			bf:SetAlpha(0)
		end
	end

	-- Keep this function lightweight because it can run frequently.
end

-- ============================================================ --
-- Utility: Fast Loot & Movie Skip                              --
-- ============================================================ --
function muteCatQOL:InitializeAutomation()
	-- Fast Loot
	local function FastLoot()
		if GetCVarBool("autoLootDefault") ~= IsModifiedClick("AUTOLOOT") then
			for i = GetNumLootItems(), 1, -1 do
				LootSlot(i)
			end
		end
	end
	local lootFrame = CreateFrame("Frame")
	lootFrame:RegisterEvent("LOOT_READY")
	lootFrame:SetScript("OnEvent", FastLoot)

	-- Movie Skip
	if MovieFrame then
		MovieFrame:HookScript("OnShow", function(self)
			if self:IsShown() then
				MovieFrame_OnMovieFinished(self)
			end
		end)
	end
	
	-- Talking Head Hider (Optional but recommended)
	if TalkingHeadFrame then
		hooksecurefunc(TalkingHeadFrame, "Show", function(self)
			self:Hide()
		end)
	end

	self:InitializeErrorFilter()
	self:InitializeEasyItemDestroy()
	
	-- Initial enforcement
	self:EnforceAutomationState()
end
