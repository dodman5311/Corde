local ReplicatedStorage = game:GetService("ReplicatedStorage")
local musicService = {
	playingTrack = nil,
}
--// Services

--// Instances
local assets = ReplicatedStorage.Assets
local music = assets.Music

--// Modules
local util = require(script.Parent.Util)

--// Values
local DEFAULT_FADE_TIME = 0.5
local lastTrack

function musicService:StopTrack(fadeTime: number?): Sound?
	if not musicService.playingTrack then
		return
	end
	fadeTime = fadeTime or DEFAULT_FADE_TIME

	local ti = TweenInfo.new(fadeTime, Enum.EasingStyle.Linear)
	local trackToStop: Sound = musicService.playingTrack

	lastTrack = trackToStop
	musicService.playingTrack = nil

	if fadeTime == 0 then
		trackToStop:Stop()
		return trackToStop
	end

	util.tween(trackToStop, ti, { Volume = 0 }, false, function()
		trackToStop:Pause()
	end, Enum.PlaybackState.Completed)
	return trackToStop
end

function musicService:PlayTrack(trackName: string, fadeTime: number?): Sound?
	if not trackName or (musicService.playingTrack and trackName == musicService.playingTrack.Name) then
		return
	end
	fadeTime = fadeTime or DEFAULT_FADE_TIME

	local ti = TweenInfo.new(fadeTime, Enum.EasingStyle.Linear)
	local track: Sound = music:FindFirstChild(trackName)

	self:StopTrack()
	musicService.playingTrack = track

	if fadeTime == 0 then
		track.Volume = track:GetAttribute("Volume")
		track:Play()
		return track
	end

	track.Volume = 0
	track:Resume()
	util.tween(track, ti, { Volume = track:GetAttribute("Volume") })

	return track
end

function musicService:ReturnToLastTrack(): Sound?
	if not lastTrack then
		return
	end

	print(lastTrack)
	return self:PlayTrack(lastTrack.Name)
end

--// Main
for _, track in ipairs(music:GetChildren()) do
	track:SetAttribute("Volume", track.Volume)
end

workspace:GetAttributeChangedSignal("InCombat"):Connect(function()
	if workspace:GetAttribute("InCombat") then
		musicService:PlayTrack("SuddenDeath")
	else
		musicService:ReturnToLastTrack()
	end
end)

return musicService
