local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local globalInputService = require(script.Parent.GlobalInputService)

local function onKeyboardChanged(self, previousValue)
	globalInputService.inputs[self.Name]:ReplaceKeybinds("Keyboard", { [previousValue] = self.Value })
	globalInputService:CheckKeyPrompts()
end

local function onGamepadChanged(self, previousValue)
	globalInputService.inputs[self.Name]:ReplaceKeybinds("Gamepad", { [previousValue] = self.Value })
	globalInputService:CheckKeyPrompts()
end

local gameSettings = {
	{
		Name = "Audio",

		{
			Name = "Music Volume",
			Type = "Slider",
			Value = 100,
			Values = NumberRange.new(0, 100),
			OnChanged = function(self)
				game:GetService("SoundService").Music.Volume = self.Value / 100
			end,
		},

		{
			Name = "SFX Volume",
			Type = "Slider",
			Value = 100,
			MaxValue = NumberRange.new(0, 100),
			OnChanged = function(self)
				game:GetService("SoundService").UI.Volume = self.Value / 100
				game:GetService("SoundService").SoundEffects.Volume = self.Value / 100
			end,
		},
	},

	{
		Name = "Graphics",

		{
			Name = "Film Grain",
			Type = "Selection",
			Value = true,
			Values = { true, false },
			OnChanged = function(self)
				playerGui:WaitForChild("FilmGrain").Enabled = self.Value
			end,
		},
	},

	{
		Name = "Interface",
	},

	{
		Name = "Gameplay",
		{
			Name = "Difficulty",
			Type = "Selection",
			Value = "Solemn",
			Values = { "Hope", "Solemn", "Despair" },
			-- Hope: Take less damage. Empty Hunger doesn't increase damage taken.
			-- Solemn: The intended way to play.
			-- Despair: Take more damage. Hunger goes down over time. Less ammo.

			OnChanged = function() end,
		},

		{
			Name = "Auto Read",
			Type = "Selection",
			Value = true,
			Values = { true, false },
			OnChanged = function() end,
		},

		{
			Name = "Hints",
			Type = "Selection",
			Value = false,
			Values = { true, false },
			OnChanged = function() end,
		},
	},

	{
		Name = "Keybinds",

		{
			Name = "Interact",
			Type = "KeyInput",
			Value = Enum.KeyCode.F,
			OnChanged = onKeyboardChanged,
		},

		{
			Name = "Inventory",
			Type = "KeyInput",
			Value = Enum.KeyCode.E,
			OnChanged = onKeyboardChanged,
		},

		{
			Name = "N.E.T",
			Type = "KeyInput",
			Value = Enum.KeyCode.Tab,
			OnChanged = onKeyboardChanged,
		},

		{
			Name = "Sprint",
			Type = "KeyInput",
			Value = Enum.KeyCode.LeftShift,
			OnChanged = onKeyboardChanged,
		},

		{
			Name = "Ready Weapon",
			Type = "KeyInput",
			Value = Enum.UserInputType.MouseButton2,
			OnChanged = onKeyboardChanged,
		},

		{
			Name = "Fire Weapon",
			Type = "KeyInput",
			Value = Enum.UserInputType.MouseButton1,
			OnChanged = onKeyboardChanged,
		},

		{
			Name = "Reload",
			Type = "KeyInput",
			Value = Enum.KeyCode.R,
			OnChanged = onKeyboardChanged,
		},

		{
			Name = "Exit First Person View",
			Type = "KeyInput",
			Value = Enum.UserInputType.MouseButton2,
			OnChanged = onKeyboardChanged,
		},
	},

	{
		Name = "Gamepad",

		{
			Name = "Interact",
			Type = "KeyInput",
			Value = Enum.KeyCode.ButtonA,
			OnChanged = onGamepadChanged,
		},

		{
			Name = "Inventory",
			Type = "KeyInput",
			Value = Enum.KeyCode.ButtonY,
			OnChanged = onGamepadChanged,
		},

		{
			Name = "N.E.T",
			Type = "KeyInput",
			Value = Enum.KeyCode.ButtonL1,
			OnChanged = onGamepadChanged,
		},

		{
			Name = "Sprint",
			Type = "KeyInput",
			Value = Enum.KeyCode.ButtonR2,
			OnChanged = onGamepadChanged,
		},

		{
			Name = "Ready Weapon",
			Type = "KeyInput",
			Value = Enum.KeyCode.ButtonL2,
			OnChanged = onGamepadChanged,
		},

		{
			Name = "Fire Weapon",
			Type = "KeyInput",
			Value = Enum.KeyCode.ButtonR2,
			OnChanged = onGamepadChanged,
		},

		{
			Name = "Reload",
			Type = "KeyInput",
			Value = Enum.KeyCode.ButtonR1,
			OnChanged = onGamepadChanged,
		},

		{
			Name = "Exit First Person View",
			Type = "KeyInput",
			Value = Enum.KeyCode.ButtonB,
			OnChanged = onKeyboardChanged,
		},
	},
}

local function applySettings()
	for _, group in pairs(gameSettings) do
		for _, setting in ipairs(group) do
			setting:OnChanged()
		end
	end
end

local function loadSaveData(upgradeIndex, gameState, settingsToLoad)
	if not settingsToLoad then
		return
	end

	for _, group in pairs(gameSettings) do
		for _, setting in ipairs(group) do
			local foundSetting = settingsToLoad[setting.Name]
			if foundSetting == nil then
				continue
			end

			local previousValue = setting.Value
			setting.Value = foundSetting
			setting:OnChanged(previousValue)
		end
	end

	applySettings()
end

return gameSettings
