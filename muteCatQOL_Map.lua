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
	MUTECATQOL_APPLYING_WORLDMAP_POS = true
	frame:ClearAllPoints()
	frame:SetPoint(pos.point or "CENTER", UIParent, pos.relativePoint or "CENTER", pos.x or 0, pos.y or 0)
	MUTECATQOL_APPLYING_WORLDMAP_POS = nil
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
	if (frame == nil or MUTECATQOL_WORLDMAP_HARDLOCK_HOOKED) then
		return
	end

	hooksecurefunc(frame, "SetPoint", function()
		if (muteCatQOL:IsWorldMapLocked() and not MUTECATQOL_APPLYING_WORLDMAP_POS) then
			muteCatQOL:ApplyWorldMapPosition()
		end
	end)
	hooksecurefunc(frame, "ClearAllPoints", function()
		if (muteCatQOL:IsWorldMapLocked() and not MUTECATQOL_APPLYING_WORLDMAP_POS) then
			muteCatQOL:ApplyWorldMapPosition()
		end
	end)

	MUTECATQOL_WORLDMAP_HARDLOCK_HOOKED = true
end

function muteCatQOL:HookWorldMapPositionPersistence(frame)
	if (frame == nil or MUTECATQOL_WORLDMAP_POS_HOOKED) then
		return
	end

	frame:HookScript("OnShow", function(self)
		if (muteCatQOL:IsWorldMapLocked() and not MUTECATQOL_WORLDMAP_FIRST_SHOW_DONE) then
			self:SetAlpha(0)
			muteCatQOL:ApplyWorldMapPosition()
			C_Timer.After(0, function()
				muteCatQOL:ApplyWorldMapPosition()
				if (self ~= nil) then
					self:SetAlpha(1)
				end
				MUTECATQOL_WORLDMAP_FIRST_SHOW_DONE = true
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

	MUTECATQOL_WORLDMAP_POS_HOOKED = true
end

function muteCatQOL:HookWorldMapDragSource(sourceFrame, worldMapFrame)
	if (sourceFrame == nil or worldMapFrame == nil) then
		return
	end
	if (MUTECATQOL_WORLDMAP_DRAG_SOURCES == nil) then
		MUTECATQOL_WORLDMAP_DRAG_SOURCES = {}
	end
	if (MUTECATQOL_WORLDMAP_DRAG_SOURCES[sourceFrame]) then
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

	MUTECATQOL_WORLDMAP_DRAG_SOURCES[sourceFrame] = true
end

function muteCatQOL:RegisterWorldMapCommands()
	if (MUTECATQOL_WORLD_MAP_COMMANDS_REGISTERED) then
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
	MUTECATQOL_WORLD_MAP_COMMANDS_REGISTERED = true
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
end