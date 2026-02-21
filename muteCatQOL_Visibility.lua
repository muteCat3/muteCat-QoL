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
	if self:ShouldForceShowForCombatOrInstance() then
		return false
	end
	if self:IsClientSceneActive() then
		return true
	end
	if (C_ActionBar and C_ActionBar.HasOverrideActionBar and C_ActionBar.HasOverrideActionBar()) or UnitInVehicle("player") then
		return true
	end
	if IsMiniGameActive() then
		return true
	end
	if IsTravelStateActive() then
		return true
	end
	if IsResting and IsResting() then
		return true
	end
	return false
end

function muteCatQOL:ForceHideFrame(frame, hookKey, hardOnShowHide)
	if not frame then return end
	frame:SetAlpha(0)
	if frame.Hide then frame:Hide() end
	if frame.EnableMouse then frame:EnableMouse(false) end
	if muteCatQOL.Runtime and muteCatQOL.Runtime.Hooks and muteCatQOL.Runtime.Hooks[hookKey] then
		return
	end
	if hardOnShowHide and frame.SetScript and frame.Hide then
		frame:SetScript("OnShow", frame.Hide)
	elseif frame.HookScript then
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
