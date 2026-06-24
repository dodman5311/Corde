-- Dependencies

local PathfindingService = game:GetService("PathfindingService")

local Pool = require(script.Parent.Pool)

local VECTOR3_XZ = Vector3.new(1, 0, 1)
local DEFAULT_COMPUTE_COOLDOWN = 0.2

local DEBUG_PART_SIZE = Vector3.new(0.6, 0.6, 0.6)
local DEBUG_COLOR = Color3.fromRGB(0, 170, 255)
local DEBUG_COLOR_JUMP = Color3.fromRGB(255, 85, 0)

local DEBUG_POOL_CONFIG: Pool.PoolConfig<Part> = {
	onRetrieve = function(part: Part)
		part.Parent = workspace
	end,
	onReturn = function(part: Part)
		part.Parent = nil
	end,
}

local DEBUG_POOL: Pool.Pool<Part> = Pool.new(function(): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Size = DEBUG_PART_SIZE
	part.Shape = Enum.PartType.Ball
	part.Material = Enum.Material.Neon
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end, DEBUG_POOL_CONFIG)

-- Types

export type AgentData = {
	AgentRadius: number,
	AgentHeight: number,
	AgentStepHeight: number,
	AgentCanJump: boolean,
	AgentCanClimb: boolean,
}

export type State = {
	agentData: AgentData,
	waypoints: { PathWaypoint },
	waypointIndex: number,

	cNextCompute: number,
	computeThread: thread?,
	computeCooldown: number,
	computeFailures: number,

	reachedTarget: boolean,
	hasDirectPath: boolean,
	targetPosition: Vector3,
	path: Path,

	obstacleParams: RaycastParams,
	debugParts: { Part }?,
}

-- Debug Util

local function ClearDebugVisuals(state: State)
	local parts = state.debugParts
	if not parts then
		return
	end
	for _, part in parts do
		DEBUG_POOL:Return(part)
	end
	table.clear(parts)
end

local function RenderDebugVisuals(state: State)
	local parts = state.debugParts
	if not parts then
		return
	end
	ClearDebugVisuals(state)

	for i = state.waypointIndex, #state.waypoints do
		local waypoint = state.waypoints[i]
		local part = DEBUG_POOL:Retrieve()
		part.Position = waypoint.Position
		part.Color = if waypoint.Action == Enum.PathWaypointAction.Jump then DEBUG_COLOR_JUMP else DEBUG_COLOR
		table.insert(parts, part)
	end
end

-- Path Util

local Path = {}

local function ClearPath(state: State)
	table.clear(state.waypoints)
	state.waypointIndex = 0
	ClearDebugVisuals(state)
end

local function ComputePath(state: State, currentPosition: Vector3, targetPosition: Vector3, cNow: number)
	state.cNextCompute = cNow + state.computeCooldown * (1 + state.computeFailures)

	state.computeThread = task.spawn(function()
		local path = state.path
		local success = pcall(path.ComputeAsync, path, currentPosition, targetPosition)

		print(path.Status)

		if success and path.Status == Enum.PathStatus.Success then
			state.waypoints = path:GetWaypoints()
			state.waypointIndex = 2
			state.computeFailures = 0
			RenderDebugVisuals(state)
		else
			state.computeFailures += 1
			ClearPath(state)
		end
		state.computeThread = nil
	end)
end

local function UpdateWaypoints(state: State, currentPosition: Vector3)
	local waypoints, waypointIndex = state.waypoints, state.waypointIndex
	local nWaypoints = #waypoints
	if nWaypoints == 0 then
		ClearPath(state)
		return
	end

	repeat
		local lastPosition = waypoints[waypointIndex - 1].Position
		local waypointOffset = (waypoints[waypointIndex].Position - lastPosition) * VECTOR3_XZ
		local passedWaypoint = ((currentPosition - lastPosition) * VECTOR3_XZ):Dot(waypointOffset)
			> waypointOffset:Dot(waypointOffset)
		if passedWaypoint then
			waypointIndex += 1
		end
	until waypointIndex > nWaypoints or not passedWaypoint

	if waypointIndex > nWaypoints then
		ClearPath(state)
	else
		state.waypointIndex = waypointIndex
	end
end

function Path.CheckDirectPath(state: State, currentPosition: Vector3, targetPosition: Vector3): boolean
	local agentData = state.agentData
	local height = agentData.AgentHeight
	local radius = agentData.AgentRadius
	local stepHeight = agentData.AgentStepHeight

	local offset = targetPosition - currentPosition
	local size = Vector3.new(2 * radius, height - stepHeight, 0)
	local origin = CFrame.lookAlong(
		Vector3.new(currentPosition.X, currentPosition.Y + (height + stepHeight) / 2, currentPosition.Z),
		offset * VECTOR3_XZ
	)

	return workspace:Blockcast(origin, size, offset, state.obstacleParams) == nil
end

function Path.GetDirection(state: State, currentPosition: Vector3, targetPosition: Vector3): Vector3
	if state.reachedTarget then
		return Vector3.zero
	end

	if state.hasDirectPath then
		return (targetPosition - currentPosition) * VECTOR3_XZ
	end

	local waypoint = state.waypoints[state.waypointIndex]
	return if waypoint then ((waypoint.Position - currentPosition) * VECTOR3_XZ).Unit else Vector3.zero
end

function Path.Update(state: State, currentPosition: Vector3, targetPosition: Vector3)
	local nWaypoints = #state.waypoints
	local reachedTarget = (targetPosition - currentPosition).Magnitude < 1
	state.reachedTarget = reachedTarget
	if reachedTarget then
		if nWaypoints > 0 then
			ClearPath(state)
		end
		return
	end

	local hasDirectPath = Path.CheckDirectPath(state, currentPosition, targetPosition)
	state.hasDirectPath = hasDirectPath

	if hasDirectPath then
		return
	end

	local cNow = os.clock()
	local targetChanged = (state.targetPosition - targetPosition).Magnitude > 1

	if targetChanged then
		state.targetPosition = targetPosition
	end

	local offCourse = state.waypointIndex >= 1
		and nWaypoints > 0
		and not Path.CheckDirectPath(state, currentPosition, state.waypoints[state.waypointIndex].Position)

	if offCourse then
		ClearPath(state)
		nWaypoints = 0
	end

	if (targetChanged or nWaypoints == 0) and not state.computeThread and cNow > state.cNextCompute then
		ComputePath(state, currentPosition, targetPosition, cNow)
	elseif nWaypoints > 0 then
		UpdateWaypoints(state, currentPosition)
	end
end

function Path.Cleanup(state: State)
	print("CLEAN")
	if state.computeThread then
		task.cancel(state.computeThread)
	end
	state.path:Destroy()
	ClearDebugVisuals(state)
end

function Path.state(
	agentData: AgentData,
	currentPosition: Vector3,
	obstacleParams: RaycastParams,
	computeCooldown: number?,
	debug: boolean?
): State
	assert(agentData.AgentStepHeight < agentData.AgentHeight, "AgentStepHeight must be less than AgentHeight")

	return {
		agentData = agentData,
		targetPosition = currentPosition,
		reachedTarget = true,
		hasDirectPath = true,
		waypointIndex = 0,
		waypoints = {},
		path = PathfindingService:CreatePath(agentData :: any),
		cNextCompute = os.clock(),
		computeCooldown = computeCooldown or DEFAULT_COMPUTE_COOLDOWN,
		computeFailures = 0,
		obstacleParams = obstacleParams,
		debugParts = if debug then {} else nil,
	}
end

return Path
