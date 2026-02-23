local string_gsub = string.gsub
local string_lower = string.lower

muteCatQOL.ServiceChannelNames = {
	["service"] = true,
	["services"] = true,
	["dienst"] = true,
	["dienste"] = true,
	["dienstleistungen"] = true,
}

function muteCatQOL:IsServiceChannelName(channelName)
	if (channelName == nil or channelName == "") then
		return false
	end

	local normalized = string_lower(channelName)
	for serviceTerm in pairs(muteCatQOL.ServiceChannelNames) do
		if normalized:find(serviceTerm, 1, true) then
			return true
		end
	end
	return false
end

function muteCatQOL:LeaveServiceChannel()
	if (GetChannelList == nil or LeaveChannelByName == nil) then
		return
	end

	local channels = { GetChannelList() }
	for i = 1, #channels, 3 do
		local channelName = channels[i + 1]
		if muteCatQOL:IsServiceChannelName(channelName) then
			pcall(LeaveChannelByName, channelName)
		end
	end
end

function muteCatQOL:ScheduleServiceChannelLeave()
	muteCatQOL:LeaveServiceChannel()

	C_Timer.After(2, function()
		muteCatQOL:LeaveServiceChannel()
	end)

	C_Timer.After(10, function()
		muteCatQOL:LeaveServiceChannel()
	end)
end

function muteCatQOL:InitializeServiceChannelAutoLeave()
	if (MUTECATQOL_SERVICE_CHANNEL_INIT) then
		return
	end

	muteCatQOL:ScheduleServiceChannelLeave()
	MUTECATQOL_SERVICE_CHANNEL_INIT = true
end
