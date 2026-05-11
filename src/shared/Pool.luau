export type PoolConfig<T> = {

	minObjects: number?,
	onRetrieve: (object: T) -> ()?,
	onReturn: (object: T) -> ()?,
}

export type Pool<T> = {
	_available: { T },
	_constructor: () -> T,

	Return: (self: Pool<T>, object: T) -> (),
	Retrieve: (self: Pool<T>) -> T,
}

local Pool = {}
Pool.__index = Pool

function Pool.Return<T>(self: Pool<T>, object: T)
	table.insert(self._available, object)
end

function Pool.Retrieve<T>(self: Pool<T>): T
	local object = table.remove(self._available)
	if not object then
		object = self._constructor()
	end

	return object
end

function Pool.new<T>(constructor: () -> T, config: PoolConfig<T>?): Pool<T>
	local self = setmetatable({
		_available = {},
		_constructor = constructor,
	}, Pool) :: Pool<T>

	if config then
		local onRetrieve = config.onRetrieve
		if onRetrieve then
			self.Retrieve = function(self: Pool<T>): T
				local object = Pool.Retrieve(self)
				onRetrieve(object)
				return object
			end
		end

		local onReturn = config.onReturn
		if onReturn then
			self.Return = function(self: Pool<T>, object: T)
				Pool.Return(self, object)
				onReturn(object)
			end
		end

		local minObjects = config.minObjects
		if minObjects then
			for i = 1, minObjects do
				self:Return(constructor())
			end
		end
	end

	return self
end

return Pool
