local util = {
	bound = {},
}
local deb = game:GetService("Debris")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local ts = game:GetService("TweenService")

local rng = Random.new()
local gameSettings = require(script.Parent.GameSettings)

local function flicker(frame, speed, amnt)
	for _ = 0, amnt do
		if not frame.Parent then
			return
		end

		task.wait(speed)
		frame.Visible = not frame.Visible
	end
end

function util.getSetting(groupName: string, settingName: string)
	local foundSetting

	for _, group in ipairs(gameSettings) do
		if group.Name ~= groupName then
			continue
		end

		

		for _, setting in ipairs(group) do
			if setting.Name ~= settingName then
				continue
			end

			foundSetting = setting			
		end
	end

	return foundSetting and foundSetting.Value, foundSetting
end

function util.SearchDictionary(dictionary, value)
	local foundValue
	for i, v in pairs(dictionary) do
		if v == value then
			foundValue = i
			break
		end
	end

	return foundValue
end

function util.flickerUi(frame, speed, amnt, nonSync)
	if nonSync then
		task.spawn(flicker, frame, speed, amnt)
	else
		flicker(frame, speed, amnt)
	end
end

function util.map(v, min1, max1, min2, max2)
	return (v - min1) / (max1 - min1) * (max2 - min2) + min2
end

local function typeOutTxt(label, text, letterPerSecond)
	for i = 0, string.len(text) do
		label.Text = string.sub(text, 0, i)
		task.wait(1 / letterPerSecond)
	end
end

function util.typeOut(label, text, letterPerSecond, nonSync)
	if nonSync then
		task.spawn(typeOutTxt, label, text, letterPerSecond)
	else
		typeOutTxt(label, text, letterPerSecond)
	end
end

local function tween(instance, tweenInfo, propertyTable)
	local newTween = ts:Create(instance, tweenInfo, propertyTable)
	newTween:Play()
	newTween.Completed:Connect(function()
		task.wait()
		newTween:Destroy()
	end)

	return newTween
end

function util.getNearestEnemy(position, maxDistance, list)
	local closest = math.huge
	local enemy
	local enemyPosition

	for _, foundEnemy in ipairs(list) do
		local distance = (position - foundEnemy:GetPivot().Position).Magnitude
		if distance > maxDistance then
			continue
		end
		local humanoid = foundEnemy:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then
			continue
		end

		if distance < closest then
			closest = distance
			enemy = foundEnemy
			enemyPosition = enemy:GetPivot().Position
		end
	end

	return enemy, closest, enemyPosition
end

