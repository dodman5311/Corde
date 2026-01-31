return (
	setmetatable({}, {
		__mode = "k",
		__index = function(self, model: Model)
			local plane = model:FindFirstChild("HumanoidRootPart") :: Part
			local root = model:FindFirstChild("HumanoidRootPart") :: Part

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
