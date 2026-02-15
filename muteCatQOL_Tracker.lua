local _G = _G
local ipairs = ipairs
function muteCatQOL:PLAYER_ENTERING_WORLD()
	muteCatQOL:UpdateStanceBarVisibility()
	muteCatQOL:ScheduleNoTrackerMinimizeApply()
	if (muteCatQOL.ScheduleServiceChannelLeave ~= nil) then
		muteCatQOL:ScheduleServiceChannelLeave()
	end
end

function muteCatQOL:HideTrackerMinimizeButtonTextures(button)
	if (button == nil) then
		return
	end
	local texture = button:GetNormalTexture()
	if (texture ~= nil) then
		texture:Hide()
		texture:SetAlpha(0)
	end
	texture = button:GetPushedTexture()
	if (texture ~= nil) then
		texture:Hide()
		texture:SetAlpha(0)
	end
	texture = button:GetHighlightTexture()
	if (texture ~= nil) then
		texture:Hide()
		texture:SetAlpha(0)
	end
	if (button.GetDisabledTexture ~= nil) then
		texture = button:GetDisabledTexture()
		if (texture ~= nil) then
			texture:Hide()
			texture:SetAlpha(0)
		end
	end
end

function muteCatQOL:ApplyNoTrackerMinimize()
	local tracker = _G["ObjectiveTrackerFrame"]
	local header = tracker ~= nil and tracker.Header or nil
	if (header == nil) then
		return
	end

	if (header.Background ~= nil) then
		header.Background:Hide()
		header.Background:SetAlpha(0)
	end

	if (header.Text ~= nil) then
		header.Text:Hide()
		header.Text:SetAlpha(0)
	else
		for _, region in ipairs({ header:GetRegions() }) do
			if (region ~= nil and region.GetObjectType ~= nil and region:GetObjectType() == "FontString") then
				region:Hide()
				region:SetAlpha(0)
			end
		end
	end

	if (header.MinimizeButton ~= nil) then
		local button = header.MinimizeButton
		button:Hide()
		button:EnableMouse(false)
		muteCatQOL:HideTrackerMinimizeButtonTextures(button)
		if not(button.muteCatQOLHookedShow) then
			button:HookScript("OnShow", function(self)
				self:Hide()
				self:EnableMouse(false)
				muteCatQOL:HideTrackerMinimizeButtonTextures(self)
			end)
			button.muteCatQOLHookedShow = true
		end
	end

	if not(header.muteCatQOLHookedShow) then
		header:HookScript("OnShow", function(self)
			if (self.Background ~= nil) then
				self.Background:Hide()
				self.Background:SetAlpha(0)
			end
			if (self.Text ~= nil) then
				self.Text:Hide()
				self.Text:SetAlpha(0)
			else
				for _, region in ipairs({ self:GetRegions() }) do
					if (region ~= nil and region.GetObjectType ~= nil and region:GetObjectType() == "FontString") then
						region:Hide()
						region:SetAlpha(0)
					end
				end
			end
			if (self.MinimizeButton ~= nil) then
				self.MinimizeButton:Hide()
				self.MinimizeButton:EnableMouse(false)
				muteCatQOL:HideTrackerMinimizeButtonTextures(self.MinimizeButton)
			end
		end)
		header.muteCatQOLHookedShow = true
	end
end

function muteCatQOL:ScheduleNoTrackerMinimizeApply()
	if (MUTECATQOL_NOTRACKER_TIMER0 == nil) then
		MUTECATQOL_NOTRACKER_TIMER0 = true
		C_Timer.After(0, function()
			MUTECATQOL_NOTRACKER_TIMER0 = nil
			muteCatQOL:ApplyNoTrackerMinimize()
		end)
	end
	if (MUTECATQOL_NOTRACKER_TIMER02 == nil) then
		MUTECATQOL_NOTRACKER_TIMER02 = true
		C_Timer.After(0.2, function()
			MUTECATQOL_NOTRACKER_TIMER02 = nil
			muteCatQOL:ApplyNoTrackerMinimize()
		end)
	end
	if (MUTECATQOL_NOTRACKER_TIMER1 == nil) then
		MUTECATQOL_NOTRACKER_TIMER1 = true
		C_Timer.After(1, function()
			MUTECATQOL_NOTRACKER_TIMER1 = nil
			muteCatQOL:ApplyNoTrackerMinimize()
		end)
	end
end

function muteCatQOL:PLAYER_LOGIN()
	muteCatQOL:ScheduleNoTrackerMinimizeApply()
	if (muteCatQOL.ScheduleServiceChannelLeave ~= nil) then
		muteCatQOL:ScheduleServiceChannelLeave()
	end
end

function muteCatQOL:QUEST_LOG_UPDATE()
	muteCatQOL:ScheduleNoTrackerMinimizeApply()
end

function muteCatQOL:ZONE_CHANGED_NEW_AREA()
	muteCatQOL:ScheduleNoTrackerMinimizeApply()
end

function muteCatQOL:UI_SCALE_CHANGED()
	muteCatQOL:ScheduleNoTrackerMinimizeApply()
end


