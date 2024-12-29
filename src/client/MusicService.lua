local ReplicatedStorage = game:GetService("ReplicatedStorage")
local musicService = {}
--// Services

--// Instances
local assets = ReplicatedStorage.Assets
local music = assets.Music

--// Modules
local util = require(script.Parent.Util)

--// Values
local DEFAULT_FADE_TIME = 0.25
local lastTrack
local currentTrack

function musicService:StopTrack(fadeTime: number?): Sound?
	if not currentTrack then
		return
	end
	fadeTime = fadeTime or DEFAULT_FADE_TIME

	local ti = TweenInfo.new(fadeTime, Enum.EasingStyle.Linear)
	local trackToStop: Sound = currentTrack

	lastTrack = trackToStop
	currentTrack = nil

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
	if not trackName or (currentTrack and trackName == currentTrack.Name) then
		return
	end
	fadeTime = fadeTime or DEFAULT_FADE_TIME

	local ti = TweenInfo.new(fadeTime, Enum.EasingStyle.Linear)
	local track: Sound = music:FindFirstChild(trackName)

	self:StopTrack()
	currentTrack = track

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
	self:StopTrack()
	self:PlayTrack(lastTrack.Name)
	return lastTrack
end

--// Main
for _, track in ipairs(music:GetChildren()) do
	track:SetAttribute("Volume", track.Volume)
end

return musicService
