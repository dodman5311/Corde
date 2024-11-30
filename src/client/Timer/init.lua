local module = {
	timerQueue = {},
}

local RUN_SERVICE = game:GetService("RunService")
local signal = require(script.signal)

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
		Connection = nil,
		CallTime = os.clock(),
		WaitTime = waitTime,
		["Function"] = Function,
		Parameters = { ... },
		Condition = nil,

		OnTimerStepped = signal.new(),
	}

	timer.OnEnded = signal.new()

	function timer:IsRunning()
		return self.Connection and true or false
	end

	function timer:Run()
		if self.Connection then
			return
		end

		self.CallTime = os.clock()

		self.Connection = RUN_SERVICE.Heartbeat:Connect(function()

			self.OnTimerStepped:Fire(os.clock() - self.CallTime)

			if (os.clock() - self.CallTime) < self.WaitTime then
				return
			end

			timer.OnEnded:Fire()

			self.Connection:Disconnect()
			self.Connection = nil

			if not self.Function then
				return
			end
			self.Function(table.unpack(self.Parameters))
		end)
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
		if not self.Connection then
			return
		end
		self.Connection:Disconnect()
		self.Connection = nil
	end

	function timer:Destroy()
		if self.Connection then
			self.Connection:Disconnect()
			self.Connection = nil
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

return module
