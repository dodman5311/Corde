local module = {
	OnStep = {
		{ Function = "SearchForTarget", Parameters = { 20, 90 } },
		{ Function = "LookAtTarget", Parameters = { true, 0.05 }, State = "Looking" },
		{ Function = "LookRandom", Parameters = { true, 0.05, NumberRange.new(3, 6) }, State = "Idle" },
	},

	OnTargetFound = {
		{ Function = "SwitchToState", Parameters = { "Looking" } },
	},

	OnTargetLost = {
		{ Function = "SwitchToState", Parameters = { "Idle" } },
	},

	Start = {
		{ Function = "SwitchToState", Parameters = { "Idle" } },
	},

	OnDeath = {
		{ Function = "PlaceNpcBody" },
		{ Function = "Destroy" },
	},
}

return module
