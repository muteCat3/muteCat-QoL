local _G = _G
local ipairs = ipairs
local pairs = pairs
local pcall = pcall
local math_max = math.max

local TRACKER_PROGRESS_BAR_TEXTURE_FALLBACK = "Interface\\TargetingFrame\\UI-StatusBar"

local RECT_BORDER_THICKNESS = 2
local RECT_BORDER_COLOR_R = 0
local RECT_BORDER_COLOR_G = 0
local RECT_BORDER_COLOR_B = 0
local RECT_BORDER_COLOR_A = 1

local TRACKER_BAR_HEIGHT_DELTA = 2
local TRACKER_BAR_TEXT_SIZE_DELTA = -2
local TRACKER_HEADER_TEXT_SIZE_DELTA = -2
local function GetChallengeModeBlockAncestor(frame)
	local current = frame
	while (current ~= nil) do
		if (current.TimerBG ~= nil and current.TimerBGBack ~= nil and current.StatusBar ~= nil) then
			return current
		end
		if (current.GetName ~= nil) then
			local currentName = current:GetName()
			if (type(currentName) == "string" and currentName:find("ChallengeModeBlock", 1, true) ~= nil) then
				return current
			end
		end
		if (current.GetParent ~= nil) then
			current = current:GetParent()
		else
			current = nil
		end
	end
	return nil
end

local function IsChallengeModeStatusBar(bar)
	return (GetChallengeModeBlockAncestor(bar) ~= nil)
end

local function HideTexture(texture)
	if (texture == nil) then
		return
	end
	texture:Hide()
	texture:SetAlpha(0)
end

local function ShowTexture(texture)
	if (texture == nil) then
		return
	end
	texture:SetAlpha(1)
	texture:Show()
end

local function ResolveDFSoftStatusbarTexture()
	if (muteCatQOL.TrackerProgressBarTexture ~= nil) then
		return muteCatQOL.TrackerProgressBarTexture
	end

	local texturePath = nil
	if (_G.LibStub ~= nil) then
		local lsm = _G.LibStub("LibSharedMedia-3.0", true)
		if (lsm ~= nil and lsm.Fetch ~= nil) then
			local ok, path = pcall(lsm.Fetch, lsm, "statusbar", "DF Soft", true)
			if (ok and type(path) == "string" and path ~= "") then
				texturePath = path
			else
				ok, path = pcall(lsm.Fetch, lsm, "statusbar", "DF soft", true)
				if (ok and type(path) == "string" and path ~= "") then
					texturePath = path
				end
			end
		end
	end

	if (texturePath == nil) then
		texturePath = TRACKER_PROGRESS_BAR_TEXTURE_FALLBACK
	end

	muteCatQOL.TrackerProgressBarTexture = texturePath
	return texturePath
end

local function ApplyHeaderTextStyle(fontString)
	if (fontString == nil) then
		return
	end

	if (fontString.GetFont ~= nil and fontString.SetFont ~= nil) then
		local fontPath = fontString:GetFont()
		if (fontString.muteCatQOLBaseFontSize == nil) then
			local _, baseSize = fontString:GetFont()
			fontString.muteCatQOLBaseFontSize = baseSize
		end
		if (fontPath ~= nil and fontString.muteCatQOLBaseFontSize ~= nil) then
			local targetSize = math_max(1, fontString.muteCatQOLBaseFontSize + TRACKER_HEADER_TEXT_SIZE_DELTA)
			fontString:SetFont(fontPath, targetSize, "THINOUTLINE")
		end
	end

	if (fontString.SetShadowOffset ~= nil) then
		fontString:SetShadowOffset(0, 0)
	end
	if (fontString.SetShadowColor ~= nil) then
		fontString:SetShadowColor(0, 0, 0, 0)
	end
end

local function HideScenarioProgressBarAtlases(bar)
	if (bar == nil) then
		return
	end

	-- Keep BarFrame textures visible so tracker progress bars retain their background.
	HideTexture(bar.IconBG)
	HideTexture(bar.BarGlow)
	HideTexture(bar.Sheen)
	HideTexture(bar.Starburst)
