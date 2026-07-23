local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Emotes = require(script.Parent.Emotes)

local DapRequest = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("DapRequest")
local Player = Players.LocalPlayer



return {
	{
		Name = "DAP",
		Image = "Duo",
		Callback = function()
			DapRequest:FireServer(Player)
		end,
	},
	{
		Name = "HANDS",
		Image = "Duo",
		Callback = function(player)
			Emotes.playAnimation("rbxassetid://136563349276572", true)
		end,
	},
	{
		Name = "LEAN",
		Image = "Dance",
		Callback = function(player)
			Emotes.playAnimation("rbxassetid://75348927382723", true)
		end,
	},
	{
		Name = "POSE 1",
		Image = "Dance",
		Callback = function(player)
			Emotes.playAnimation("rbxassetid://89563091064417", true)
		end,
	},
	{
		Name = "POSE 2",
		Image = "Dance",
		Callback = function(player)
			Emotes.playAnimation("rbxassetid://129570503190870", true)
		end,
	},
	{
		Name = "POSE 3",
		Image = "Dance",
		Callback = function(player)
			Emotes.playAnimation("rbxassetid://109079336438861", true)
		end,
	},
	{
		Name = "POSE 4",
		Image = "Dance",
		Callback = function(player)
			Emotes.playAnimation("rbxassetid://138755796413060", true)
		end,
	},
	{
		Name = "STURDY",
		Image = "Dance",
		Callback = function(player)
			Emotes.playAnimation("rbxassetid://137506721556358")
		end,
	},
	{
		Name = "SCUBA",
		Image = "Dance",
		Callback = function(player)
			Emotes.playAnimation("rbxassetid://75895742967558")
			--StartRobbery:FireServer(player)
		end,
	},
	{
		Name = "WOO",
		Image = "Dance",
		Callback = function(player)
			Emotes.playAnimation("rbxassetid://115789692138129")
		end,
	},
	{
		Name = "TYLIL DANCE",
		Image = "Dance",
		Callback = function(player)
			Emotes.playAnimation("rbxassetid://74053384644180")
		end,
	},
	{
		Name = "MURDA BEND",
		Image = "Dance",
		Callback = function(player)
			Emotes.playAnimation("rbxassetid://101959866221659")
		end,
	},
	{
		Name = "ZESTY",
		Image = "Dance",
		Callback = function(player)
			Emotes.playAnimation("rbxassetid://111104464070868")
		end,
	},
	{
		Name = "JIGG",
		Image = "Dance",
		Callback = function(player)
			Emotes.playAnimation("rbxassetid://83903388914144")
		end,
	},
	{
		Name = "JERSEY DANCE",
		Image = "Dance",
		Callback = function(player)
			Emotes.playAnimation("rbxassetid://126528839643058")
		end,
	},
	{
		Name = "CAMDEN BOP",
		Image = "Dance",
		Callback = function(player)
			Emotes.playAnimation("rbxassetid://85329378752179")
		end,
	},
	{
		Name = "TURN UP",
		Image = "Dance",
		Callback = function(player)
			Emotes.playAnimation("rbxassetid://97291415117779")
		end,
	},
	{
		Name = "DOUGIE",
		Image = "Dance",
		Callback = function(player)
			Emotes.playAnimation("rbxassetid://81845227195500")
		end,
	},
	{
		Name = "GROOVE DANCE",
		Image = "Dance",
		Callback = function(player)
			Emotes.playAnimation("rbxassetid://119812751030761")
		end,
	},
}
