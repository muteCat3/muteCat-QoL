local InCombatLockdown = InCombatLockdown
local IsMounted = IsMounted
local IsResting = IsResting
local UnitInVehicle = UnitInVehicle
local GetShapeshiftFormID = GetShapeshiftFormID

local function IsMiniGameActive()
	return (C_PetBattles and C_PetBattles.IsInBattle and C_PetBattles.IsInBattle()) or false
end

local function IsTravelStateActive()
	local shapeshiftFormID = GetShapeshiftFormID and GetShapeshiftFormID() or nil
	return IsMounted() or shapeshiftFormID == 3 or shapeshiftFormID == 29 or shapeshiftFormID == 27
end

function muteCatQOL:SetClientSceneActive(active)
	self.Runtime = self.Runtime or {}
	self.Runtime.State = self.Runtime.State or {}
	self.Runtime.State.ClientSceneActive = active and true or false
end

function muteCatQOL:IsClientSceneActive()
	return self.Runtime and self.Runtime.State and self.Runtime.State.ClientSceneActive or false
end

function muteCatQOL:ShouldForceShowForCombatOrInstance()
	if InCombatLockdown() then
		return true
	end
	local inInstance, instanceType = IsInInstance()
	return inInstance and (instanceType == "party" or instanceType == "raid")
end

function muteCatQOL:ShouldHideByVisibilityRules()
	self.Runtime = self.Runtime or {}
	self.Runtime.State = self.Runtime.State or {}

	if self:ShouldForceShowForCombatOrInstance() then
		self.Runtime.State.LinkedHUDHidden = false
		return false
	end
	if self:IsClientSceneActive() then
		self.Runtime.State.LinkedHUDHidden = true
		return true
	end
	if (C_ActionBar and C_ActionBar.HasOverrideActionBar and C_ActionBar.HasOverrideActionBar()) or UnitInVehicle("player") then
		self.Runtime.State.LinkedHUDHidden = true
		return true
	end
	if IsMiniGameActive() then
		self.Runtime.State.LinkedHUDHidden = true
		return true
	end
	if IsTravelStateActive() then
		self.Runtime.State.LinkedHUDHidden = true
		return true
	end
	if IsResting and IsResting() then
		self.Runtime.State.LinkedHUDHidden = true
		return true
	end
	self.Runtime.State.LinkedHUDHidden = false
	return false
end

function muteCatQOL:UpdateVisibilityState()
	return self:ShouldHideByVisibilityRules()
end

function muteCatQOL:IsLinkedHUDHidden()
	-- Always refresh the state when asked, to ensure third-party cooldown viewers/unitframes get fresh data.
	return self:ShouldHideByVisibilityRules()
end

function muteCatQOL:InitializeVisibilityEvents()
	if self.Runtime.Hooks.VisibilityEventsInitialized then return end
	
	local f = CreateFrame("Frame")
	local events = {
		"PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
		"PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA",
		"PLAYER_UPDATE_RESTING", "UPDATE_SHAPESHIFT_FORM",
		"UPDATE_OVERRIDE_ACTIONBAR", "UNIT_ENTERED_VEHICLE", "UNIT_EXITED_VEHICLE",
		"PLAYER_MOUNT_DISPLAY_CHANGED"
	}
	for _, e in ipairs(events) do f:RegisterEvent(e) end
	f:SetScript("OnEvent", function()
		muteCatQOL:ShouldHideByVisibilityRules()
		if muteCatQOL.QueueImmediateBarMouseoverUpdate then
			muteCatQOL:QueueImmediateBarMouseoverUpdate()
		end
	end)
	
	self.Runtime.Hooks.VisibilityEventsInitialized = true
end

function muteCatQOL:ForceHideFrame(frame, hookKey, hardOnShowHide)
	if not frame then return end
	frame:SetAlpha(0)
	if frame.Hide then frame:Hide() end
	if frame.EnableMouse then frame:EnableMouse(false) end
	if muteCatQOL.Runtime and muteCatQOL.Runtime.Hooks and muteCatQOL.Runtime.Hooks[hookKey] then
		return
	end
	if frame.HookScript then
		frame:HookScript("OnShow", function(self)
			self:SetAlpha(0)
			self:Hide()
			if self.EnableMouse then self:EnableMouse(false) end
		end)
	end
	if muteCatQOL.Runtime and muteCatQOL.Runtime.Hooks then
		muteCatQOL.Runtime.Hooks[hookKey] = true
	end
end
