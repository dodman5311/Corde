local ReplicatedStorage = game:GetService("ReplicatedStorage")
local module = {
	currentDisplayedModel = nil,
}
local client = script.Parent
local cameraService = require(client.Camera)
local acts = require(client.Acts)
local globalInputService = require(client.GlobalInputService)

local locksAndSafesFolder = ReplicatedStorage.Assets.Models.LocksAndSafes

function module:EnterLock(lockObject: Instance)
	local modelName = lockObject:GetAttribute("3DModel")
	if not modelName or acts:checkAct("Interacting") then
		return
	end

	local model = locksAndSafesFolder:FindFirstChild(modelName)
	if not model then
		return
	end

	acts:createAct("Interacting", "In3DLock")
	globalInputService.inputs["Walk"]:Disable()

	local newModel = model:Clone()
	newModel.Parent = workspace
	newModel:PivotTo(CFrame.new(0, -100, 0))
	local cameraRoot = newModel.PrimaryPart.CameraRoot

	cameraService:EnterFirstPerson(
		cameraRoot.WorldCFrame,
		cameraRoot:GetAttribute("ViewRange"),
		cameraRoot:GetAttribute("FieldOfView")
	)
	module.currentDisplayedModel = newModel

	module.exitInput:Enable()
	return newModel
end

function module:ExitLock()
	module.exitInput:Disable()

	acts:removeAct("Interacting", "In3DLock")
	globalInputService.inputs["Walk"]:Enable()

	cameraService:EnterFollow()
	module.currentDisplayedModel:Destroy()
end

local function exitLockInput(state)
	if state ~= Enum.UserInputState.Begin then
		return
	end

	module:ExitLock()
end

function module.Init()
	module.exitInput = globalInputService.CreateNewInput(
		"ExitLock",
		exitLockInput,
		Enum.KeyCode.ButtonB,
		Enum.UserInputType.MouseButton2,
		Enum.KeyCode.Backspace,
		Enum.KeyCode.Space
	)
	module.exitInput:Disable()
end

return module
