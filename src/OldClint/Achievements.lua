local Achievements = {
	Ids = {
		SeriousExceptionError = 1689940225597180,
		PreppersInstinct = 898533891695716,
		SomethingWrong = 3458853088031214,
		WomanInTheMirror = 1780080177178857,
	},
}

--// Services
local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

--// Instances
local assets = ReplicatedStorage.Assets
local sounds = assets.Sounds
local gui = StarterGui:WaitForChild("Achievements")

--// Modules
local Net = require(ReplicatedStorage.Packages.Net)
local Util = require(script.Parent.Util)

--// Values

--// Functions
local function showAwardedAchievement(AchievementId: number)
	local ti = TweenInfo.new(0.5, Enum.EasingStyle.Linear)

	local badgeInfo = BadgeService:GetBadgeInfoAsync(AchievementId)
	sounds.Achievement:Play()

	if not badgeInfo then
		return
	end

	local achievementUi = gui.Achievement:Clone()
	achievementUi.Name = "ActiveAchievement"
	achievementUi.Parent = gui
	achievementUi.Title.Text = badgeInfo.Name
	achievementUi.Description.Text = badgeInfo.Description
	achievementUi.Icon.Image = "rbxassetid://" .. badgeInfo.IconImageId
	achievementUi.Position = UDim2.fromScale(1, 1.2)

	achievementUi.Visible = true

	Util.tween(achievementUi, ti, { Position = UDim2.fromScale(1, 1) }, false, function()
		task.wait(5)
		Util.tween(achievementUi, ti, { Position = UDim2.fromScale(1, 1.2) }, true)
		achievementUi:Destroy()
	end)
end

local function showBadgeError(errorMessage: string)
	local errorMessageLabel: TextLabel = gui.ErrorMessage
	errorMessageLabel.Text = errorMessage
	errorMessageLabel.Visible = true
	task.delay(8, function()
		errorMessageLabel.Visible = false
	end)
	error("CLIENT: " .. errorMessage)
end

function Achievements:AwardAchievement(achievementId: number)
	local result, errorMessage = Net:Invoke("AwardAchievement", achievementId)
	if errorMessage then
		showBadgeError(errorMessage)
	end

	if result then
		showAwardedAchievement(achievementId)
	end
end

function Achievements:Init()
	gui.Parent = Players.LocalPlayer.PlayerGui

	task.delay(1, function()
		StarterGui:SetCore("BadgesNotificationsActive", false)
	end)
end

--// Main //--
return Achievements
