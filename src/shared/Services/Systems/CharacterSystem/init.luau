--!strict
local CharacterSystem = {}

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--// Instances

--// Modules
local BindToAttributes = require(ReplicatedStorage.Shared.Utils.BindToAttributes)
local CharacterAnimations = require(script.CharacterAnimations)
local CharacterConfig = require(ReplicatedStorage.Shared.Config.Character)
local CharacterTypes = require(ReplicatedStorage.Shared.Types.Character)
local Signal = require(ReplicatedStorage.Packages.Signal)
local SpriteSheetAnimator = require(ReplicatedStorage.Shared.Services.Components.SpriteSheetAnimator)

--// Values

type Character = CharacterTypes.Character
type CharacterConfig = CharacterTypes.CharacterConfig
type CharacterInstance = CharacterTypes.CharacterInstance
type CharacterState = CharacterTypes.CharacterState

local DEFAULT_CHARACTER_CONFIG: CharacterConfig = CharacterConfig
local Characters: { Character } = {}
local HeartBeatConnection: RBXScriptConnection?

--// Functions

local function GetDirectionUnit(vector: Vector2): Vector3
	local vector3Direction = Vector3.new(vector.X, 0, vector.Y)

	if vector3Direction.Magnitude > 0 then
		vector3Direction = vector3Direction.Unit
	else
		vector3Direction = Vector3.zero
	end

	return vector3Direction
end

local function UpdateMovementDirection(character: Character)
	local movementDirection = character.State.MovementDirection

	local walkVel = character.Instance:FindFirstChild("WalkVelocity") :: LinearVelocity?
	if not walkVel then
		return
	end

	local movementUnit = GetDirectionUnit(movementDirection) * character.State.WalkSpeed
	walkVel.VectorVelocity = walkVel.VectorVelocity:Lerp(movementUnit, character.State.MovementFriction)
end

local function UpdateLookDirection(character: Character)
	local lookDirection = character.State.LookDirection

	local gyro = character.Instance:FindFirstChild("Gyro") :: AlignOrientation?
	if not gyro then
		return
	end

	local lookUnit = GetDirectionUnit(lookDirection)

	local position = character.Instance:GetPivot().Position

	if lookUnit.Magnitude > 0 then
		gyro.CFrame = CFrame.lookAt(position, position + lookUnit)
	end
end

function CharacterSystem:Start()
	if HeartBeatConnection then
		return
	end
	HeartBeatConnection = RunService.Heartbeat:Connect(function()
		for _, character: Character in ipairs(Characters) do
			UpdateMovementDirection(character)
			UpdateLookDirection(character)
		end
	end)
end

function CharacterSystem:Stop()
	if not HeartBeatConnection then
		return
	end

	HeartBeatConnection:Disconnect()
	HeartBeatConnection = nil
end

local function copyToTable(donor: {}, receiver: {})
	for index, value in donor do
		receiver[index] = value
	end
end

function CharacterSystem:GetCharacterFromInstance(characterInstance: Instance): Character?
	for _, character: Character in ipairs(Characters) do
		if character.Instance == characterInstance then
			return character
		end
	end

	return
end

local function BuildCharacterState(config: CharacterConfig): CharacterState
	local characterState = {
		MovementDirection = Vector2.zero,
		LookDirection = Vector2.zero,
		IsAlive = true,
	}

	for index, value in pairs(config) do
		characterState[index] = value
	end

	return characterState :: CharacterState
end

