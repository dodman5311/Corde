local module = {
	timerQueue = {},
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RUN_SERVICE = game:GetService("RunService")
local signal = require(ReplicatedStorage.Packages.Signal)
local runningTimers = {}

module.wait = function(sec, index)
	local waitTimer = module:new(index or "waitAt_" .. os.clock())
	waitTimer.WaitTime = sec or 0.01
	waitTimer:Run()
	waitTimer.OnEnded:Wait()
	waitTimer:Destroy()
end

module.new = function(self, timerName, waitTime, Function, ...)
	local queue = self

	local pausedAt = 0

	if not timerName then
		timerName = #queue + 1
	end

	if queue.timerQueue[timerName] then
		return
	end

	local timer = {
		IsRunning = false,
		CallTime = os.clock(),
		WaitTime = waitTime,
		["Function"] = Function,
		Parameters = { ... },
		Condition = nil,

		OnTimerStepped = signal.new(),
	}

	timer.OnEnded = signal.new()

	function timer:Run()
		if self.IsRunning then
			return
		end

		self.CallTime = os.clock()

		self.IsRunning = true
		table.insert(runningTimers, self)
	end

	function timer:Reset()
		self.CallTime = os.clock()
	end

	function timer:Delay(amount)
		self.CallTime += amount
	end

	function timer:Update(index, value)
		self[index] = value
	end

	function timer:UpdateFunction(value, ...)
		self["Function"] = value
		self["Parameters"] = ...
	end

	function timer:Cancel()
		if not self.IsRunning then
			return
		end
		table.remove(table.find(runningTimers, self))
		self.IsRunning = false
	end

	function timer:Destroy()
		if self.IsRunning then
			table.remove(table.find(runningTimers, self))
			self.IsRunning = false
		end

		self.OnPaused:Disconnect()
		self.OnResumed:Disconnect()

		queue.timerQueue[timerName] = nil
	end

	function timer:Complete()
		self.CallTime = -self.WaitTime
	end

	function timer:GetCurrentTime()
		return os.clock() - self.CallTime
	end

	queue.timerQueue[timerName] = timer
	return queue.timerQueue[timerName]
end

function module:newQueue()
	return {
		timerQueue = {},
		new = module["new"],

		DestroyAll = function(self)
			for _, timer in self.timerQueue do
				if not timer["Destroy"] then
					continue
				end
				timer:Destroy()
			end
		end,

		CancelAll = function(self)
			for _, timer in self.timerQueue do
				if not timer["Cancel"] then
					continue
				end
				timer:Cancel()
			end
		end,

		DoAll = function(self, functionName, ...)
			for _, timer in self.timerQueue do
				if not timer[functionName] then
					continue
				end
				timer[functionName](timer, ...)
			end
		end,
	}
end

function module:getTimer(timerName)
	return self.timerQueue[timerName]
end

RUN_SERVICE.Heartbeat:Connect(function()
	for _,timer in ipairs(runningTimers) do
		timer.OnTimerStepped:Fire(os.clock() - timer.CallTime)

		if (os.clock() - timer.CallTime) < timer.WaitTime then
			continue
		end

		table.remove(table.find(runningTimers, timer))
		timer.IsRunning = false

		timer.OnEnded:Fire()

		if not timer.Function then
			continue
		end

		task.spawn(timer.Function, table.unpack(timer.Parameters))
	end
end)

return module
