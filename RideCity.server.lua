-- Ride City: motorbike + e-scooter arcade sandbox
-- Paste this whole script into ServerScriptService in Roblox Studio (Baseplate template).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local VEHICLES = {
	moto = {
		name = "MOTORBIKE",
		color = Color3.fromRGB(210, 45, 45),
		chassisSize = Vector3.new(2, 0.8, 6),
		wheelSize = Vector3.new(0.6, 1.8, 1.8),
		wheelGap = 2.6,
		speed = 55,
		steerAngle = 26,
		seatZ = 0.2,
		torque = 4000,
	},
	scooter = {
		name = "E-SCOOTER",
		color = Color3.fromRGB(45, 170, 95),
		chassisSize = Vector3.new(2, 0.6, 4.4),
		wheelSize = Vector3.new(0.5, 1.4, 1.4),
		wheelGap = 1.7,
		speed = 32,
		steerAngle = 34,
		seatZ = -0.2,
		torque = 2000,
	},
}

local vehicleFolder = Instance.new("Folder")
vehicleFolder.Name = "RideVehicles"
vehicleFolder.Parent = workspace

local coinFolder = Instance.new("Folder")
coinFolder.Name = "RideCoins"
coinFolder.Parent = workspace

local function makePart(className, props, parent)
	local part = Instance.new(className)
	part.Anchored = true
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in props do
		part[key] = value
	end
	part.Parent = parent
	return part
end

local function makeWeld(partA, partB)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = partA
	weld.Part1 = partB
	weld.Parent = partA
	return weld
end

local function buildMap()
	local map = Instance.new("Folder")
	map.Name = "RideMap"
	map.Parent = workspace

	local base = workspace:FindFirstChild("Baseplate")
	if base then
		base.Material = Enum.Material.Asphalt
		base.Color = Color3.fromRGB(78, 80, 84)
	end

	makePart("SpawnLocation", {
		Name = "PlayerSpawn",
		Size = Vector3.new(26, 1, 18),
		CFrame = CFrame.new(0, 0.5, 24),
		Material = Enum.Material.Grass,
		Color = Color3.fromRGB(70, 140, 70),
	}, map)

	local roads = {
		{Vector3.new(420, 1, 24), CFrame.new(0, 0.5, 0)},
		{Vector3.new(24, 1, 420), CFrame.new(0, 0.5, 0)},
		{Vector3.new(420, 1, 24), CFrame.new(0, 0.5, 160)},
		{Vector3.new(420, 1, 24), CFrame.new(0, 0.5, -160)},
		{Vector3.new(24, 1, 420), CFrame.new(160, 0.5, 0)},
		{Vector3.new(24, 1, 420), CFrame.new(-160, 0.5, 0)},
	}
	for _, road in roads do
		makePart("Part", {
			Name = "Road",
			Size = road[1],
			CFrame = road[2],
			Material = Enum.Material.Asphalt,
			Color = Color3.fromRGB(30, 30, 33),
		}, map)
	end

	makePart("WedgePart", {
		Name = "JumpRampNorth",
		Size = Vector3.new(20, 4, 30),
		CFrame = CFrame.new(0, 3, -85) * CFrame.Angles(0, math.rad(180), 0),
		Material = Enum.Material.Concrete,
		Color = Color3.fromRGB(190, 150, 60),
	}, map)

	makePart("WedgePart", {
		Name = "JumpRampWest",
		Size = Vector3.new(30, 4, 20),
		CFrame = CFrame.new(-85, 3, 0) * CFrame.Angles(0, math.rad(-90), 0),
		Material = Enum.Material.Concrete,
		Color = Color3.fromRGB(190, 150, 60),
	}, map)

	for i = 1, 12 do
		makePart("Part", {
			Name = "Cone",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(1.5, 1.5, 1.5),
			CFrame = CFrame.new(110 + ((i - 1) % 6) * 18, 1.8, 60 + math.floor((i - 1) / 6) * 14),
			Color = Color3.fromRGB(250, 130, 50),
			Anchored = false,
			CustomPhysicalProperties = PhysicalProperties.new(0.3, 0.5, 0.2),
		}, map)
	end
end

