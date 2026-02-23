local _G = _G

function muteCatQOL:EnsureDB()
	if (muteCatQOLDB == nil or type(muteCatQOLDB) ~= "table") then
		muteCatQOLDB = {}
	end
	if (muteCatQOLDB.worldMap == nil or type(muteCatQOLDB.worldMap) ~= "table") then
		muteCatQOLDB.worldMap = {}
	end
	if (muteCatQOLDB.worldMap.locked == nil) then
		muteCatQOLDB.worldMap.locked = false
	end
	return muteCatQOLDB
end

function muteCatQOL:GetWorldMapFrame()
	return _G["WorldMapFrame"]
end

function muteCatQOL:IsWorldMapLocked()
	local db = muteCatQOL:EnsureDB()
	return db.worldMap.locked == true
end

function muteCatQOL:SetWorldMapLocked(isLocked)
	local db = muteCatQOL:EnsureDB()
	db.worldMap.locked = isLocked and true or false
	if (db.worldMap.locked) then
		muteCatQOL:SaveWorldMapPosition()
		muteCatQOL:ApplyWorldMapPosition()
		print("muteCat QOL: WorldMap locked")
	else
		print("muteCat QOL: WorldMap unlocked")
	end
end

function muteCatQOL:ApplyWorldMapPosition()
	local frame = muteCatQOL:GetWorldMapFrame()
	if (frame == nil) then
		return
	end
	local db = muteCatQOL:EnsureDB()
	local pos = db.worldMap.position
	if (pos == nil) then
		return
	end
	muteCatQOL.Runtime.State.ApplyingWorldMapPos = true
	frame:ClearAllPoints()
	frame:SetPoint(pos.point or "CENTER", UIParent, pos.relativePoint or "CENTER", pos.x or 0, pos.y or 0)
	muteCatQOL.Runtime.State.ApplyingWorldMapPos = nil
end

function muteCatQOL:SaveWorldMapPosition()
	local frame = muteCatQOL:GetWorldMapFrame()
	if (frame == nil) then
		return
	end
	local point, _, relativePoint, x, y = frame:GetPoint(1)
	if (point == nil) then
		return
	end
	local db = muteCatQOL:EnsureDB()
	db.worldMap.position = {
		point = point,
		relativePoint = relativePoint,
		x = x,
		y = y,
	}
end

function muteCatQOL:HookWorldMapHardLock(frame)
	if (frame == nil or muteCatQOL.Runtime.Hooks.WorldMapHardLock) then
		return
	end

	hooksecurefunc(frame, "SetPoint", function()
		if (muteCatQOL:IsWorldMapLocked() and not muteCatQOL.Runtime.State.ApplyingWorldMapPos) then
			muteCatQOL:ApplyWorldMapPosition()
		end
	end)
	hooksecurefunc(frame, "ClearAllPoints", function()
		if (muteCatQOL:IsWorldMapLocked() and not muteCatQOL.Runtime.State.ApplyingWorldMapPos) then
			muteCatQOL:ApplyWorldMapPosition()
		end
	end)

	muteCatQOL.Runtime.Hooks.WorldMapHardLock = true
end

function muteCatQOL:HookWorldMapPositionPersistence(frame)
	if (frame == nil or muteCatQOL.Runtime.Hooks.WorldMapPos) then
		return
	end

	frame:HookScript("OnShow", function(self)
		if (muteCatQOL:IsWorldMapLocked() and not muteCatQOL.Runtime.State.WorldMapFirstShowDone) then
			self:SetAlpha(0)
			muteCatQOL:ApplyWorldMapPosition()
			C_Timer.After(0, function()
				muteCatQOL:ApplyWorldMapPosition()
				if (self ~= nil) then
					self:SetAlpha(1)
				end
				muteCatQOL.Runtime.State.WorldMapFirstShowDone = true
			end)
			return
		end

		muteCatQOL:ApplyWorldMapPosition()
		C_Timer.After(0, function()
			muteCatQOL:ApplyWorldMapPosition()
		end)
	end)

	if (type(frame.SynchronizeDisplayState) == "function") then
		hooksecurefunc(frame, "SynchronizeDisplayState", function()
			muteCatQOL:ApplyWorldMapPosition()
		end)
	end

	muteCatQOL.Runtime.Hooks.WorldMapPos = true
end

function muteCatQOL:HookWorldMapDragSource(sourceFrame, worldMapFrame)
	if (sourceFrame == nil or worldMapFrame == nil) then
		return
	end
	if (muteCatQOL.Runtime.State.WorldMapDragSources == nil) then
		muteCatQOL.Runtime.State.WorldMapDragSources = {}
	end
	if (muteCatQOL.Runtime.State.WorldMapDragSources[sourceFrame]) then
		return
	end

	sourceFrame:RegisterForDrag("LeftButton")
	sourceFrame:HookScript("OnDragStart", function()
		if (muteCatQOL:IsWorldMapLocked()) then
			return
		end
		worldMapFrame:StartMoving()
	end)
	sourceFrame:HookScript("OnDragStop", function()
		worldMapFrame:StopMovingOrSizing()
		if (muteCatQOL:IsWorldMapLocked()) then
			muteCatQOL:ApplyWorldMapPosition()
			return
		end
		muteCatQOL:SaveWorldMapPosition()
	end)

	muteCatQOL.Runtime.State.WorldMapDragSources[sourceFrame] = true
end

function muteCatQOL:RegisterWorldMapCommands()
	if (muteCatQOL.Runtime.Hooks.WorldMapCommands) then
		return
	end
	SLASH_MUTECATQOL1 = "/mcqol"
	SLASH_MUTECATQOL2 = "/mutecatqol"
	SlashCmdList["MUTECATQOL"] = function(msg)
		local input = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
		if (input == "lock") then
			muteCatQOL:SetWorldMapLocked(true)
		elseif (input == "unlock") then
			muteCatQOL:SetWorldMapLocked(false)
		else
			print("muteCat QOL: /mcqol lock | /mcqol unlock")
		end
	end
	muteCatQOL.Runtime.Hooks.WorldMapCommands = true
end

function muteCatQOL:InitializeWorldMapMover()
	local frame = muteCatQOL:GetWorldMapFrame()
	muteCatQOL:RegisterWorldMapCommands()
	if (frame == nil) then
		return
	end

	muteCatQOL:EnsureDB()
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	frame:SetUserPlaced(true)
	frame.ignoreFramePositionManager = true
	muteCatQOL:ApplyWorldMapPosition()
	muteCatQOL:HookWorldMapPositionPersistence(frame)
	muteCatQOL:HookWorldMapHardLock(frame)

	local titleContainer = frame.BorderFrame and frame.BorderFrame.TitleContainer or frame.TitleContainer
	muteCatQOL:HookWorldMapDragSource(titleContainer, frame)
	muteCatQOL:HookWorldMapDragSource(frame, frame)
	muteCatQOL:HookWorldMapDragSource(_G["TomTomWorldFrame"], frame)
end

function muteCatQOL:ADDON_LOADED(addonName)
	if (addonName == "Blizzard_WorldMap") then
		muteCatQOL:InitializeWorldMapMover()
	end
	if (addonName == "TomTom") then
		muteCatQOL:InitializeWorldMapMover()
	end
	if (addonName == "Blizzard_EditMode") then
		muteCatQOL:InitializeEditModeCoords()
	end
	if (addonName == "LibEditMode") then
		muteCatQOL:InitializeEditModeCoords()
	end
end
