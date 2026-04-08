local InputSystem = {}

--// Services

--// Instances

--// Modules

--// Values
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GlobalInputSystem = require(script.Parent.GlobalInputSystem)

InputSystem.InputActions = {
	Sprint = GlobalInputSystem.CreateInputAction("Sprint", function()
		return
	end, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonR2, "Button"),

	Interact = GlobalInputSystem.CreateInputAction("Interact", function()
		return
	end, Enum.KeyCode.F, Enum.KeyCode.ButtonX, "Button"),

	Inventory = GlobalInputSystem.CreateInputAction("Inventory", function()
		return
	end, Enum.KeyCode.E, Enum.KeyCode.ButtonY, "Button"),

	["NET Mode"] = GlobalInputSystem.CreateInputAction("Inventory", function()
		return
	end, Enum.KeyCode.Space, Enum.KeyCode.ButtonL1, "Button"),

	["Ready Weapon"] = GlobalInputSystem.CreateInputAction("Inventory", function()
		return
	end, Enum.KeyCode.Space, Enum.KeyCode.ButtonL1, "Button"),

	["Move Player"] = GlobalInputSystem.CreateInputAction("Move Player", function()
		return
	end, { Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D }, Enum.KeyCode.Thumbstick1, "Joystick"),
}

InputSystem.InputGroups = {
	Player = GlobalInputSystem.CreateActionGroup("Player"),
	Menu = GlobalInputSystem.CreateActionGroup("Menu"),
	Inventory = GlobalInputSystem.CreateActionGroup("Inventory"),
}

--// Functions
function InputSystem:ConnectToAction(
	inputAction: GlobalInputSystem.InputAction,
	func: (inputState: Enum.UserInputState, input: InputObject) -> any?
)
	inputAction.Callback = func
	inputAction:Refresh()
end

function InputSystem:Init()
	self = self :: typeof(InputSystem)
	--Prestart Code
	GlobalInputSystem.AddToActionGroup(
		self.InputGroups.Player,
		self.InputActions.Sprint,
		self.InputActions.Interact,
		self.InputActions["Move Player"],
		self.InputActions["Ready Weapon"],
		self.InputActions["NET Mode"]
	)

	GlobalInputSystem.AddToActionGroup(self.InputGroups.Inventory, self.InputActions.Inventory)
	GlobalInputSystem.AddToActionGroup(self.InputGroups.Menu, self.InputActions.Inventory)
end

function InputSystem:Start()
	--Start Code
end

--// Main //--

return InputSystem
