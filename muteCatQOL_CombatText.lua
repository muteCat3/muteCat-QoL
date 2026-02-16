local ipairs = ipairs

-- Based on current CVars exposed by AdvancedInterfaceOptions (TWW API).
muteCatQOL.CombatTextCVarsOff = {
	"enableCombatText",
	"enableFloatingCombatText",
	"floatingCombatTextCombatDamage",
	"floatingCombatTextCombatLogPeriodicSpells",
	"floatingCombatTextPetMeleeDamage",
	"floatingCombatTextPetSpellDamage",
	"floatingCombatTextCombatHealing",
	"floatingCombatTextCombatHealingAbsorbSelf",
	"floatingCombatTextCombatHealingAbsorbTarget",
	"floatingCombatTextDodgeParryMiss",
	"floatingCombatTextDamageReduction",
	"floatingCombatTextCombatState",
	"floatingCombatTextAuras",
	"floatingCombatTextReactives",
	"floatingCombatTextFriendlyHealers",
	"floatingCombatTextComboPoints",
	"floatingCombatTextLowManaHealth",
	"floatingCombatTextEnergyGains",
	"floatingCombatTextPeriodicEnergyGains",
	"floatingCombatTextHonorGains",
	"floatingCombatTextRepChanges",
	"floatingCombatTextAllSpellMechanics",
	"floatingCombatTextSpellMechanics",
	"floatingCombatTextSpellMechanicsOther",
	"enablePetBattleCombatText",
	"enablePetBattleFloatingCombatText",
}

function muteCatQOL:ApplyCombatTextHideCVars()
	if (SetCVar ~= nil) then
		for _, cvarName in ipairs(muteCatQOL.CombatTextCVarsOff) do
			pcall(SetCVar, cvarName, "0")
		end
	end

	if (CombatText ~= nil) then
		CombatText:Hide()
		if not(MUTECATQOL_COMBATTEXT_ONSHOW_HOOKED) then
			CombatText:HookScript("OnShow", function(self)
				self:Hide()
			end)
			MUTECATQOL_COMBATTEXT_ONSHOW_HOOKED = true
		end
	end

	if (CombatText_UpdateDisplayedMessages ~= nil) then
		pcall(CombatText_UpdateDisplayedMessages)
	end
end

function muteCatQOL:InitializeCombatTextHider()
	if (MUTECATQOL_COMBATTEXT_INITIALIZED) then
		return
	end

	if (UIParentLoadAddOn ~= nil) then
		pcall(UIParentLoadAddOn, "Blizzard_CombatText")
	end

	muteCatQOL:ApplyCombatTextHideCVars()
	C_Timer.After(0, function()
		muteCatQOL:ApplyCombatTextHideCVars()
	end)

	MUTECATQOL_COMBATTEXT_INITIALIZED = true
end