function CharacterSystem.new(characterInstance: CharacterInstance, config: CharacterConfig?): Character
	config = config or DEFAULT_CHARACTER_CONFIG

	local attributesChanged: RBXScriptConnection
	local newInstance: CharacterInstance = characterInstance:Clone()
	local state = BindToAttributes(newInstance)

	copyToTable(BuildCharacterState(config :: CharacterConfig), state)
	newInstance.Name = state.Name

	local playingAnimations = {}

	local newCharacter: Character = {
		State = state,
		Context = {},

		Instance = newInstance,

		PlayAnimation = function(
			self: Character,
			animationName: string,
			frameDelay: number?,
			loop: boolean?,
			stayOnLastFrame: boolean?,
			startOnFrame: number?
		)
			local animationFrame, _ = self:GetAnimation(animationName)
			if not animationFrame or not animationFrame.Parent then
				return
			end

			local animationsTable = playingAnimations[animationFrame.Parent]

			for _, otherAnimationFrame in ipairs(animationsTable) do
				otherAnimationFrame.Visible = false
			end

			animationFrame.Visible = true
			frameDelay = frameDelay or 1 / self.State.FrameRate

			local animation = SpriteSheetAnimator.PlayAnimation(
				animationFrame,
				frameDelay :: number,
				loop,
				stayOnLastFrame,
				startOnFrame
			)

			if not animationsTable then
				playingAnimations[animationFrame.Parent] = {}
				animationsTable = playingAnimations[animationFrame.Parent]
			end
			table.insert(animationsTable, animationFrame)

			animation.OnEnded:Once(function()
				table.remove(animationsTable, table.find(animationsTable, animationFrame))
			end)

			return animation
		end,
		StopAnimation = function(self: Character, animationName: string)
			local animationFrame, _ = self:GetAnimation(animationName)
			if not animationFrame or not animationFrame.Parent then
				return
			end

			SpriteSheetAnimator.StopAnimation(animationFrame)

			local animationsTable = playingAnimations[animationFrame.Parent]

			table.remove(animationsTable, table.find(animationsTable, animationFrame))

			if #animationsTable > 0 then
				animationsTable[#animationsTable].Visible = true
			end
			return
		end,
		StopAllAnimations = function(self: Character)
			for _, animationFrame in ipairs(self.Instance:GetDescendants()) do
				if not animationFrame:IsA("GuiObject") or not animationFrame:FindFirstChild("Image") then
					continue
				end
				animationFrame.Visible = false
				SpriteSheetAnimator.StopAnimation(animationFrame)
			end

			playingAnimations = {}

			return
		end,

		GetAnimation = function(self: Character, animationName: string): (Frame?, SpriteSheetAnimator.Animation2D?)
			local animationFrame = self.Instance:FindFirstChild(animationName, true)
			if not animationFrame or not animationFrame:FindFirstChild("Image") then
				warn(`No animation by the name of {animationName} was found.`)
				return
			end
			local animation2d: SpriteSheetAnimator.Animation2D = SpriteSheetAnimator.CheckPlaying(animationFrame)
			return animationFrame, animation2d
		end,

		Spawn = function(self: Character, spawnLocation: Vector2)
			self.Instance.Parent = workspace
			self.Instance:PivotTo(CFrame.new(spawnLocation.X, 0, spawnLocation.Y))
			self:Run()

			return
		end,
		Run = function(self: Character)
			if table.find(Characters, self) then
				return
			end
			table.insert(Characters, self)

			self.OnDied:Connect(function() end)

			return
		end,
		Stop = function(self: Character)
			self:StopAllAnimations()
			local index = table.find(Characters, self)
			if not index then
				return
			end
			table.remove(Characters, index)

			return
		end,
		Destroy = function(self: Character)
			if attributesChanged then
				attributesChanged:Disconnect()
			end
			self:Stop()
			self.Instance:Destroy()
			self.OnDied:Destroy()
			self.OnHealthChanged:Destroy()
			self.OnMovementChanged:Destroy()

			return
		end,

		OnDied = Signal.new(),
		OnHealthChanged = Signal.new(),
		OnMovementChanged = Signal.new(),
	}

	attributesChanged = newInstance.AttributeChanged:Connect(function(attribute: string)
		if attribute == "MaxHealth" or attribute == "Health" then
			local health = newCharacter.State.Health
			local maxHealth = newCharacter.State.MaxHealth

			if health > maxHealth then
				newCharacter.State.Health = maxHealth
			elseif health < 0 then
				newCharacter.State.Health = 0
			end

			newCharacter.OnHealthChanged:Fire(newCharacter.State.Health)

			if newCharacter.State.Health == 0 and newCharacter.State.IsAlive == true then
				newCharacter.State.IsAlive = false
				newCharacter.OnDied:Fire()
			end
		elseif attribute == "MovementDirection" then
			newCharacter.OnMovementChanged:Fire(newCharacter.State.MovementDirection)
			-- connect character movement
		elseif attribute == "Name" then
			newInstance.Name = newCharacter.State.Name
		end
	end)

	return newCharacter
end

--// Main //--
return CharacterSystem