local function buildVehicle(kind, groundPosition)
	local info = VEHICLES[kind]
	local wheelRadius = info.wheelSize.Y / 2
	local chassisHalf = Vector3.new(info.chassisSize.X / 2, info.chassisSize.Y / 2, info.chassisSize.Z / 2)
	local chassisCFrame = CFrame.new(groundPosition + Vector3.new(0, wheelRadius + 0.3 + chassisHalf.Y, 0))
	local wheelY = -(0.3 + chassisHalf.Y)
	local frontZ = -info.wheelGap
	local rearZ = info.wheelGap

	local model = Instance.new("Model")
	model.Name = kind
	model:SetAttribute("SpawnPosition", groundPosition)

	local chassis = Instance.new("Part")
	chassis.Name = "Chassis"
	chassis.Size = info.chassisSize
	chassis.CFrame = chassisCFrame
	chassis.Color = info.color
	chassis.Material = Enum.Material.Metal
	chassis.Anchored = false
	chassis.Parent = model
	model.PrimaryPart = chassis

	local gyro = Instance.new("BodyGyro")
	gyro.Name = "RideGyro"
	gyro.MaxTorque = Vector3.new(0, 0, 150000)
	gyro.P = 2000
	gyro.D = 250
	gyro.CFrame = CFrame.new()
	gyro.Parent = chassis

	local seat = Instance.new("VehicleSeat")
	seat.Name = "DriverSeat"
	seat.Size = Vector3.new(2, 1, 1)
	seat.CFrame = chassisCFrame * CFrame.new(0, chassisHalf.Y + 0.5, info.seatZ)
	seat.Color = Color3.fromRGB(20, 20, 20)
	seat.Material = Enum.Material.Fabric
	seat.Anchored = false
	seat.HeadsUpDisplay = false
	seat.MaxSpeed = 0
	seat.Torque = 0
	seat.Parent = model
	makeWeld(chassis, seat)

	local tag = Instance.new("BillboardGui")
	tag.Size = UDim2.fromOffset(140, 40)
	tag.StudsOffset = Vector3.new(0, 2.8, 0)
	tag.Parent = seat

	local tagText = Instance.new("TextLabel")
	tagText.Size = UDim2.fromScale(1, 1)
	tagText.BackgroundTransparency = 1
	tagText.Font = Enum.Font.GothamBold
	tagText.TextScaled = true
	tagText.TextColor3 = Color3.fromRGB(255, 255, 255)
	tagText.TextStrokeTransparency = 0.4
	tagText.Text = info.name
	tagText.Parent = tag

	local headlight = Instance.new("Part")
	headlight.Name = "Headlight"
	headlight.Size = Vector3.new(1, 0.5, 0.4)
	headlight.CFrame = chassisCFrame * CFrame.new(0, chassisHalf.Y + 0.4, -(chassisHalf.Z + 0.2))
	headlight.Color = Color3.fromRGB(255, 235, 140)
	headlight.Material = Enum.Material.Neon
	headlight.Anchored = false
	headlight.CanCollide = false
	headlight.Parent = model
	makeWeld(chassis, headlight)

	local fork = Instance.new("Part")
	fork.Name = "Fork"
	fork.Size = Vector3.new(0.4, 2.2, 0.4)
	fork.CFrame = chassisCFrame * CFrame.new(0, wheelY + 0.95, frontZ)
	fork.Color = Color3.fromRGB(70, 72, 78)
	fork.Material = Enum.Material.Metal
	fork.Anchored = false
	fork.Parent = model

	local bar = Instance.new("Part")
	bar.Name = "Handlebar"
	bar.Size = Vector3.new(2, 0.3, 0.3)
	bar.CFrame = fork.CFrame * CFrame.new(0, 1.2, 0)
	bar.Color = Color3.fromRGB(30, 30, 32)
	bar.Material = Enum.Material.Metal
	bar.Anchored = false
	bar.CanCollide = false
	bar.Parent = model
	makeWeld(fork, bar)

	local steerChassisAtt = Instance.new("Attachment")
	steerChassisAtt.Name = "SteerBase"
	steerChassisAtt.Position = Vector3.new(0, wheelY + 0.95, frontZ)
	steerChassisAtt.Orientation = Vector3.new(0, 0, 90)
	steerChassisAtt.Parent = chassis

	local steerForkAtt = Instance.new("Attachment")
	steerForkAtt.Name = "SteerFork"
	steerForkAtt.Orientation = Vector3.new(0, 0, 90)
	steerForkAtt.Parent = fork

	local steerHinge = Instance.new("HingeConstraint")
	steerHinge.Name = "SteerHinge"
	steerHinge.Attachment0 = steerChassisAtt
	steerHinge.Attachment1 = steerForkAtt
	steerHinge.ActuatorType = Enum.ActuatorType.Servo
	steerHinge.ServoMaxTorque = 1000000
	steerHinge.AngularSpeed = 12
	steerHinge.TargetAngle = 0
	steerHinge.Parent = chassis

	local function makeWheel(localZ, isFront)
		local wheel = Instance.new("Part")
		wheel.Name = isFront and "FrontWheel" or "RearWheel"
		wheel.Shape = Enum.PartType.Cylinder
		wheel.Size = info.wheelSize
		wheel.CFrame = chassisCFrame * CFrame.new(0, wheelY, localZ)
		wheel.Color = Color3.fromRGB(28, 28, 30)
		wheel.Material = Enum.Material.Rubber
		wheel.Anchored = false
		wheel.CustomPhysicalProperties = PhysicalProperties.new(1, 1.4, 0.05)
		wheel.Parent = model

		local holderAtt = Instance.new("Attachment")
		holderAtt.Position = isFront and Vector3.new(0, -0.95, 0) or Vector3.new(0, wheelY, localZ)
		holderAtt.Parent = isFront and fork or chassis

		local wheelAtt = Instance.new("Attachment")
		wheelAtt.Parent = wheel

		local hinge = Instance.new("HingeConstraint")
		hinge.Attachment0 = holderAtt
		hinge.Attachment1 = wheelAtt
		if isFront then
			hinge.Name = "FrontHinge"
			hinge.ActuatorType = Enum.ActuatorType.None
		else
			hinge.Name = "DriveHinge"
			hinge.ActuatorType = Enum.ActuatorType.Motor
			hinge.MotorMaxTorque = info.torque
			hinge.AngularVelocity = 0
		end
		hinge.Parent = isFront and fork or chassis
	end

	makeWheel(frontZ, true)
	makeWheel(rearZ, false)

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Respawn"
	prompt.ObjectText = info.name
	prompt.HoldDuration = 0.25
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = seat
	prompt.Triggered:Connect(function()
		buildVehicle(kind, model:GetAttribute("SpawnPosition"))
		model:Destroy()
	end)

	model.Parent = vehicleFolder
