-- Dependencies
local RunService = game:GetService("RunService")

local Path = require(script.Dependencies.Path)
local StateMachine = require(script.Dependencies.StateMachine)
local StateConfig = require(script.StateConfig)

local Character = script.Parent
local Animator = Character.AnimationController.Animator
local Target = workspace.Target

local ObstacleRayParams = RaycastParams.new()
ObstacleRayParams.FilterDescendantsInstances = { Character, Target }
ObstacleRayParams.FilterType = Enum.RaycastFilterType.Exclude
ObstacleRayParams.RespectCanCollide = true

local AgentData: Path.AgentData = {
	AgentRadius = 6,
	AgentHeight = 17,
	AgentStepHeight = 1,
	AgentCanJump = false,
	AgentCanClimb = false,
}

-- Types

type AdultState = StateConfig.AdultState
type AdultInstances = StateConfig.AdultInstances
type AdultAnimations = StateConfig.AdultAnimations
type AdultBlackboard = StateConfig.AdultBlackboard
type PathState = Path.State

-- Initialize

local Instances: AdultInstances = {
	model = Character,
	rootPart = Character.RootPart,
	controllerManager = Character.ControllerManager,
	controllers = {
		ground = Character.ControllerManager.GroundController,
		air = Character.ControllerManager.AirController,
	}
}

local Animations: AdultAnimations = {
	idle = Animator:LoadAnimation(script.Animations.Idle),
	walk = Animator:LoadAnimation(script.Animations.Walk),
	run = Animator:LoadAnimation(script.Animations.Run),
	attack = Animator:LoadAnimation(script.Animations.Attack),
}

Animations.walk.Priority = Enum.AnimationPriority.Action
Animations.run.Priority = Enum.AnimationPriority.Action
Animations.attack.Priority = Enum.AnimationPriority.Action3
Animations.attack.Looped = false

local PathState = Path.state(AgentData, Character:GetPivot().Position, ObstacleRayParams, nil, true)

local Blackboard: AdultBlackboard = {
	cNextAttack = 0,
	currentTarget = Target:GetPivot().Position,
}

Animations.idle:Play()

-- Logic

local state: AdultState = if Character:GetAttribute("IsAggressive") then "Aggressive" else "Passive"

local function UpdateBlackboard()
	Blackboard.currentTarget = Target:GetPivot().Position
end

local function UpdateStateMachine(dt: number)
	local transition = StateMachine.CheckTransitions(StateConfig, state, Instances, Animations, PathState)
	if transition then
		StateMachine.Transition(StateConfig, transition, state, Instances, Animations, Blackboard, PathState)
		state = transition.to
	end

	StateMachine.Update(StateConfig, state, dt, Instances, Animations, Blackboard, PathState)
end

local function UpdateMovement()
	local currentPosition = Character:GetPivot().Position
	local targetPosition = Blackboard.currentTarget
	Path.Update(PathState, currentPosition, targetPosition)
	local direction = Path.GetDirection(PathState, currentPosition, targetPosition)
	Instances.controllerManager.MovingDirection = direction
	
	if not direction:FuzzyEq(Vector3.zero) then
		Instances.controllerManager.FacingDirection = direction
	end
end

RunService.PostSimulation:Connect(function(dt: number)
	UpdateBlackboard()
	UpdateStateMachine(dt)
	UpdateMovement()
end)