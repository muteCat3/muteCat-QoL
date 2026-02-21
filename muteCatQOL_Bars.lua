local _G = _G
local ipairs = ipairs
local InCombatLockdown = InCombatLockdown
local IsMounted = IsMounted

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
	if config.currentAlpha == alpha then return end
	for _, button in ipairs(config.buttons) do
		if (button ~= nil) then
			if (button:GetAlpha() ~= alpha) then
				button:SetAlpha(alpha)
			end
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
	if (math.abs(delta) <= 0.01) then
		muteCatQOL:SetBarButtonsAlpha(config, targetAlpha)
		return
	end

	local tick = muteCatQOL.BarMouseoverTickTime or 0.05
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

-- Reusable table to avoid creating a new one every tick
local _groupMouseOverState = {}

function muteCatQOL:UpdateBarMouseoverBehavior()
	wipe(_groupMouseOverState)
	local inInstance, instanceType = IsInInstance()
	local isExemptInstance = inInstance and (instanceType == "party" or instanceType == "raid" or instanceType == "pvp" or instanceType == "arena")

	for _, config in ipairs(muteCatQOL.Runtime.State.BarConfigs) do
		if (config.group ~= nil) then
			local current = _groupMouseOverState[config.group]
			if not(current) then
				_groupMouseOverState[config.group] = muteCatQOL:IsAnyBarButtonMouseOver(config.buttons)
			else
				_groupMouseOverState[config.group] = current or muteCatQOL:IsAnyBarButtonMouseOver(config.buttons)
			end
		end
	end

	for _, config in ipairs(muteCatQOL.Runtime.State.BarConfigs) do
		local isMouseOver
		if (config.group ~= nil) then
			isMouseOver = _groupMouseOverState[config.group] or false
		else
			isMouseOver = muteCatQOL:IsAnyBarButtonMouseOver(config.buttons)
		end
		local targetAlpha
		local forceInstant = false
		if (config.mode == "showhide") then
			targetAlpha = isMouseOver and 1 or 0
		elseif (config.mode == "dim") then
			if InCombatLockdown() then
				targetAlpha = 1
				forceInstant = true
			else
				targetAlpha = isMouseOver and 1 or config.dimAlpha
			end
		elseif (config.mode == "combatdim") then
			targetAlpha = InCombatLockdown() and 1 or (config.dimAlpha or 0.3)
			forceInstant = true
		elseif (config.mode == "combatonly") then
			targetAlpha = InCombatLockdown() and 1 or 0
			forceInstant = true
		elseif (config.mode == "mounthide") then
			targetAlpha = (IsMounted() and not isExemptInstance) and 0 or 1
			forceInstant = true
		elseif (config.mode == "visibilityrules") then
			targetAlpha = muteCatQOL:ShouldHideByVisibilityRules() and 0 or 1
			forceInstant = true
		else
			targetAlpha = 1
		end
		muteCatQOL:UpdateBarButtonsAlphaWithHideDelay(config, targetAlpha, forceInstant, isMouseOver)
	end
end

muteCatQOL.BarMouseoverHideDelay = 1.0
muteCatQOL.BarMouseoverFadeOutDuration = 0.2
muteCatQOL.BarMouseoverTickTime = 0.05

function muteCatQOL:InitializeBarMouseoverBehavior()
	if (muteCatQOL.Runtime.State.BarConfigs == nil) then
		muteCatQOL.Runtime.State.BarConfigs = {
			{ id = 1, mode = "showhide", group = "main123", buttons = muteCatQOL:BuildBarButtons("ActionButton", 12), lastAlpha = nil },
			{ id = 2, mode = "showhide", group = "main123", buttons = muteCatQOL:BuildBarButtons("MultiBarBottomLeftButton", 12), lastAlpha = nil },
			{ id = 3, mode = "showhide", group = "main123", buttons = muteCatQOL:BuildBarButtons("MultiBarBottomRightButton", 12), lastAlpha = nil },
			{ id = 4, mode = "visibilityrules", buttons = muteCatQOL:BuildBarButtons("MultiBarRightButton", 12), lastAlpha = nil },
			{ id = 5, mode = "showhide", buttons = muteCatQOL:BuildBarButtons("MultiBarLeftButton", 12), lastAlpha = nil },
			{ id = 6, mode = "showhide", buttons = muteCatQOL:BuildBarButtons("MultiBar5Button", 12), lastAlpha = nil },
			{ id = 7, mode = "showhide", buttons = muteCatQOL:BuildBarButtons("MultiBar6Button", 12), lastAlpha = nil },
			{ id = 8, mode = "visibilityrules", buttons = muteCatQOL:BuildBarButtons("MultiBar7Button", 12), lastAlpha = nil },
		}
	end
end
