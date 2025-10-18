local module = {
	timerQueue = {},
}

local RUN_SERVICE = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local signal = require(ReplicatedStorage.Packages.Signal)
local runningTimers = {}
local acts = require(script.Parent.Acts)

export type Timer = {
	IsRunning: boolean,
	CallTime: number,
	WaitTime: number,
	["Function"]: () -> any?,
	Parameters: { any? },

	OnTimerStepped: signal.Signal<number>,
	OnEnded: signal.Signal<Enum.PlaybackState>,

	Run: (self: Timer) -> nil,
	Reset: (self: Timer) -> nil,
	Delay: (self: Timer, amount: number) -> nil,
	Update: (self: Timer, index: string, value: any) -> nil,
	UpdateFunction: (self: Timer, func: () -> any, ...any) -> nil,
	Cancel: (self: Timer) -> nil,
	Destroy: (self: Timer) -> nil,
	Complete: (self: Timer) -> nil,
	GetCurrentTime: (self: Timer) -> number,
}
export type TimerQueue = {
	new: (self: TimerQueue, timerName: string, waitTime: number?, Function: (() -> any?)?, ...any?) -> Timer,

	DestroyAll: (self: TimerQueue) -> nil,

	CancelAll: (self: TimerQueue) -> nil,

	DoAll: (self: TimerQueue, functionName: string, ...any) -> nil,
}

module.new = function(self, timerName, waitTime, Function, ...): Timer
	local queue = self

	local pausedAt = 0

	if not timerName then
		timerName = #queue + 1
	end

	if queue.timerQueue[timerName] then
		return queue.timerQueue[timerName]
	end

	local timer = {
		IsRunning = false,
		CallTime = os.clock(),
		WaitTime = waitTime,
		["Function"] = Function,
		Parameters = { ... },

		OnTimerStepped = signal.new(),
		OnEnded = signal.new(),
	}

	timer.OnPaused = acts.OnActAdded:Connect(function(act)
		if act == "Paused" then
			pausedAt = os.clock()
		end
	end)

	timer.OnResumed = acts.OnActRemoved:Connect(function(act)
		if act == "Paused" then
			timer:Delay(os.clock() - pausedAt)
		end
	end)

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
		table.remove(runningTimers, table.find(runningTimers, self))
		self.IsRunning = false

		timer.OnEnded:Fire(Enum.PlaybackState.Cancelled)
	end

	function timer:Destroy()
		if self.IsRunning then
			table.remove(runningTimers, table.find(runningTimers, self))
			self.IsRunning = false
		end

		self.OnTimerStepped:Destroy()
		self.OnEnded:Destroy()

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

module.wait = function(sec, index)
	local waitTimer = module:new(index or "waitAt_" .. os.clock())
	waitTimer.WaitTime = sec or 0.01
	waitTimer:Run()
	waitTimer.OnEnded:Wait()
	waitTimer:Destroy()
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
	for _, timer in ipairs(runningTimers) do
		if acts:checkAct("Paused") then
			return
		end
		timer.OnTimerStepped:Fire(os.clock() - timer.CallTime)

		if (os.clock() - timer.CallTime) < timer.WaitTime then
			continue
		end

		table.remove(runningTimers, table.find(runningTimers, timer))

		timer.IsRunning = false
		timer.OnEnded:Fire(Enum.PlaybackState.Completed)

		if not timer.Function then
			continue
		end

		task.spawn(timer.Function, table.unpack(timer.Parameters))
	end
end)

return module