end
local MPLUS_HEADER_BG_ATLASES = {
	["ChallengeMode-TimerBG"] = true,
	["ChallengeMode-TimerBG-Back"] = true,
	["challengemode-timer"] = true,
	["ScenarioTrackerToast"] = true,
	["evergreen-scenario-trackerheader-final-filigree"] = true,
	["ScenarioTrackerToast-FinalFiligree"] = true,
}

local function HideScenarioHeaderBackgrounds(frame)
	if (frame == nil) then
		return
	end
	local challengeModeBlock = GetChallengeModeBlockAncestor(frame)
	if (challengeModeBlock ~= nil) then
		ShowTexture(challengeModeBlock.TimerBGBack)
		ShowTexture(challengeModeBlock.TimerBG)

		for _, region in ipairs({ challengeModeBlock:GetRegions() }) do
			if (region ~= nil and region.GetObjectType ~= nil and region:GetObjectType() == "Texture") then
				local atlas = nil
				if (region.GetAtlas ~= nil) then
					atlas = region:GetAtlas()
				end
				if (atlas == "ChallengeMode-TimerBG" or atlas == "ChallengeMode-TimerBG-Back" or atlas == "challengemode-timer") then
					ShowTexture(region)
				end
			end
		end
		return
	end

	HideTexture(frame.TimerBGBack)
	HideTexture(frame.TimerBG)
	HideTexture(frame.NormalBG)
	HideTexture(frame.FinalBG)
	HideTexture(frame.BG)
	HideTexture(frame.GoldCurlies)
	HideTexture(frame.GlowTexture)

	for _, region in ipairs({ frame:GetRegions() }) do
		if (region ~= nil and region.GetObjectType ~= nil and region:GetObjectType() == "Texture") then
			local atlas = nil
			if (region.GetAtlas ~= nil) then
				atlas = region:GetAtlas()
			end
			if (atlas ~= nil and MPLUS_HEADER_BG_ATLASES[atlas] == true) then
				HideTexture(region)
			end

		end
	end
end
local function EnsureRectBorder(bar)
	if (bar == nil) then
		return
	end

	local border = bar.muteCatQOLRectBorder
	if (border == nil) then
		border = CreateFrame("Frame", nil, bar)
		bar.muteCatQOLRectBorder = border
		border:SetFrameLevel((bar:GetFrameLevel() or 1) + 2)

		border.top = border:CreateTexture(nil, "OVERLAY")
		border.top:SetTexture("Interface\\Buttons\\WHITE8x8")

		border.bottom = border:CreateTexture(nil, "OVERLAY")
		border.bottom:SetTexture("Interface\\Buttons\\WHITE8x8")

		border.left = border:CreateTexture(nil, "OVERLAY")
		border.left:SetTexture("Interface\\Buttons\\WHITE8x8")

		border.right = border:CreateTexture(nil, "OVERLAY")
		border.right:SetTexture("Interface\\Buttons\\WHITE8x8")
	end

	border:ClearAllPoints()
	border:SetAllPoints(bar)

	border.top:ClearAllPoints()
	border.top:SetPoint("TOPLEFT", border, "TOPLEFT")
	border.top:SetPoint("TOPRIGHT", border, "TOPRIGHT")
	border.top:SetHeight(RECT_BORDER_THICKNESS)

	border.bottom:ClearAllPoints()
	border.bottom:SetPoint("BOTTOMLEFT", border, "BOTTOMLEFT")
	border.bottom:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT")
	border.bottom:SetHeight(RECT_BORDER_THICKNESS)

	border.left:ClearAllPoints()
	border.left:SetPoint("TOPLEFT", border, "TOPLEFT", 0, -RECT_BORDER_THICKNESS)
	border.left:SetPoint("BOTTOMLEFT", border, "BOTTOMLEFT", 0, RECT_BORDER_THICKNESS)
	border.left:SetWidth(RECT_BORDER_THICKNESS)

	border.right:ClearAllPoints()
	border.right:SetPoint("TOPRIGHT", border, "TOPRIGHT", 0, -RECT_BORDER_THICKNESS)
	border.right:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", 0, RECT_BORDER_THICKNESS)
	border.right:SetWidth(RECT_BORDER_THICKNESS)

	border.top:SetVertexColor(RECT_BORDER_COLOR_R, RECT_BORDER_COLOR_G, RECT_BORDER_COLOR_B, RECT_BORDER_COLOR_A)
	border.bottom:SetVertexColor(RECT_BORDER_COLOR_R, RECT_BORDER_COLOR_G, RECT_BORDER_COLOR_B, RECT_BORDER_COLOR_A)
	border.left:SetVertexColor(RECT_BORDER_COLOR_R, RECT_BORDER_COLOR_G, RECT_BORDER_COLOR_B, RECT_BORDER_COLOR_A)
	border.right:SetVertexColor(RECT_BORDER_COLOR_R, RECT_BORDER_COLOR_G, RECT_BORDER_COLOR_B, RECT_BORDER_COLOR_A)
	border:Show()
