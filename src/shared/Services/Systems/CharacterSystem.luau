--!strict
local CharacterSystem = {}

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--// Instances

--// Modules
local BindToAttributes = require(ReplicatedStorage.Shared.Utils.BindToAttributes)
local Character = require(ReplicatedStorage.Shared.Config.Character)
local CharacterTypes = require(ReplicatedStorage.Shared.Types.Character)
local Signal = require(ReplicatedStorage.Packages.Signal)
local SpriteSheetAnimator = require(ReplicatedStorage.Shared.Services.Components.SpriteSheetAnimator)

--// Values

type Character = CharacterTypes.Character
type CharacterConfig = CharacterTypes.CharacterConfig
type CharacterInstance = CharacterTypes.CharacterInstance
type CharacterState = CharacterTypes.CharacterState

local DEFAULT_CHARACTER_CONFIG: CharacterConfig = Character
local Characters = {}

--// Functions

function CharacterSystem:Init() end

function CharacterSystem:Start() end

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

function CharacterSystem.new(
	characterName: string,
	characterInstance: CharacterInstance,
	config: CharacterConfig?
): Character
	config = config or DEFAULT_CHARACTER_CONFIG

	local newInstance: CharacterInstance = characterInstance:Clone()
	newInstance.Name = characterName

	local state = BindToAttributes(newInstance)
	copyToTable(BuildCharacterState(config :: CharacterConfig), state)

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
			local frame = self:GetAnimation(animationName)
			if not frame then
				return
			end

			frameDelay = frameDelay or 1 / self.State.FrameRate

			return SpriteSheetAnimator.PlayAnimation(frame, frameDelay :: number, loop, stayOnLastFrame, startOnFrame)
		end,
		StopAnimation = function(self: Character, animationName: string)
			local frame = self:GetAnimation(animationName)
			if not frame then
				return
			end

			SpriteSheetAnimator.StopAnimation(frame)
		end,
		GetAnimation = function(self: Character, animationName: string): (Frame?, SpriteSheetAnimator.Animation2D?)
			local getAnimationFrame = self.Instance:FindFirstChild(animationName, true)
			if not getAnimationFrame or not getAnimationFrame:FindFirstChild("Image") then
				warn(`No animation by the name of {animationName} was found.`)
				return
			end
			local animation2d: SpriteSheetAnimator.Animation2D = SpriteSheetAnimator.CheckPlaying(getAnimationFrame)
			return getAnimationFrame, animation2d
		end,

		Spawn = function(self: Character, spawnLocation: Vector2)
			self.Instance.Parent = workspace
			self.Instance:PivotTo(CFrame.new(spawnLocation.X, 0, spawnLocation.Y))
			self:Run()

			return
		end,
		Run = function(self: Character)
			table.insert(Characters, self)

			return
		end,
		Stop = function(self: Character)
			local index = table.find(Characters, self)
			if not index then
				return
			end
			table.remove(Characters, index)

			return
		end,
		Destroy = function(self: Character)
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

	newInstance.AttributeChanged:Connect(function(attribute: string)
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
		end
	end)

	return newCharacter
end

RunService.Heartbeat:Connect(function()
	for _, character: Character in ipairs(Characters) do
		local movementDirection = character.State.MovementDirection
		character.Instance.WalkVelocity.VectorVelocity = Vector3.new(movementDirection.X, 0, movementDirection.Y)
	end
end)

--// Main //--
return CharacterSystem
