local AwardAchievements = {}

--// Services
local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.Packages.Net)

--// Instances

--// Modules

--// Values

--// Functions
local function awardBadge(player, badgeId)
	-- Fetch badge information
	local success, badgeInfo = pcall(function()
		return BadgeService:GetBadgeInfoAsync(badgeId)
	end)

	if success then
		-- Confirm that badge can be awarded
		if badgeInfo.IsEnabled then
			-- Award badge
			local awardSuccess, result = pcall(function()
				return BadgeService:AwardBadge(player.UserId, badgeId)
			end)

			if not awardSuccess then
				-- the AwardBadge function threw an error
				local errorMsg = "Error while awarding badge: " .. result
				warn(errorMsg)
				return false, errorMsg
			elseif not result then
				-- the AwardBadge function did not award a badge
				warn("Failed to award badge.", success, result)
				return false
			end
		end

		return badgeInfo.IsEnabled
	else
		local errorMsg = "Error while fetching badge info: " .. badgeInfo
		warn(errorMsg)
		return false, errorMsg
	end
end

function AwardAchievements:Init()
	--Prestart Code
end

function AwardAchievements:Start()
	--Start Code
end

--// Main //--

Net:Handle("AwardAchievement", awardBadge)
return AwardAchievements
