local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Packages.Signal)

local Events = {
	Control = {
		ForceInventoryClose = Signal.new() :: Signal.Signal<>,
		WalkPlayerToPoint = Signal.new() :: Signal.Signal<Vector2>,
		UpdateInteractablesList = Signal.new() :: Signal.Signal<>,
	},
	React = {
		AreaEntered = Signal.new() :: Signal.Signal<Part>,
	},
}

return Events
