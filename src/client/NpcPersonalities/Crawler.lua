local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.Types)
local NpcStats = {
	BloodType = "Black",
	Health = 100,
	Walkspeed = 15,
	Debug = false,
}

local ATTACK_DISTANCE = 8.75

local module: Types.npcPersonality = {
	Start = {
		{ Function = "SetStats", Parameters = { NpcStats } },
		{ Function = "SwitchToState", Parameters = { "Idle" } },
		{ Function = "PlayAnimation", Parameters = { "Animation_Idle", 0.2, true } },
		--	{ Function = "ConnectPath" },
	},

	OnStep = {
		{ Function = "SearchForTarget", Parameters = { 25, 135 } },
		--{ Function = "CheckForDirectPath", Parameters = {} },
		--{ Function = "RunPath" },
		{ Function = "MoveTowardsTarget", Parameters = { 0.025 } },
		{ Function = "MoveAlongPath", Parameters = { 0.05 } },

		--{ Function = "LookAtTarget", Parameters = { true, 0.05 } },

		-- {
		-- 	Function = "LookAtPath",
		-- 	Parameters = { 0.05 },
		-- 	Conditions = { NextWaypoint = nil, InCloseRange = true, Invert = true },
		-- },
		-- { Function = "LookAtTarget", Parameters = { true, 0.05 }, Conditions = { InCloseRange = true } },

		-- {
		-- 	Function = "MoveForwards",
		-- 	Parameters = { 0.05 },
		-- 	Conditions = { NextWaypoint = nil, Invert = true },
		-- },
		-- { Function = "StopMoving", Conditions = { Conditions = { NextWaypoint = nil } } },
	},

	InCloseRange = {
		{
			Function = "MeleeAttack",
			Parameters = { 20, 1.5, Vector2.new(2.5, 5), 3, true },
		},

		Parameters = { ATTACK_DISTANCE },
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
		--{ Function = "SwitchToState", Parameters = { "Idle" } },
		--{ Function = "LookAtPath" },
		--{ Function = "MoveForwards", Parameters = { 0.05 } },
		{ Function = "RunPath", Parameters = { true } },
	},

	OnStateChanged = {
		{
			Function = "PlayAnimation",
			Parameters = { "Animation_Walk", 0.05, true },
			Conditions = { GetState = "Chasing" },
		},
	},
}

return module
