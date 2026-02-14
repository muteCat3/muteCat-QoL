local _G = _G
local GetShapeshiftForm = GetShapeshiftForm
local GetShapeshiftFormInfo = GetShapeshiftFormInfo
local GetNumShapeshiftForms = GetNumShapeshiftForms
local InCombatLockdown = InCombatLockdown
local RegisterStateDriver = RegisterStateDriver
local UnregisterStateDriver = UnregisterStateDriver
function muteCatQOL:ShouldHideStanceBar()
	local activeFormIndex = GetShapeshiftForm()
	if (activeFormIndex == nil or activeFormIndex == 0) then
		return false
	end
	if (muteCatQOL.HideStanceBarOnFormSpellID ~= nil) then
		local _, _, _, activeFormSpellID = GetShapeshiftFormInfo(activeFormIndex)
		return activeFormSpellID == muteCatQOL.HideStanceBarOnFormSpellID
	end
	if (muteCatQOL.HideStanceBarOnFormIndex ~= nil) then
		return activeFormIndex == muteCatQOL.HideStanceBarOnFormIndex
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
			if (formSpellID == muteCatQOL.HideStanceBarOnFormSpellID) then
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

	if shouldHide then
		stanceFrame:SetAlpha(0)
	else
		stanceFrame:SetAlpha(1)
	end

	if not(MUTECATQOL_STANCEBAR_ONSHOW_HOOKED) then
		stanceFrame:HookScript("OnShow", function(self)
			if muteCatQOL:ShouldHideStanceBar() then
				self:SetAlpha(0)
			else
				self:SetAlpha(1)
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