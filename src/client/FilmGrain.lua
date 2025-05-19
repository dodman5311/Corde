--// This script was made by: 'boatbomber'
-- Check out the original DevForum post here:

-- https://devforum.roblox.com/t/misc-scripts-modules-my-smaller-projects/383771?u=itsplasmarblx

-- Settings

local GRAIN_SIZE = 50 -- A number 1 to 100
local GRAIN_SPEED = 100 -- A number 1 to 100
local GRAIN_VISIBILITY = 10 -- A number 1 to 100

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

local udim2 = UDim2.new
local rand = math.random
local plr = game.Players.LocalPlayer
local plrGui = plr:WaitForChild("PlayerGui")
local util = require(script.Parent.Util)

local baseSize = 300 * (GRAIN_SIZE * 0.02)
local speed = 1 / (40 * (GRAIN_SPEED * 0.02))
local vis = 1.05 - (GRAIN_VISIBILITY * 0.01)

local GrainGui = Instance.new("ScreenGui")
GrainGui.Name = "FilmGrain"
GrainGui.IgnoreGuiInset = true
GrainGui.DisplayOrder = 99
GrainGui.Parent = plrGui
GrainGui.Enabled = util.getSetting("Graphics", "Film Grain")

local GrainImage = Instance.new("ImageLabel")
GrainImage.Size = udim2(1, 0, 1, 0)
GrainImage.BackgroundTransparency = 1
GrainImage.ImageTransparency = vis
GrainImage.ScaleType = Enum.ScaleType.Tile
GrainImage.Image = "http://www.roblox.com/asset/?id=28756351"
GrainImage.Parent = GrainGui

local last = 0
game:GetService("RunService").Heartbeat:Connect(function()
	if tick() - last < speed then
		return
	end

	last = tick()
	GrainImage.TileSize =
		udim2(rand(baseSize * 0.89, baseSize * 1.11) / 1000, 0, rand(baseSize * 0.89, baseSize * 1.11) / 1000, 0)
end)

return {}
