local castTo = {}

function castTo.checkCast(positionA: Vector3, positionB: Vector3, rp: RaycastParams?)
	positionA = Vector3.new(positionA.X, 4, positionA.Z)
	positionB = Vector3.new(positionB.X, 4, positionB.Z)

	local raycast = workspace:Raycast(positionA, positionB - positionA, rp)

	return raycast
end

return castTo