end

local function ApplyTrackerProgressBarStyle(progressFrame)
	if (progressFrame == nil) then
		return
	end

	local bar = progressFrame.Bar
	if (bar == nil and progressFrame.SetStatusBarTexture ~= nil) then
		bar = progressFrame
	end
	if (bar == nil) then
		return
	end

	if (IsChallengeModeStatusBar(bar)) then
		return
	end

	if (bar.SetStatusBarTexture ~= nil) then
		bar:SetStatusBarTexture(ResolveDFSoftStatusbarTexture())
	end

	if (bar.GetHeight ~= nil and bar.SetHeight ~= nil) then
		if (bar.muteCatQOLBaseHeight == nil) then
			bar.muteCatQOLBaseHeight = bar:GetHeight()
		end
		if (bar.muteCatQOLBaseHeight ~= nil and bar.muteCatQOLBaseHeight > 0) then
			bar:SetHeight(bar.muteCatQOLBaseHeight + TRACKER_BAR_HEIGHT_DELTA)
		end
	end

	if (bar.Label ~= nil and bar.Label.GetFont ~= nil and bar.Label.SetFont ~= nil) then
		local fontPath, _, fontFlags = bar.Label:GetFont()
		if (bar.Label.muteCatQOLBaseFontSize == nil) then
			local _, baseSize = bar.Label:GetFont()
			bar.Label.muteCatQOLBaseFontSize = baseSize
		end
		if (fontPath ~= nil and bar.Label.muteCatQOLBaseFontSize ~= nil) then
			local targetSize = math_max(1, bar.Label.muteCatQOLBaseFontSize + TRACKER_BAR_TEXT_SIZE_DELTA)
			bar.Label:SetFont(fontPath, targetSize, fontFlags)
		end
	end

	HideTexture(bar.BorderLeft)
	HideTexture(bar.BorderRight)
	HideTexture(bar.BorderMid)
	HideTexture(bar.Border)
	HideScenarioProgressBarAtlases(bar)
	EnsureRectBorder(bar)

	if not(progressFrame.muteCatQOLProgressHookedShow) then
		progressFrame:HookScript("OnShow", function(self)
			ApplyTrackerProgressBarStyle(self)
		end)
		progressFrame.muteCatQOLProgressHookedShow = true
	end

	if not(bar.muteCatQOLProgressHookedShow) then
		bar:HookScript("OnShow", function()
			ApplyTrackerProgressBarStyle(progressFrame)
		end)
		bar.muteCatQOLProgressHookedShow = true
	end
end

local function ApplyTrackerProgressBarTable(tableRef)
	if (tableRef == nil) then
		return
	end
	for _, progressBar in pairs(tableRef) do
		ApplyTrackerProgressBarStyle(progressBar)
	end
end

