local module = {
    OnStep = {
		{ Function = "SearchForTarget", Parameters = { "Player", 25} },
		--{ Function = "LookAtTarget", Parameters = { true, .05 } },

	},

	OnDeath = {
		{ Function = "PlaceNpcBody" },
		{ Function = "Destroy" },
	}
}

return module