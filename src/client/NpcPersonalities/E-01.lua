local NpcStats = {
	BloodType = "Black",
	Health = 100,
	Walkspeed = 60,
}

local module = {
	Start = {
		{ Function = "SetStats", Parameters = { NpcStats } },
		{ Function = "SwitchToState", Parameters = { "Idle" } },
		{ Function = "PlayAnimation", Parameters = { "Animation_Idle", 0.2, true } },
	},

	OnStep = {
		{ Function = "SearchForTarget", Parameters = { 25, 135 } },

		--{ Function = "LookAtTarget", Parameters = { true, 0.05 }, State = "Attacking" },
		{ Function = "LookAtPath", Parameters = { true, 0.05 }, State = "Chasing" },

		{ Function = "MoveForwards", Parameters = { 0.05 }, State = "Chasing" },
		--{ Function = "MoveForwards", Parameters = { 0.05 }, State = "Attacking" },

		{ Function = "StopMoving", State = "Idle" },
	},

	InCloseRange = {
		{
			Function = "MeleeAttack",
			Parameters = { 20, 1.5, Vector2.new(2.5, 5), 3, true },
		},

		Parameters = { 8.75 },
	},

	-- OnCloseRangeEntered = {
	-- 	{ Function = "SwitchToState", Parameters = { "Attacking" } },
	-- },

	-- OnCloseRangeLeft = {
	-- 	{ Function = "SwitchToLastState" },
	-- },

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
