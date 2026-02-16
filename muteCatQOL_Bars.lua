local _G = _G
local ipairs = ipairs
local InCombatLockdown = InCombatLockdown
local IsMounted = IsMounted
local IsInInstance = IsInInstance
local math_abs = math.abs
local HasVehicleActionBar = HasVehicleActionBar
local HasOverrideActionBar = HasOverrideActionBar
local HasTempShapeshiftActionBar = HasTempShapeshiftActionBar
local IsPossessBarVisible = IsPossessBarVisible

local function IsSpecialActionBarStateActive()
	if (HasVehicleActionBar ~= nil and HasVehicleActionBar()) then
		return true
	end
	if (HasOverrideActionBar ~= nil and HasOverrideActionBar()) then
		return true
	end
	if (HasTempShapeshiftActionBar ~= nil and HasTempShapeshiftActionBar()) then
		return true
	end
	if (IsPossessBarVisible ~= nil and IsPossessBarVisible()) then
		return true
	end
	return false
end

function muteCatQOL:BuildBarButtons(prefix, maxButtons)
	local buttons = {}
	for i = 1, maxButtons do
		local button = _G[prefix..i]
		if (button ~= nil) then
			buttons[#buttons + 1] = button
		end
	end
	return buttons
end

function muteCatQOL:IsAnyBarButtonMouseOver(buttons)
	for _, button in ipairs(buttons) do
		if (button ~= nil and button.IsMouseOver ~= nil and button:IsMouseOver()) then
			return true
		end
	end
	return false
end

function muteCatQOL:SetBarButtonsAlpha(config, alpha)
	if (config.currentAlpha == alpha) then
		return
	end
	for _, button in ipairs(config.buttons) do
		if (button ~= nil) then
			button:SetAlpha(alpha)
		end
	end
	config.lastAlpha = alpha
	config.currentAlpha = alpha
end

function muteCatQOL:UpdateBarButtonsAlphaWithHideDelay(config, targetAlpha, forceInstant, isMouseOver)
	if (forceInstant) then
		config.pendingFadeOutAt = nil
		muteCatQOL:SetBarButtonsAlpha(config, targetAlpha)
		return
	end

	if (config.currentAlpha == nil) then
		config.currentAlpha = config.lastAlpha or 1
	end

	if (isMouseOver or targetAlpha >= 1) then
		config.pendingFadeOutAt = nil
		if (config.currentAlpha ~= 1) then
			muteCatQOL:SetBarButtonsAlpha(config, 1)
		end
		return
	end

	local now = GetTime()
	local hideDelay = muteCatQOL.BarMouseoverHideDelay or 1.0
	if (config.pendingFadeOutAt == nil) then
		config.pendingFadeOutAt = now + hideDelay
	end
	if (now < config.pendingFadeOutAt) then
		if (config.currentAlpha ~= 1) then
			muteCatQOL:SetBarButtonsAlpha(config, 1)
		end
		return
	end

	if (config.mode == "showhide") then
		muteCatQOL:SetBarButtonsAlpha(config, targetAlpha)
		return
	end

	local delta = targetAlpha - config.currentAlpha
	if (math_abs(delta) <= 0.01) then
		muteCatQOL:SetBarButtonsAlpha(config, targetAlpha)
		return
	end

	local tick = muteCatQOL.BarMouseoverTickTime or 0.1
	local duration = muteCatQOL.BarMouseoverFadeOutDuration or 0.2
	local step = tick / duration
	if (step > 1) then
		step = 1
	end

	local newAlpha = config.currentAlpha + (delta * step)
	if ((delta > 0 and newAlpha > targetAlpha) or (delta < 0 and newAlpha < targetAlpha)) then
		newAlpha = targetAlpha
	end
	muteCatQOL:SetBarButtonsAlpha(config, newAlpha)
end

function muteCatQOL:UpdateBarMouseoverBehavior()
	if (MUTECATQOL_BAR_CONFIGS == nil) then
		return
	end

	local inCombat = InCombatLockdown()
	local mounted = IsMounted()
	local _, instanceType = IsInInstance()
	local keepVisibleInInstance = (instanceType == "party" or instanceType == "raid")
	local specialActionBarState = IsSpecialActionBarStateActive()

	local groupMouseOverState = {}
	for _, config in ipairs(MUTECATQOL_BAR_CONFIGS) do
		if (config.group ~= nil) then
			local current = groupMouseOverState[config.group]
			if not(current) then
				groupMouseOverState[config.group] = muteCatQOL:IsAnyBarButtonMouseOver(config.buttons)
			else
				groupMouseOverState[config.group] = current or muteCatQOL:IsAnyBarButtonMouseOver(config.buttons)
			end
		end
	end

	for _, config in ipairs(MUTECATQOL_BAR_CONFIGS) do
		local mode = config.mode
		local needsMouseOver = (mode == "showhide" or mode == "dim")
		local isMouseOver = false
		if (needsMouseOver) then
			if (config.group ~= nil) then
				isMouseOver = groupMouseOverState[config.group] or false
			else
				isMouseOver = muteCatQOL:IsAnyBarButtonMouseOver(config.buttons)
			end
		end

		local targetAlpha
		local forceInstant = false

		if (mode == "showhide") then
			targetAlpha = isMouseOver and 1 or 0
		elseif (mode == "dim") then
			if inCombat then
				targetAlpha = 1
				forceInstant = true
			else
				targetAlpha = isMouseOver and 1 or config.dimAlpha
			end
		elseif (mode == "combatdim") then
			targetAlpha = inCombat and 1 or (config.dimAlpha or 0.3)
			forceInstant = true
		elseif (mode == "combatonly") then
			targetAlpha = inCombat and 1 or 0
			forceInstant = true
		elseif (mode == "mounthide") then
			targetAlpha = (mounted and not keepVisibleInInstance and not specialActionBarState) and 0 or 1
			forceInstant = true
		else
			targetAlpha = 1
		end

		muteCatQOL:UpdateBarButtonsAlphaWithHideDelay(config, targetAlpha, forceInstant, isMouseOver)
	end
end

muteCatQOL.BarMouseoverHideDelay = 1.0
muteCatQOL.BarMouseoverFadeOutDuration = 0.2
muteCatQOL.BarMouseoverTickTime = 0.1

function muteCatQOL:InitializeBarMouseoverBehavior()
	if (MUTECATQOL_BAR_CONFIGS == nil) then
		MUTECATQOL_BAR_CONFIGS = {
			{ id = 1, mode = "showhide", group = "main123", buttons = muteCatQOL:BuildBarButtons("ActionButton", 12), lastAlpha = nil },
			{ id = 2, mode = "showhide", group = "main123", buttons = muteCatQOL:BuildBarButtons("MultiBarBottomLeftButton", 12), lastAlpha = nil },
			{ id = 3, mode = "showhide", group = "main123", buttons = muteCatQOL:BuildBarButtons("MultiBarBottomRightButton", 12), lastAlpha = nil },
			{ id = 4, mode = "combatdim", dimAlpha = 0.3, buttons = muteCatQOL:BuildBarButtons("MultiBarRightButton", 12), lastAlpha = nil },
			{ id = 5, mode = "showhide", buttons = muteCatQOL:BuildBarButtons("MultiBarLeftButton", 12), lastAlpha = nil },
			{ id = 6, mode = "mounthide", buttons = muteCatQOL:BuildBarButtons("MultiBar5Button", 12), lastAlpha = nil },
			{ id = 7, mode = "mounthide", buttons = muteCatQOL:BuildBarButtons("MultiBar6Button", 12), lastAlpha = nil },
			{ id = 8, mode = "mounthide", buttons = muteCatQOL:BuildBarButtons("MultiBar7Button", 12), lastAlpha = nil },
		}
	end

	if (MUTECATQOL_BAR_MOUSEOVER_TICKER == nil) then
		MUTECATQOL_BAR_MOUSEOVER_TICKER = C_Timer.NewTicker(muteCatQOL.BarMouseoverTickTime or 0.1, function()
			muteCatQOL:UpdateBarMouseoverBehavior()
		end)
	end
	muteCatQOL:UpdateBarMouseoverBehavior()
end
