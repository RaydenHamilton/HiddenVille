local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Cache references
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Modules = ReplicatedStorage:WaitForChild("Modules")

local PlayAudio = Remotes:WaitForChild("PlayAudio")
local VisualizeBullet = Remotes:WaitForChild("VisualizeBullet")
local VisualizeHitEffect = Remotes:WaitForChild("VisualizeHitEffect")

local ProjectileHandler = require(script.Parent.ProjectileHandler)
local AudioHandler = require(Modules:WaitForChild("AudioHandler"))

-- Audio
local function PlayReplicatedAudio(audio, replicate)
	if not audio then
		return
	end
	AudioHandler:PlayAudio(audio, replicate)
end

-- Projectile simulation
local function SimulateReplicatedProjectile(
	tool,
	handle,
	vmHandle,
	clientModule,
	clDirections,
	svDirections,
	firePoint,
	muzzlePoint,
	miscs,
	replicate
)
	if not tool or not handle then
		return
	end
	ProjectileHandler:SimulateProjectile(
		tool,
		handle,
		vmHandle,
		clientModule,
		clDirections,
		svDirections,
		firePoint,
		muzzlePoint,
		miscs,
		replicate
	)
end

-- Hit effects
local function VisualizeReplicatedHitEffect(effectType, hit, position, normal, material, clientModule, miscs, replicate)
	if not effectType or not position then
		return
	end
	ProjectileHandler:VisualizeHitEffect(effectType, hit, position, normal, material, clientModule, miscs, replicate)
end

local gunSimulate = {}

function gunSimulate.init()
	-- Connections
	PlayAudio.OnClientEvent:Connect(PlayReplicatedAudio)
	VisualizeBullet.OnClientEvent:Connect(SimulateReplicatedProjectile)
	VisualizeHitEffect.OnClientEvent:Connect(VisualizeReplicatedHitEffect)
end
return gunSimulate