end

local function spawnCoin(position)
	local coin = makePart("Part", {
		Name = "Coin",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(3, 3, 3),
		CFrame = CFrame.new(position),
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 200, 40),
		CanCollide = false,
	}, coinFolder)

	local bob = TweenService:Create(coin, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Position = position + Vector3.new(0, 1, 0)})
	bob:Play()

	coin.Touched:Connect(function(hit)
		local model = hit and hit:FindFirstAncestorOfClass("Model")
		if not model then
			return
		end
		local player = Players:GetPlayerFromCharacter(model)
		if not player then
			local seat = model:FindFirstChildOfClass("VehicleSeat")
			local humanoid = seat and seat.Occupant
			player = humanoid and Players:GetPlayerFromCharacter(humanoid.Parent)
		end
		if not player then
			return
		end
		local stats = player:FindFirstChild("leaderstats")
		local coins = stats and stats:FindFirstChild("Coins")
		if coins then
			coins.Value += 1
		end
		coin:Destroy()
		task.delay(20, function()
			spawnCoin(position)
		end)
	end)
end

local function buildCoins()
	local coinPositions = {}
	for step = -3, 3 do
		table.insert(coinPositions, Vector3.new(step * 70, 3, 0))
		table.insert(coinPositions, Vector3.new(0, 3, step * 70))
		table.insert(coinPositions, Vector3.new(160, 3, step * 60))
		table.insert(coinPositions, Vector3.new(-160, 3, step * 60))
	end
	for step = 1, 6 do
		table.insert(coinPositions, Vector3.new(0, 6.5, -112 - step * 3))
		table.insert(coinPositions, Vector3.new(-112 - step * 3, 6.5, 0))
	end
	for _, position in coinPositions do
		spawnCoin(position)
	end
end

Players.PlayerAdded:Connect(function(player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	stats.Parent = player

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Parent = stats
end)

RunService.Heartbeat:Connect(function()
	for _, model in vehicleFolder:GetChildren() do
		local seat = model:FindFirstChild("DriverSeat", true)
		local drive = model:FindFirstChild("DriveHinge", true)
		local steer = model:FindFirstChild("SteerHinge", true)
		if seat and drive and steer then
			local info = VEHICLES[model.Name]
			if info then
				local occupied = seat.Occupant ~= nil
				drive.AngularVelocity = occupied and -seat.Throttle * info.speed or 0
				steer.TargetAngle = occupied and -seat.Steer * info.steerAngle or 0
			end
		end
	end
end)

buildMap()
buildVehicle("moto", Vector3.new(-4, 1, 10))
buildVehicle("scooter", Vector3.new(4, 1, 10))
buildCoins()

print("Ride City loaded: motorbike and e-scooter ready at spawn")
