return (
	setmetatable({}, {
		__mode = "k",
		__index = function(self, model: Model)
			local controllerManager = model:FindFirstChild("ControllerManager") :: ControllerManager
			local groundController = controllerManager:FindFirstChild("GroundController") :: GroundController
			local slideController = controllerManager:FindFirstChild("SlideController") :: GroundController
			local airController = controllerManager:FindFirstChild("AirController") :: AirController
			local playerReference = model:FindFirstChild("PlayerReference") :: ObjectValue
			local haltVerticalVelocity = model:FindFirstChild("HaltVerticalVelocity") :: LinearVelocity
			local alignPosition = model:FindFirstChild("AlignPosition") :: AlignPosition
			local humanoid = model:FindFirstChild("Humanoid") :: Humanoid
			local root = model:FindFirstChild("HumanoidRootPart") :: Part
			local groundSensor = root:FindFirstChild("GroundSensor") :: ControllerPartSensor
			local bodyBackAttachment = model:FindFirstChild("BodyBackAttachment", true) :: Attachment

			local characterInstance = {
				Model = model,
				ControllerManager = controllerManager,
				GroundController = groundController,
				SlideController = slideController,
				AirController = airController,
				GroundSensor = groundSensor,
				PlayerReference = playerReference,
				HaltVerticalVelocity = haltVerticalVelocity,
				AlignPosition = alignPosition,
				Humanoid = humanoid,
				Root = root,
				BodyBackAttachment = bodyBackAttachment,
			} :: CharacterInstances

			rawset(self, model, characterInstance)
			return characterInstance
		end,
	}) :: any
) :: { [Model]: CharacterInstances }
