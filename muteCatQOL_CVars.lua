local pairs = pairs

muteCatQOL.DefaultCVars = {
	-- camera tuning
	cameraReduceUnexpectedMovement = "1",
	cameraYawSmoothSpeed = "180",
	cameraPitchSmoothSpeed = "180",
	cameraIndirectOffset = "0",
	test_cameraDynamicPitch = "0",
	cameraIndirectVisibility = "1",

	-- user requested QoL
	AutoPushSpellToActionBar = "0",
	UnitNamePlayerGuild = "0",
	UnitNamePlayerPVPTitle = "0",
	UnitNameGuildTitle = "0",
	ResampleAlwaysSharpen = "1",
}

function muteCatQOL:ApplyDefaultCVars()
	if (SetCVar == nil) then
		return
	end
	for cvarName, cvarValue in pairs(muteCatQOL.DefaultCVars) do
		pcall(SetCVar, cvarName, cvarValue)
	end
end

function muteCatQOL:InitializeDefaultCVars()
	if (MUTECATQOL_CVARS_INITIALIZED) then
		return
	end
	muteCatQOL:ApplyDefaultCVars()
	MUTECATQOL_CVARS_INITIALIZED = true
end