local function ApplyQuestBlockHeaderVisuals(frame)
	if (frame == nil) then
		return
	end

	HideTexture(frame.HeaderGlow)
	HideTexture(frame.Glow)
	HideTexture(frame.Shine)

	if (frame.Header ~= nil) then
		HideTexture(frame.Header.Glow)
		HideTexture(frame.Header.Shine)
		ApplyHeaderTextStyle(frame.Header.Text)
	end

	ApplyHeaderTextStyle(frame.HeaderText)
	ApplyHeaderTextStyle(frame.Text)

	HideScenarioHeaderBackgrounds(frame)

end

local function IsInMythicPlus()
	return (C_ChallengeMode ~= nil and C_ChallengeMode.IsChallengeModeActive ~= nil and C_ChallengeMode.IsChallengeModeActive())
end

function muteCatQOL:UpdateMythicPlusQuestTrackerVisibility()
	local questTracker = _G["QuestObjectiveTracker"]
	if (questTracker == nil) then
		return
	end

	local inMythicPlus = IsInMythicPlus()
	if (inMythicPlus) then
		if (questTracker.muteCatQOLForcedMPlusHidden ~= true) then
			local collapsed = nil
			if (questTracker.IsCollapsed ~= nil) then
				local ok, value = pcall(questTracker.IsCollapsed, questTracker)
				if (ok) then
					collapsed = value
				end
			elseif (questTracker.collapsed ~= nil) then
				collapsed = questTracker.collapsed
			elseif (questTracker.isCollapsed ~= nil) then
				collapsed = questTracker.isCollapsed
			end
			questTracker.muteCatQOLPrevCollapsed = collapsed
		end

		if (questTracker.SetCollapsed ~= nil) then
			pcall(questTracker.SetCollapsed, questTracker, true)
		end
		questTracker:Hide()
		questTracker.muteCatQOLForcedMPlusHidden = true
	else
		if (questTracker.muteCatQOLForcedMPlusHidden) then
			if (questTracker.SetCollapsed ~= nil and questTracker.muteCatQOLPrevCollapsed ~= nil) then
				pcall(questTracker.SetCollapsed, questTracker, questTracker.muteCatQOLPrevCollapsed)
			end
			questTracker:Show()
			questTracker.muteCatQOLForcedMPlusHidden = false
			questTracker.muteCatQOLPrevCollapsed = nil
		end
	end

	if not(questTracker.muteCatQOLMPlusHookedShow) then
		questTracker:HookScript("OnShow", function(self)
			if (IsInMythicPlus()) then
				if (self.SetCollapsed ~= nil) then
					pcall(self.SetCollapsed, self, true)
				end
				self:Hide()
			end
		end)
		questTracker.muteCatQOLMPlusHookedShow = true
	end
end
local function TraverseChildren(frame, callback)
	if (frame == nil) then
		return
	end
	for _, child in ipairs({ frame:GetChildren() }) do
		callback(child)
		TraverseChildren(child, callback)
	end
end

function muteCatQOL:ApplyTrackerProgressBarsStyle()
	muteCatQOL:UpdateMythicPlusQuestTrackerVisibility()
	local tracker = _G["ObjectiveTrackerFrame"]
	if (tracker == nil) then
		return
	end

	if (tracker.MODULES ~= nil) then
		for _, module in pairs(tracker.MODULES) do
			if (module ~= nil) then
				ApplyTrackerProgressBarTable(module.usedProgressBars)
				ApplyTrackerProgressBarTable(module.usedTimerBars)
			end
		end
	end

	TraverseChildren(tracker, function(frame)
		if (frame ~= nil) then
			if (frame.Bar ~= nil or (frame.SetStatusBarTexture ~= nil and frame.BorderMid ~= nil)) then
				ApplyTrackerProgressBarStyle(frame)
			end
			ApplyQuestBlockHeaderVisuals(frame)
		end
	end)
end

function muteCatQOL:PLAYER_ENTERING_WORLD()
	muteCatQOL:UpdateStanceBarVisibility()
	muteCatQOL:ScheduleNoTrackerMinimizeApply()
	if (muteCatQOL.ScheduleServiceChannelLeave ~= nil) then
		muteCatQOL:ScheduleServiceChannelLeave()
	end
end

