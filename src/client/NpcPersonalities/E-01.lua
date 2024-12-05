local module = {
    OnStep = {
		{ Function = "SearchForTarget", Parameters = { "Player", 20} },
		{ Function = "LookAtTarget", Parameters = { true, 0.5 } },

	},

	OnSpawn = {
		{ Function = "PlayAnimation", Parameters = { "Animation_Idle", 0.2, true } },
	},

	OnDeath = {
		{ Function = "PlaceNpcBody" },
		{ Function = "Destroy" },
	}
    -- TargetFound = {
	-- 	{ Function = "SwitchToState", Parameters = { "Attacking" } },
	-- 	{ Function = "MoveTowardsTarget" },
	-- },

	-- TargetLost = {
	-- 	{ Function = "SwitchToState", Parameters = { "Chasing" } },
	-- 	{ Function = "MoveTowardsTarget" },
	-- },
}

return module
