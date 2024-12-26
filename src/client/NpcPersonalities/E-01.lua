local module = {
	OnStep = {
		{ Function = "SearchForTarget", Parameters = { 20 } },
		{ Function = "LookAtTarget", Parameters = { true, 0.05 } },
		{ Function = "MoveForwards", State = "Chasing", Parameters = { 0.05 } },
		{ Function = "StopMoving", State = "Idle" },
	},

	InCloseRange = {
		{
			Function = "MeleeAttack",
			Parameters = { 1, 0.5, true },
		},

		Parameters = { 2 },
	},

	OnSpawn = {
		{ Function = "SwitchToState", Parameters = { "Idle" } },
		{ Function = "PlayAnimation", Parameters = { "Animation_Idle", 0.2, true } },
	},

	OnDeath = {
		--{ Function = "PlaceNpcBody" },
		{ Function = "Destroy" },
	},
	OnTargetFound = {
		{ Function = "SwitchToState", Parameters = { "Chasing" } },
		{ Function = "PlayAnimation", Parameters = { "Animation_Walk", 0.05, true } },
	},

	OnMoved = {
		{ Function = "SetAnimationPlayback", Parameters = { "Animation_Walk", "Resume" } },
	},

	OnStopped = {
		{ Function = "SetAnimationPlayback", Parameters = { "Animation_Walk", "Pause" } },
	},

	OnTargetLost = {
		{ Function = "SwitchToState", Parameters = { "Idle" } },
		--{ Function = "MoveTowardsTarget" },
	},
}

return module