function util.ShuffleTable(tabl)
	for i = 1, #tabl - 1 do
		local ran = math.random(i, #tabl)
		tabl[i], tabl[ran] = tabl[ran], tabl[i]
	end

	return tabl
end

function util.circleCurve(t)
	return math.sqrt(1 - (2 * t - 1) ^ 2)
end

function util.tween(
	instance: Instance | {},
	tweenInfo: TweenInfo,
	propertyTable: {},
	yield: boolean?,
	endingFunction: any?,
	endingState: Enum.PlaybackState?
)
	local createdTween

	if typeof(instance) == "table" then
		for _, v in pairs(instance) do
			createdTween = tween(v, tweenInfo, propertyTable)
		end
	else
		createdTween = tween(instance, tweenInfo, propertyTable)
	end

	if yield then
		createdTween.Completed:Wait()
		if not endingFunction then
			return createdTween
		end

		local state = createdTween.PlaybackState
		if state ~= (endingState or Enum.PlaybackState.Completed) then
			return
		end
		endingFunction()
	elseif endingFunction then
		createdTween.Completed:Connect(function(state)
			if state ~= (endingState or Enum.PlaybackState.Completed) then
				return
			end

			endingFunction()
		end)
	end

	return createdTween
end

function util.callFromCache(object)
	local cache = game:GetService("ReplicatedStorage").Assets.Cache
	local getObject = cache:FindFirstChild(object.Name)
	if not getObject then
		getObject = object:Clone()
	end
	return getObject
end

function util:GetMatchingChildren(
	parent: Instance,
	propertiesTable: {},
	getDescendants: boolean?
): {} -- e.g {PropertyName = Value}
	local children
	local matchingChildren = {}
	if getDescendants then
		children = parent:GetChildren()
	else
		children = parent:GetDescendants()
	end

	for _, child: Instance in ipairs(children) do
		local childMatches = true

		for propertyName, value in pairs(propertiesTable) do
			if child[propertyName] == value then
				continue
			end

			childMatches = false
		end

		if not childMatches then
			continue
		end

		table.insert(matchingChildren, child)
	end

	return matchingChildren
end

local function placeInCache(object)
	if not object or not object.Parent then
		return
	end

	object.Parent = game:GetService("ReplicatedStorage").Assets.Cache
end

function util.addToCache(object, expireTime)
	if expireTime then
		task.delay(expireTime, function()
			placeInCache(object)
		end)
	else
		placeInCache(object)
	end
end

function util.doWithChance(chance: number, func)
	if math.random(0, 100) <= chance then
		func()
	end
end

function util.visualizeRay(origin, goal)
	local newPart = Instance.new("Part")
	newPart.Transparency = 1
	newPart.CanCollide = false
	newPart.CanQuery = false
	newPart.CanTouch = false
	newPart.Anchored = true

	local a0 = Instance.new("Attachment")
	a0.Parent = newPart
	a0.WorldPosition = origin
	local a1 = Instance.new("Attachment")
	a1.Parent = newPart
	a1.WorldPosition = goal

	local beam = Instance.new("Beam")
	beam.Parent = newPart
	beam.Attachment0 = a0
	beam.Attachment1 = a1
	beam.Width0 = 0.1
	beam.Width1 = 0.1
	beam.FaceCamera = true

	deb:AddItem(newPart, 1)
	newPart.Parent = workspace
end

function util.len(t)
	local n = 0

	for _ in pairs(t) do
		n = n + 1
	end
	return n
end

function util.getKey(i, k)
	if string.match(k, "Mouse") then
		return Enum.UserInputType[k] == i.UserInputType
	else
		return Enum.KeyCode[k] == i.KeyCode
	end
end

function util.getMods(parent, getDescendants, priority)
	local requiedModules = {}
	local t = parent:GetChildren()
	if getDescendants then
		t = parent:GetDescendants()
	end

	local modules = {}

	for _, v in ipairs(t) do
		if not v:IsA("ModuleScript") then
			continue
		end
		table.insert(modules, v)
	end

	if priority then
		for _, v in priority do
			local module = parent:WaitForChild(v)
			requiedModules[module.Name] = require(module)
		end
	end

	for index, module in ipairs(modules) do
		if priority and table.find(priority, index) then
			continue
		end
		requiedModules[module.Name] = require(module)
	end

	return requiedModules
end

function util.commitAction(action, list, priority, ...)
	if priority then
		for _, v in priority do
			local mod = list[v]
			if not mod or not mod[action] then
				continue
			end
			mod[action](...)
		end
	end

	for index, mod in list do
		if priority and table.find(priority, index) then
			continue
		end
		if not mod[action] then
			continue
		end
		mod[action](...)
	end
end

function util.checkForHumanoid(subject)
	if not subject then
		return
	end
	local model = subject:IsA("Model") and subject or subject:FindFirstAncestorOfClass("Model")
	if not model then
		return
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	return humanoid, model
end

function util.getRandomChild(Parent: Instance)
	if not Parent then
		return
	end
	local children = Parent:GetChildren()
	local i = rng:NextInteger(1, #children)
	return children[i]
end

function util.loadToTable(Parent: Instance, LoadTo: Animator)
	local Table = {}
	for _, v in ipairs(Parent:GetChildren()) do
		if not v:IsA("Animation") then
			continue
		end
		Table[v.Name] = LoadTo:LoadAnimation(v)
	end
	return Table
end

function util.randomAngle(angle)
	return math.rad(math.random(-angle * 1000, angle * 1000) / 1000)
end

util.PlayingSounds = {}

function util.PlaySound(sound: Sound, range: number?, stopTime: number?, parent: Instance?): Sound?
	if not sound then
		return
	end

	local soundClone = sound:Clone()
	--soundClone.Name = "SoundPlaying"
	soundClone.Parent = parent or script
	if range then
		soundClone.PlaybackSpeed += rng:NextNumber(-range, range)
	end

	soundClone:Play()

	if stopTime then
		deb:AddItem(soundClone, stopTime)
	else
		soundClone.Ended:Once(function()
			soundClone:Destroy()
		end)
	end

	return soundClone
end

function util.PlayFrom(object: Model | BasePart, sound: Sound, range: number?, stopTime: number?): Sound?
	local character = Players.LocalPlayer.Character
	if not character then
		return
	end

	-- local camera = workspace.CurrentCamera -- DIRECTIONAL AUDIO: Simply doesn't sound good.
	-- local newObject = Instance.new("Part")
	-- newObject.Parent = workspace
	-- newObject.Anchored = true
	-- newObject.Transparency = 0
	-- newObject.CanQuery = false
	-- newObject.Size = Vector3.one * 0.1
	-- newObject.Material = Enum.Material.Neon

	-- local step = RunService.RenderStepped:Connect(function()
	-- 	local cn = camera.CFrame * CFrame.Angles(math.rad(90), 0, 0) * CFrame.new(0, -camera.CFrame.Position.Y, 0)
	-- 	local offset = object:GetPivot().Position - cn.Position
	-- 	newObject.CFrame = camera.CFrame * CFrame.new(offset)
	-- end)

	-- newObject.Name = "SoundPart"

	local soundClone: Sound? = util.PlaySound(sound, range, stopTime) --, newObject)
	-- soundClone.RollOffMode = Enum.RollOffMode.Inverse
	-- soundClone.RollOffMinDistance = 1000
	-- soundClone.RollOffMaxDistance = 1000

	if not soundClone then
		return
	end

	if soundClone.SoundGroup == SoundService.SoundEffects then
		soundClone.Destroying:Once(function()
			util.PlayingSounds[soundClone] = nil
			--step:Disconnect()
			--deb:AddItem(newObject, 0.1)
		end)
		util.PlayingSounds[soundClone] = object
	end

	return soundClone
end

function util.getClosestToViewportCenter(camera, parent)
	local closest = math.huge
	local subject

	local get = game.Workspace:GetDescendants()
	if parent then
		get = parent:GetDescendants()
	end

	for _, v in ipairs(get) do
		if not v:IsA("Model") or not v.PrimaryPart then
			continue
		end

		local root = v.PrimaryPart
		local pos, isOnScreen = camera:WorldToViewportPoint(root.Position)
		local onScreenPosition = Vector2.new(pos.X, pos.Y)
		if not isOnScreen then
			continue
		end

		local center = camera.ViewportSize / 2
		local distanceTo = (onScreenPosition - center).Magnitude
		if distanceTo < closest then
			closest = distanceTo
			subject = v
		end
	end

	return subject
end

return util
