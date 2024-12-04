local module = {
    OnStep = {
		{ Function = "SearchForTarget", Parameters = { "Player", 200} },
		{ Function = "LookAtTarget", Parameters = { true } },

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