local function HideTrackerMinimizeButtonTextures(button)
	if (button == nil) then
		return
	end

	local texture = button:GetNormalTexture()
	if (texture ~= nil) then
		HideTexture(texture)
	end

	texture = button:GetPushedTexture()
	if (texture ~= nil) then
		HideTexture(texture)
	end

	texture = button:GetHighlightTexture()
	if (texture ~= nil) then
		HideTexture(texture)
	end

	if (button.GetDisabledTexture ~= nil) then
		texture = button:GetDisabledTexture()
		if (texture ~= nil) then
			HideTexture(texture)
		end
	end
end

local function HideRootTrackerHeader(header)
	if (header == nil) then
		return
	end

	HideTexture(header.Background)

	if (header.Text ~= nil) then
		HideTexture(header.Text)
	else
		for _, region in ipairs({ header:GetRegions() }) do
			if (region ~= nil and region.GetObjectType ~= nil and region:GetObjectType() == "FontString") then
				HideTexture(region)
			end
		end
	end

	if (header.MinimizeButton ~= nil) then
		header.MinimizeButton:Hide()
		header.MinimizeButton:EnableMouse(false)
		HideTrackerMinimizeButtonTextures(header.MinimizeButton)
	end
end

local function HideModuleHeaderTextures(header)
	if (header == nil) then
		return
	end

	HideTexture(header.Background)
	HideTexture(header.Shine)
	HideTexture(header.Glow)
	ApplyHeaderTextStyle(header.Text)

	for _, region in ipairs({ header:GetRegions() }) do
		if (region ~= nil and region.GetObjectType ~= nil and region:GetObjectType() == "Texture") then
			HideTexture(region)
		end
	end
end

local function HideObjectiveTrackerModuleHeaderTextures()
	local tracker = _G["ObjectiveTrackerFrame"]
	if (tracker == nil) then
		return
	end

	if (tracker.MODULES ~= nil) then
		for _, module in pairs(tracker.MODULES) do
			local header = module and module.Header or nil
			if (header ~= nil) then
				HideModuleHeaderTextures(header)
				if not(header.muteCatQOLHookedShow) then
					header:HookScript("OnShow", function(self)
						HideModuleHeaderTextures(self)
					end)
					header.muteCatQOLHookedShow = true
				end
			end
		end
	end

	for _, child in ipairs({ tracker:GetChildren() }) do
		if (child ~= nil and child.Header ~= nil) then
			HideModuleHeaderTextures(child.Header)
			if not(child.Header.muteCatQOLHookedShow) then
				child.Header:HookScript("OnShow", function(self)
					HideModuleHeaderTextures(self)
				end)
				child.Header.muteCatQOLHookedShow = true
			end
		end
	end
end

function muteCatQOL:ApplyNoTrackerMinimize()
	muteCatQOL:ApplyTrackerProgressBarsStyle()
	muteCatQOL:UpdateMythicPlusQuestTrackerVisibility()

	local tracker = _G["ObjectiveTrackerFrame"]
	local header = tracker ~= nil and tracker.Header or nil
	if (header ~= nil) then
		HideRootTrackerHeader(header)

		if not(header.muteCatQOLRootHookedShow) then
			header:HookScript("OnShow", function(self)
				HideRootTrackerHeader(self)
				muteCatQOL:ApplyTrackerProgressBarsStyle()
	muteCatQOL:UpdateMythicPlusQuestTrackerVisibility()
			end)
			header.muteCatQOLRootHookedShow = true
		end
	end

	HideObjectiveTrackerModuleHeaderTextures()
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

function muteCatQOL:CHALLENGE_MODE_START()
	muteCatQOL:ScheduleNoTrackerMinimizeApply()
end

function muteCatQOL:CHALLENGE_MODE_COMPLETED()
	muteCatQOL:ScheduleNoTrackerMinimizeApply()
end

function muteCatQOL:CHALLENGE_MODE_RESET()
	muteCatQOL:ScheduleNoTrackerMinimizeApply()
end

function muteCatQOL:SCENARIO_UPDATE()
	muteCatQOL:ScheduleNoTrackerMinimizeApply()
end


