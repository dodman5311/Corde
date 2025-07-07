local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local globalInputService = require(script.Parent.GlobalInputService)
local Types = require(ReplicatedStorage.Shared.Types)

local function onKeyboardChanged(self: Types.Setting)
	globalInputService.inputActions[self.Name]:ReplaceKeybinds("Keyboard", { [self.Values] = self.Value })
	self.Values = self.Value
	globalInputService:CheckKeyPrompts()
end

local function onGamepadChanged(self: Types.Setting)
	globalInputService.inputActions[self.Name]:ReplaceKeybinds("Gamepad", { [self.Values] = self.Value })
	self.Values = self.Value
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
			OnChanged = function(self: Types.Setting)
				game:GetService("SoundService").Music.Volume = self.Value / 100
			end,
		},

		{
			Name = "SFX Volume",
			Type = "Slider",
			Value = 100,
			Values = NumberRange.new(0, 100),
			OnChanged = function(self: Types.Setting)
				game:GetService("SoundService").UI.Volume = self.Value / 100
				game:GetService("SoundService").SoundEffects.Volume = self.Value / 100
			end,
		},
	},

	{
		Name = "Graphics",

		{
			Name = "Film Grain",
			Type = "List",
			Value = true,
			Values = { true, false },
			OnChanged = function(self: Types.Setting)
				playerGui:WaitForChild("FilmGrain").Enabled = self.Value
			end,
		},

		{
			Name = "Screen Effects",
			Type = "List",
			Value = "None",
			Values = { "None", "Vintage", "CRTV" },
			OnChanged = function(self: Types.Setting)
				for _, frame in ipairs(playerGui.ScreenEffects:GetChildren()) do
					frame.Visible = frame.Name == self.Value
				end
			end,
		},
	},

	{
		Name = "Interface",

		{
			Name = "Font",
			Type = "List",

			Value = "Silkscreen",
			Values = { "Silkscreen", "Arcade", "Inconsolata", "Arial" },
			OnChanged = function(self: Types.Setting)
				local fonts = {
					Silkscreen = Font.fromId(12187371840),
					["Arcade"] = Font.fromEnum(Enum.Font.Arcade),
					["Arial"] = Font.fromEnum(Enum.Font.Arial),
					["Inconsolata"] = Font.fromEnum(Enum.Font.Code),
				}

				for _, label in ipairs(game:GetDescendants()) do
					if not (label:IsA("TextLabel") or label:IsA("TextButton") or label:IsA("TextBox")) then
						continue
					end

					label.FontFace = fonts[self.Value]
				end
			end,
		},
	},

	{
		Name = "Gameplay",
		-- {
		-- 	Name = "Difficulty",
		-- 	Type = "List",
		-- 	Value = "Solemn",
		-- 	Values = { "Hope", "Solemn", "Despair" },
		-- 	-- Hope: Take less damage. Empty Hunger doesn't increase damage taken.
		-- 	-- Solemn: The intended way to play.
		-- 	-- Despair: Take more damage. Hunger goes down over time. Less ammo.

		-- 	OnChanged = function() end,
		-- },

		{
			Name = "Auto Read",
			Type = "List",
			Value = true,
			Values = { true, false },
			OnChanged = function() end,
		},

		{
			Name = "Hints",
			Type = "List",
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
			Values = Enum.KeyCode.F,
			OnChanged = onKeyboardChanged,
		},

		{
			Name = "Inventory",
			Type = "KeyInput",
			Value = Enum.KeyCode.E,
			Values = Enum.KeyCode.E,
			OnChanged = onKeyboardChanged,
		},

		{
			Name = "N.E.T",
			Type = "KeyInput",
			Value = Enum.KeyCode.Tab,
			Values = Enum.KeyCode.Tab,
			OnChanged = onKeyboardChanged,
		},

		{
			Name = "Sprint",
			Type = "KeyInput",
			Value = Enum.KeyCode.LeftShift,
			Values = Enum.KeyCode.LeftShift,
			OnChanged = onKeyboardChanged,
		},

		{
			Name = "Ready Weapon",
			Type = "KeyInput",
			Value = Enum.UserInputType.MouseButton2,
			Values = Enum.UserInputType.MouseButton2,
			OnChanged = onKeyboardChanged,
		},

		{
			Name = "Fire Weapon",
			Type = "KeyInput",
			Value = Enum.UserInputType.MouseButton1,
			Values = Enum.UserInputType.MouseButton1,
			OnChanged = onKeyboardChanged,
		},

		{
			Name = "Reload",
			Type = "KeyInput",
			Value = Enum.KeyCode.R,
			Values = Enum.KeyCode.R,
			OnChanged = onKeyboardChanged,
		},

		{
			Name = "Exit First Person View",
			Type = "KeyInput",
			Value = Enum.UserInputType.MouseButton2,
			Values = Enum.UserInputType.MouseButton2,
			OnChanged = onKeyboardChanged,
		},
	},

	{
		Name = "Gamepad",

		{
			Name = "Interact",
			Type = "KeyInput",
			Value = Enum.KeyCode.ButtonA,
			Values = Enum.KeyCode.ButtonA,
			OnChanged = onGamepadChanged,
		},

		{
			Name = "Inventory",
			Type = "KeyInput",
			Value = Enum.KeyCode.ButtonY,
			Values = Enum.KeyCode.ButtonY,
			OnChanged = onGamepadChanged,
		},

		{
			Name = "N.E.T",
			Type = "KeyInput",
			Value = Enum.KeyCode.ButtonL1,
			Values = Enum.KeyCode.ButtonL1,
			OnChanged = onGamepadChanged,
		},

		{
			Name = "Sprint",
			Type = "KeyInput",
			Value = Enum.KeyCode.ButtonR2,
			Values = Enum.KeyCode.ButtonR2,
			OnChanged = onGamepadChanged,
		},

		{
			Name = "Ready Weapon",
			Type = "KeyInput",
			Value = Enum.KeyCode.ButtonL2,
			Values = Enum.KeyCode.ButtonL2,
			OnChanged = onGamepadChanged,
		},

		{
			Name = "Fire Weapon",
			Type = "KeyInput",
			Value = Enum.KeyCode.ButtonR2,
			Values = Enum.KeyCode.ButtonR2,
			OnChanged = onGamepadChanged,
		},

		{
			Name = "Reload",
			Type = "KeyInput",
			Value = Enum.KeyCode.ButtonR1,
			Values = Enum.KeyCode.ButtonR1,
			OnChanged = onGamepadChanged,
		},

		{
			Name = "Exit First Person View",
			Type = "KeyInput",
			Value = Enum.KeyCode.ButtonB,
			Values = Enum.KeyCode.ButtonB,
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
