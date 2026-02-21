local _G = _G
local GetShapeshiftForm = GetShapeshiftForm
local GetShapeshiftFormInfo = GetShapeshiftFormInfo
local GetNumShapeshiftForms = GetNumShapeshiftForms
local InCombatLockdown = InCombatLockdown
local RegisterStateDriver = RegisterStateDriver
local UnregisterStateDriver = UnregisterStateDriver
-- Logic to determine if the stance bar should be visually hidden (Alpha 0)
function muteCatQOL:ShouldHideStanceBar()
	local activeFormIndex = GetShapeshiftForm()
	if (not activeFormIndex or muteCatQOL.SafeEqual(activeFormIndex, 0)) then
		return false
	end
	
	if (muteCatQOL.HideStanceBarOnFormSpellID ~= nil) then
		local _, _, _, activeFormSpellID = GetShapeshiftFormInfo(activeFormIndex)
		return muteCatQOL.SafeEqual(activeFormSpellID, muteCatQOL.HideStanceBarOnFormSpellID)
	end
	if (muteCatQOL.HideStanceBarOnFormIndex ~= nil) then
		return muteCatQOL.SafeEqual(activeFormIndex, muteCatQOL.HideStanceBarOnFormIndex)
	end
	return false
end

function muteCatQOL:GetTargetStanceFormIndex()
	if (muteCatQOL.HideStanceBarOnFormIndex ~= nil) then
		return muteCatQOL.HideStanceBarOnFormIndex
	end
	if (muteCatQOL.HideStanceBarOnFormSpellID ~= nil) then
		if (muteCatQOL.CachedTargetStanceSpellID == muteCatQOL.HideStanceBarOnFormSpellID and muteCatQOL.CachedTargetStanceFormIndex ~= nil) then
			return muteCatQOL.CachedTargetStanceFormIndex
		end
		local numForms = GetNumShapeshiftForms()
		for i = 1, numForms do
			local _, _, _, formSpellID = GetShapeshiftFormInfo(i)
			if (muteCatQOL.SafeEqual(formSpellID, muteCatQOL.HideStanceBarOnFormSpellID)) then
				muteCatQOL.CachedTargetStanceSpellID = muteCatQOL.HideStanceBarOnFormSpellID
				muteCatQOL.CachedTargetStanceFormIndex = i
				return i
			end
		end
		muteCatQOL.CachedTargetStanceSpellID = muteCatQOL.HideStanceBarOnFormSpellID
		muteCatQOL.CachedTargetStanceFormIndex = nil
	end
	return nil
end

function muteCatQOL:GetStanceDriverFrame()
	local frame = _G["StanceBarFrame"] or _G["StanceBar"] or _G["StanceBarContainer"]
	if (frame ~= nil) then
		return frame
	end
	local stanceButton1 = _G["StanceButton1"]
	if (stanceButton1 ~= nil and stanceButton1.GetParent ~= nil) then
		return stanceButton1:GetParent()
	end
	return nil
end

function muteCatQOL:UpdateStanceBarVisibility()
	local shouldHide = muteCatQOL:ShouldHideStanceBar()
	local stanceFrame = muteCatQOL:GetStanceDriverFrame()
	if (stanceFrame == nil) then
		return
	end

	local targetFormIndex = muteCatQOL:GetTargetStanceFormIndex()
	local visibilityMacro = "show"
	if (targetFormIndex ~= nil) then
		visibilityMacro = string.format("[form:%d] hide; show", targetFormIndex)
	end

	if not(InCombatLockdown()) then
		if (MUTECATQOL_STANCE_VISIBILITY_DRIVER ~= visibilityMacro or MUTECATQOL_STANCE_DRIVER_FRAME ~= stanceFrame) then
			if (MUTECATQOL_STANCE_DRIVER_FRAME ~= nil) then
				pcall(UnregisterStateDriver, MUTECATQOL_STANCE_DRIVER_FRAME, "visibility")
			end
			RegisterStateDriver(stanceFrame, "visibility", visibilityMacro)
			MUTECATQOL_STANCE_DRIVER_FRAME = stanceFrame
			MUTECATQOL_STANCE_VISIBILITY_DRIVER = visibilityMacro
		end
	end

	local targetAlpha = shouldHide and 0 or 1
	if muteCatQOL.SafeNotEqual(stanceFrame:GetAlpha(), targetAlpha) then
		stanceFrame:SetAlpha(targetAlpha)
	end

	if not(MUTECATQOL_STANCEBAR_ONSHOW_HOOKED) then
		stanceFrame:HookScript("OnShow", function(self)
			local h = muteCatQOL:ShouldHideStanceBar()
			local a = h and 0 or 1
			if muteCatQOL.SafeNotEqual(self:GetAlpha(), a) then
				self:SetAlpha(a)
			end
		end)
		MUTECATQOL_STANCEBAR_ONSHOW_HOOKED = true
	end
end

function muteCatQOL:UPDATE_SHAPESHIFT_FORM()
	muteCatQOL:UpdateStanceBarVisibility()
end

function muteCatQOL:UPDATE_SHAPESHIFT_FORMS()
	muteCatQOL.CachedTargetStanceFormIndex = nil
	muteCatQOL:UpdateStanceBarVisibility()
end
function muteCatQOL:PLAYER_REGEN_ENABLED()
	muteCatQOL:UpdateStanceBarVisibility()
end