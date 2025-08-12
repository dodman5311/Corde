local module = {
	OnStep = {
		{ Function = "SearchForTarget", Parameters = { 10, 135 } },
		{ Function = "LookAtPath", Parameters = { true, 0.05 } },
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

	Start = {
		{ Function = "SwitchToState", Parameters = { "Idle" } },
		{ Function = "PlayAnimation", Parameters = { "Animation_Idle", 0.2, true } },
	},

	OnDeath = {
		{ Function = "SwitchToState", Parameters = { "Dead" } },
		{ Function = "StopMoving" },
		{ Function = "SearchForTarget", Parameters = { 0 } },

		{ Function = "PlayAnimation", Parameters = { "Animation_Death", 0.05, false, true } },
		{
			Function = "Custom",
			Parameters = {
				function(npc)
					npc.Instance.Shadowbox.Transparency = 1
				end,
			},
		},
		{ Function = "Emit", Parameters = { "Dust", 25 } },
		{ Function = "Destroy", Parameters = { 2 } },
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
		{ Function = "LookAtPath" },
		{ Function = "MoveForwards", Parameters = { 0.05 } },
	},

	OnStateChanged = {
		{ Function = "PlayAnimation", Parameters = { "Animation_Walk", 0.05, true }, State = "Chasing" },
	},
}

return module
