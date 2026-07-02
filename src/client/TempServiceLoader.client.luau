--!strict
--[[ SERVICES ]]--
task.wait(5)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Services = Shared.Services
require(Services)

print(Services:GetChildren())
task.wait(15)

local Players = game:GetService("Players")
local player = Players.LocalPlayer :: Player

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid") :: Humanoid

humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
humanoid:ChangeState(Enum.HumanoidStateType.Ragdoll)

task.wait(11111111111)


humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
