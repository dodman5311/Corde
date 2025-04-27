local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local module = {
	currentDisplayedModel = nil,
}
local client = script.Parent
local cameraService = require(client.Camera)
local acts = require(client.Acts)
local globalInputService = require(client.GlobalInputService)
local inventory = require(client.Inventory)
local util = require(client.Util)

local player = Players.LocalPlayer

local objectsFolder = ReplicatedStorage.Assets.Models["3DObjects"]
local HUD
local TRANSITION_INFO = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, 0, true)

function module:EnterView(object: Instance)
	local modelName = object:GetAttribute("3DModel")
	if not modelName or acts:checkAct("Interacting", "InObjectView") then
		return
	end

	local model = objectsFolder:FindFirstChild(modelName)
	if not model then
		return
	end
	acts:createAct("InObjectView")

	globalInputService.inputs["ToggleFire"]:Disable()
	globalInputService.inputs.Interact:Disable()
	player:SetAttribute("MovementEnabled", false)

	util.tween(HUD.Transition, TRANSITION_INFO, { BackgroundTransparency = 0 }, false, function()
		module.exitInput:Enable()
		HUD.Leave3DViewPrompt.Visible = true
		globalInputService.inputs.Interact:Enable()
	end, Enum.PlaybackState.Completed)

	local newModel = model:Clone()
	newModel.Parent = workspace
	newModel:PivotTo(CFrame.new(0, -100, 0))
	module.currentDisplayedModel = newModel

	local cameraRoot = newModel.PrimaryPart.CameraRoot

	task.delay(TRANSITION_INFO.Time, function()
		cameraService:EnterFirstPerson(
			cameraRoot.WorldCFrame,
			cameraRoot:GetAttribute("ViewRange"),
			cameraRoot:GetAttribute("FieldOfView")
		)
	end)

	return newModel
end

function module:ExitView()
	globalInputService.inputs.Interact:Disable()
	util.tween(HUD.Transition, TRANSITION_INFO, { BackgroundTransparency = 0 }, false, function()
		globalInputService.inputs.Interact:Enable()
	end, Enum.PlaybackState.Completed)

	module.exitInput:Disable()
	HUD.Leave3DViewPrompt.Visible = false
	player:SetAttribute("MovementEnabled", true)

	task.wait(TRANSITION_INFO.Time)
	acts:removeAct("InObjectView")
	module.currentDisplayedModel:Destroy()
	cameraService:EnterFollow()
end

local function exitViewInput(state)
	if state ~= Enum.UserInputState.Begin then
		return
	end

	module:ExitView()
end

function module.Init()
	module.exitInput = globalInputService.CreateNewInput(
		"ExitView",
		exitViewInput,
		Enum.KeyCode.ButtonB,
		Enum.UserInputType.MouseButton2,
		Enum.KeyCode.Backspace,
		Enum.KeyCode.Space
	)
	module.exitInput:Disable()

	HUD = Players.LocalPlayer.PlayerGui.HUD
end

inventory.InvetoryToggled:Connect(function(value)
	if value or not acts:checkAct("InObjectView") then
		return
	end

	module.exitInput:Enable()
end)

return module
