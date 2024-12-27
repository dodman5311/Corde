local module = {
	OnStep = {
		{ Function = "SearchForTarget", Parameters = { 10, 100 } },
		{ Function = "LookAtTarget", Parameters = { true, 0.015 } },
		{ Function = "MoveForwards", State = "Chasing", Parameters = { 0.05 } },
		{ Function = "StopMoving", State = "Idle" },
	},

	InCloseRange = {
		{
			Function = "MeleeAttack",
			Parameters = { 20, 1.5, 3, true },
		},

		Parameters = { 3.475 },
	},

	OnSpawn = {
		{ Function = "SwitchToState", Parameters = { "Idle" } },
		{ Function = "PlayAnimation", Parameters = { "Animation_Idle", 0.2, true } },
	},

	OnDeath = {
		{ Function = "Destroy" },
	},

	OnTargetFound = {
		{ Function = "SwitchToState", Parameters = { "Chasing" } },
	},

	OnMoved = {
		{ Function = "SetAnimationPlayback", Parameters = { "Animation_Walk", "Resume" } },
	},

	OnStopped = {
		{ Function = "SetAnimationPlayback", Parameters = { "Animation_Walk", "Pause" } },
	},

	OnTargetLost = {
		{ Function = "SwitchToState", Parameters = { "Idle" } },
	},

	OnStateChanged = {
		{ Function = "PlayAnimation", Parameters = { "Animation_Walk", 0.05, true }, State = "Chasing" },
	},
}

return module
