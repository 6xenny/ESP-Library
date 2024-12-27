local ESP = {
	Enabled = false,
	Players = true,
	Names = true,
	Distance = false,
	UseMeDistance = false,
	MaxMeDistance = math.huge,
	Boxes = true,
	Health = true,
	HealthOffsetX = 4,
	HealthOffsetY = - 2,
	Items = false,
	ItemOffset = 10,
	Chams = false,
	ChamsTransparency = .5,
	ChamsOutlineTransparency = 0,
	ChamsOutlineColor = Color3.fromRGB(255, 255, 255),
	Tracers = false,
	Origin = "Bottom",
	Skeleton = false,
	PP = false,
	PPSize = 40,
	OutOfViewArrows = false,
	OutOfViewArrowsRadius = 100,
	OutOfViewArrowsSize = 25,
	OutOfViewArrowsOutline = false,
	OutOfViewArrowsOutlineColor = Color3.fromRGB(255, 255, 255),
	FaceCamera = false,
	TeamColor = true,
	TeamMates = true,
	Font = "Plex",
	TextSize = 19,
	BoxShift = CFrame.new(0, - 1.5, 0),
	BoxSize = Vector3.new(4, 6, 0),
	Color = Color3.fromRGB(0, 166, 255),
	HighlightColor = Color3.new(1, 1, 1),
	ScreenScale = 1,
	Thickness = 2,
	AttachShift = 1,
	Bars = false,
	GlobalBars = {},
	HrpName = "HumanoidRootPart",
	Objects = setmetatable({}, {
		__mode = "kv"
	}),
	Render = setmetatable({}, {
		__mode = "kv"
	}),
	Overrides = {},
	UseRenderValue = true,
	RenderValue = 200
}
getgenv().shared.ESP = ESP
if ... and type(...) == "table" then
	for i, v in next, ... do
		ESP[i] = v
	end
end
local cam = workspace.CurrentCamera
local Players, UIS = game:GetService("Players"), game:GetService("UserInputService")
local Me = Players.LocalPlayer
local mouse = Me:GetMouse()
local WorldToViewportPoint = cam.WorldToViewportPoint
local PointToObjectSpace = CFrame.new().PointToObjectSpace
local Cross = Vector3.new().Cross
local Folder = Instance.new("Folder", game.CoreGui)
local chars = {}
local lastFov, lastScale = nil, nil
for i = 17700, 17800 do
	chars[# chars + 1] = utf8.char(i)
end
for i = 160, 700 do
	chars[# chars + 1] = utf8.char(i)
end
function GenerateName(x)
	local e = ""
	for _ = 1, tonumber(x) or math.random(10, 999) do
		e = e .. chars[math.random(1, # chars)]
	end
	return e
end
function round(number)
	return typeof(number) == "Vector2" and Vector2.new(round(number.X), round(number.Y)) or math.floor(number)
end
function GetScaleFactor(fov, depth)
	if (fov ~= lastFov) then
		lastScale = math.tan(math.rad(fov * .5)) * 2
		lastFov = fov
	end
	return 1 / (depth * lastScale) * 1e3
end
function BrahWth(position)
	local screenPosition, onScreen = WorldToViewportPoint(cam, position)
	return Vector2.new(screenPosition.X, screenPosition.Y), onScreen, screenPosition.Z
end
function GetBoundingBox(torso)
	local torsoPosition, onScreen, depth = BrahWth(torso.Position)
	local scaleFactor = GetScaleFactor(cam.FieldOfView, depth)
	local size = round(Vector2.new(4 * scaleFactor, 5 * scaleFactor))
	return onScreen, size, round(Vector2.new(torsoPosition.X - (size.X * .5), torsoPosition.Y - (size.Y * .5))), torsoPosition
end
local function Draw(obj, props)
	local new = Drawing.new(obj)
	props = props or {}
	for i, v in next, props do
		new[i] = v
	end
	return new
end
function ESP.FOVCircle(radius)
	local FOVCircle = Drawing.new("Circle")
	FOVCircle.Radius = radius
	FOVCircle.Color = Color3.fromRGB(0, 166, 255)
	FOVCircle.Thickness = 3
	FOVCircle.Filled = false
	local CircleTbl = {
		Update = function()
			FOVCircle.Position = UIS:GetMouseLocation()
		end
	}
	table.insert(ESP.Objects, CircleTbl)
	return {
		Drawing = FOVCircle,
		Tbl = CircleTbl,
		Update = CircleTbl.Update
	}
end
function ESP:GetTeam(p)
	local ov = self.Overrides.GetTeam
	if ov then
		return ov(p)
	end
	return p and p.Team
end
function ESP:IsTeamMate(p)
	local ov = self.Overrides.IsTeamMate
	if ov then
		return ov(p)
	end
	return self:GetTeam(p) == self:GetTeam(Me)
end
function ESP:GetColor(obj)
	local ov = self.Overrides.GetColor
	if ov then
		return ov(obj)
	end
	local p = self:GetMeFromChar(obj)
	return p and self.TeamColor and p.Team and p.Team.TeamColor.Color or self.Color
end
function ESP:GetMeFromChar(char)
	local ov = self.Overrides.GetMeFromChar
	if ov then
		return ov(char)
	end
	
	return Players:GetPlayerFromCharacter(char)
end
function ESP:Toggle(bool)
	self.Enabled = bool
	if not bool then
		for i, v in next, self.Objects do
			if v.Type == "Box" then
				if v.Temporary then
					v:Remove()
				else
					for i, v in next, v.Components do
						if i == "Highlight" then
							v.Enabled = false
						else
							v.Visible = false
						end
					end
				end
			end
		end
	end
end
function ESP:GetBox(obj)
	return self.Objects[obj]
end
function ESP:AddObjectListener(parent, options)
	local function NewListener(c)
		if type(options.Type) == "string" and c:IsA(options.Type) or options.Type == nil then
			if type(options.Name) == "string" and c.Name == options.Name or options.Name == nil then
				if not options.Validator or options.Validator(c) then
					local box = ESP:Add(c, {
						PrimaryPart = type(options.PrimaryPart) == "string" and c:WaitForChild(options.PrimaryPart) or type(options.PrimaryPart) == "function" and options.PrimaryPart(c),
						Color = type(options.Color) == "function" and options.Color(c) or options.Color,
						ColorDynamic = options.ColorDynamic,
						Name = type(options.CustomName) == "function" and options.CustomName(c) or options.CustomName,
						IsEnabled = options.IsEnabled,
						RenderInNil = options.RenderInNil
					})
					if options.OnAdded then
						coroutine.wrap(options.OnAdded)(box)
					end
				end
			end
		end
	end
	if options.Recursive then
		parent.DescendantAdded:Connect(NewListener)
		for i, v in next, parent:GetDescendants() do
			coroutine.wrap(NewListener)(v)
		end
	else
		parent.ChildAdded:Connect(NewListener)
		for i, v in next, parent:GetChildren() do
			coroutine.wrap(NewListener)(v)
		end
	end
end
function ESP:AddGlobalPlayerBar(name, options, onAdded)
	table.insert(self.GlobalBars, {
		name,
		options,
		onAdded
	})
	for i, box in next, self.Objects do
		if box.Player then
			coroutine.wrap(onAdded)(box, box:AddBar(name, options))
		end
	end
end
local boxBase = {}
boxBase.__index = boxBase
function boxBase:Remove()
	ESP.Objects[self.Object] = nil
	for i, v in next, self.Components do
		if i == "Highlight" then
			v.Enabled = false
			v:Remove()
		else
			v.Visible = false
			v:Remove()
		end
		self.Components[i] = nil
	end
end
function boxBase:Update()
	if not self.PrimaryPart then
		return self:Remove()
	end
	local color
	if ESP.Highlighted == self.Object then
		color = ESP.HighlightColor
	else
		color = self.Color or self.ColorDynamic and self:ColorDynamic() or ESP:GetColor(self.Object) or ESP.Color
	end

	local allow = true
	if ESP.Overrides.UpdateAllow and not ESP.Overrides.UpdateAllow(self) then
		allow = false
	end
	if self.Player and not ESP.TeamMates and ESP:IsTeamMate(self.Player) then
		allow = false
	end
	if self.Player and not ESP.Players then
		allow = false
	end
	if self.IsEnabled and (type(self.IsEnabled) == "string" and not ESP[self.IsEnabled] or type(self.IsEnabled) == "function" and not self:IsEnabled()) then
		allow = false
	end
	if not workspace:IsAncestorOf(self.PrimaryPart) and not self.RenderInNil then
		allow = false
	end
	if not allow then
		for i, v in next, self.Components do
			if i == "Highlight" then
				v.Enabled = false
			else
				v.Visible = false
			end
		end
		return
	end
	if ESP.Highlighted == self.Object then
		color = ESP.HighlightColor
	end
	local IsMeHighlighted = (ESP.Highlighted == self.Object and self.Player ~= nil)
	local cf = self.PrimaryPart.CFrame
	if ESP.FaceCamera then
		cf = CFrame.new(cf.Position, cam.CFrame.Position)
	end
	local distance = math.floor((cam.CFrame.Position - cf.Position).magnitude)
	if self.Player and ESP.UseMeDistance and distance > ESP.MaxMeDistance then
		for i, v in next, self.Components do
			if i == "Highlight" then
				v.Enabled = false
			else
				v.Visible = false
			end
		end
		return
	end
	self.Distance = distance
	local size = self.Size
	local locs = {
		TopLeft = cf * ESP.BoxShift * CFrame.new(size.X / 2, size.Y / 2, 0),
		TopRight = cf * ESP.BoxShift * CFrame.new(- size.X / 2, size.Y / 2, 0),
		BottomLeft = cf * ESP.BoxShift * CFrame.new(size.X / 2, - size.Y / 2, 0),
		BottomRight = cf * ESP.BoxShift * CFrame.new(- size.X / 2, - size.Y / 2, 0),
		TagPos = cf * ESP.BoxShift * CFrame.new(0, size.Y / 2, 0),
		Torso = cf
	}
	if ESP.Boxes then
		local onScreen, size, position = GetBoundingBox(locs.Torso)
		if self.Components.Box and self.Components.BoxOutline and self.Components.BoxFill then
			if onScreen and position and size then
				self.Components.Box.Visible = true
				self.Components.Box.Color = color
				self.Components.Box.Size = size
				self.Components.Box.Position = position
				self.Components.BoxOutline.Visible = true
				self.Components.BoxOutline.Size = size
				self.Components.BoxOutline.Position = position
				self.Components.BoxFill.Visible = true
				self.Components.BoxFill.Color = color
				self.Components.BoxFill.Size = size
				self.Components.BoxFill.Position = position
			else
				self.Components.Box.Visible = false
				self.Components.BoxOutline.Visible = false
				self.Components.BoxFill.Visible = false
			end
		end
	else
		self.Components.Box.Visible = false
		self.Components.BoxOutline.Visible = false
		self.Components.BoxFill.Visible = false
	end
	if ESP.Names then
		local onScreen, size, position = GetBoundingBox(locs.Torso)
		if onScreen and size and position then
			self.Components.Name.Visible = true
			self.Components.Name.Position = round(position + Vector2.new(size.X * .5, - (self.Components.Name.TextBounds.Y + 2)))
			self.Components.Name.Text = self.Name
			self.Components.Name.Color = color
		else
			self.Components.Name.Visible = false
		end
	else
		self.Components.Name.Visible = false
	end
	if ESP.Distance then
		local onScreen, size, position = GetBoundingBox(locs.Torso)
		if onScreen and size and position then
			self.Components.Distance.Visible = true
			self.Components.Distance.Position = round(position + Vector2.new(size.X * .5, size.Y + 1))
			self.Components.Distance.Text = math.floor((cam.CFrame.Position - cf.Position).magnitude) .. "m"
			self.Components.Distance.Color = color
		else
			self.Components.Distance.Visible = false
		end
	else
		self.Components.Distance.Visible = false
	end
	if ESP.Tracers then
		local TorsoPos, Vis7 = WorldToViewportPoint(cam, locs.Torso.Position)
		if Vis7 then
			self.Components.Tracer.Visible = true
			self.Components.Tracer.From = Vector2.new(TorsoPos.X, TorsoPos.Y)
			self.Components.Tracer.To = ESP.Origin == "Mouse" and UIS:GetMouseLocation() or ESP.Origin == "Bottom" and Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / ESP.AttachShift)
			self.Components.Tracer.Color = color
			self.Components["Tracer"].ZIndex = IsMeHighlighted and 2 or 1
		else
			self.Components.Tracer.Visible = false
		end
	else
		self.Components.Tracer.Visible = false
	end
	if ESP.Bars and ESP.FaceCamera then
		if not ESP.Boxes then
			TopLeft, Vis1 = WorldToViewportPoint(cam, locs.TopLeft.p)
			BottomLeft, Vis3 = WorldToViewportPoint(cam, locs.BottomLeft.p)
		end
		local amount = 0
		for i, v in next, self.Bars do
			if (Vis1 or Vis3) and v.Value < 1 then
				local x = TopLeft.X - amount * 5 - 3
				local barWidth = 4
				local barPadding = 1
				v.Components.BarBackground.Visible = true
				v.Components.BarBackground.PointA = Vector2.new(x, TopLeft.Y)
				v.Components.BarBackground.PointB = Vector2.new(x - barWidth, TopLeft.Y)
				v.Components.BarBackground.PointC = Vector2.new(x - barWidth, BottomLeft.Y)
				v.Components.BarBackground.PointD = Vector2.new(x, BottomLeft.Y)
				v.Components.Bar.Visible = true
				v.Components.Bar.Color = v.Color
				local height = (BottomLeft.Y - TopLeft.Y - barPadding * 2) * (1 - v.Value)
				v.Components.Bar.PointA = Vector2.new(x - barPadding, TopLeft.Y + height + barPadding)
				v.Components.Bar.PointB = Vector2.new(x - barWidth + barPadding, TopLeft.Y + height + barPadding)
				v.Components.Bar.PointC = Vector2.new(x - barWidth + barPadding, BottomLeft.Y - barPadding)
				v.Components.Bar.PointD = Vector2.new(x - barPadding, BottomLeft.Y - barPadding)
				amount = amount + 1
			else
				v.Components.BarBackground.Visible = false
				v.Components.Bar.Visible = false
			end
		end
	else
		for i, v in next, self.Bars do
			v.Components.BarBackground.Visible = false
			v.Components.Bar.Visible = false
		end
	end
	if ESP.Health then
		local onScreen, size, position = GetBoundingBox(locs.Torso)
		if onScreen and size and position then
			if self.Object and self.Object:FindFirstChildOfClass("Humanoid") then
				local Health, MaxHealth = self.Object:FindFirstChildOfClass("Humanoid").Health, self.Object:FindFirstChildOfClass("Humanoid").MaxHealth
				local healthBarSize = round(Vector2.new(1, - (size.Y * (Health / MaxHealth))))
				local healthBarPosition = round(Vector2.new(position.X - (3 + healthBarSize.X), position.Y + size.Y))
				local g = Color3.fromRGB(0, 255, 8)
				local r = Color3.fromRGB(255, 0, 0)
				self.Components.HealthBar.Visible = true
				self.Components.HealthBar.Color = r:lerp(g, Health / MaxHealth)
				self.Components.HealthBar.Transparency = 1
				self.Components.HealthBar.Size = healthBarSize
				self.Components.HealthBar.Position = healthBarPosition
				self.Components.HealthBarOutline.Visible = true
				self.Components.HealthBarOutline.Transparency = 1
				self.Components.HealthBarOutline.Size = round(Vector2.new(healthBarSize.X, - size.Y) + Vector2.new(2, - 2))
				self.Components.HealthBarOutline.Position = healthBarPosition - Vector2.new(1, - 1)
				self.Components.HealthText.Visible = true
				self.Components.HealthText.Color = r:lerp(g, Health / MaxHealth)
				self.Components.HealthText.Text = math.floor(Health + .5) .. " | " .. MaxHealth
				self.Components.HealthText.Position = round(position + Vector2.new(size.X + 3, - 3))
			end
		else
			self.Components.HealthBar.Visible = false
			self.Components.HealthBarOutline.Visible = false
			self.Components.HealthText.Visible = false
		end
	else
		self.Components.HealthBar.Visible = false
		self.Components.HealthBarOutline.Visible = false
		self.Components.HealthText.Visible = false
	end
	if ESP.Items then
		local onScreen, size, position = GetBoundingBox(locs.Torso)
		if onScreen and size and position then
			if self.Object and self.Object:FindFirstChildOfClass("Tool") then
				self.Components.Items.Text = tostring(self.Object:FindFirstChildOfClass("Tool").Name)
				local ItemOffset = ESP.ItemOffset
				self.Components.Items.Position = round(position + Vector2.new(size.X * .5, size.Y - 50))
				self.Components.Items.Visible = true
				self.Components.Items.Color = color
			else
				self.Components.Items.Visible = false
			end
		else
			self.Components.Items.Visible = false
		end
	else
		self.Components.Items.Visible = false
	end
	if ESP.Skeleton then
		local TorsoPos, Vis10 = WorldToViewportPoint(cam, locs.Torso.Position)
		if Vis10 then
			if self.Object and self.Object:FindFirstChildOfClass("Humanoid") then
				if self.Object:FindFirstChildOfClass("Humanoid") and self.Object:FindFirstChildOfClass("Humanoid").RigType == Enum.HumanoidRigType.R15 then
					if self.Object and self.Object:FindFirstChild("Head") and self.Object:FindFirstChild("UpperTorso") and self.Object:FindFirstChild("LowerTorso") and self.Object:FindFirstChild("LeftUpperArm") and self.Object:FindFirstChild("LeftLowerArm") and self.Object:FindFirstChild("LeftHand") and self.Object:FindFirstChild("RightUpperArm") and self.Object:FindFirstChild("RightLowerArm") and self.Object:FindFirstChild("RightHand") and self.Object:FindFirstChild("LeftUpperLeg") and self.Object:FindFirstChild("LeftLowerLeg") and self.Object:FindFirstChild("LeftFoot") and self.Object:FindFirstChild("RightUpperLeg") and self.Object:FindFirstChild("RightLowerLeg") and self.Object:FindFirstChild("RightFoot") then
						local H = WorldToViewportPoint(cam, self.Object.Head.Position)
						local UT = WorldToViewportPoint(cam, self.Object.UpperTorso.Position)
						local LT = WorldToViewportPoint(cam, self.Object.LowerTorso.Position)
						local LUA = WorldToViewportPoint(cam, self.Object.LeftUpperArm.Position)
						local LLA = WorldToViewportPoint(cam, self.Object.LeftLowerArm.Position)
						local LH = WorldToViewportPoint(cam, self.Object.LeftHand.Position)
						local RUA = WorldToViewportPoint(cam, self.Object.RightUpperArm.Position)
						local RLA = WorldToViewportPoint(cam, self.Object.RightLowerArm.Position)
						local RH = WorldToViewportPoint(cam, self.Object.RightHand.Position)
						local LUL = WorldToViewportPoint(cam, self.Object.LeftUpperLeg.Position)
						local LLL = WorldToViewportPoint(cam, self.Object.LeftLowerLeg.Position)
						local LF = WorldToViewportPoint(cam, self.Object.LeftFoot.Position)
						local RUL = WorldToViewportPoint(cam, self.Object.RightUpperLeg.Position)
						local RLL = WorldToViewportPoint(cam, self.Object.RightLowerLeg.Position)
						local RF = WorldToViewportPoint(cam, self.Object.RightFoot.Position)
						self.Components.R15SkeleHeadUpperTorso.From = Vector2.new(H.X, H.Y)
						self.Components.R15SkeleHeadUpperTorso.To = Vector2.new(UT.X, UT.Y)
						self.Components.R15SkeleUpperTorsoLowerTorso.From = Vector2.new(UT.X, UT.Y)
						self.Components.R15SkeleUpperTorsoLowerTorso.To = Vector2.new(LT.X, LT.Y)
						self.Components.R15SkeleUpperTorsoLeftUpperArm.From = Vector2.new(UT.X, UT.Y)
						self.Components.R15SkeleUpperTorsoLeftUpperArm.To = Vector2.new(LUA.X, LUA.Y)
						self.Components.R15SkeleLeftUpperArmLeftLowerArm.From = Vector2.new(LUA.X, LUA.Y)
						self.Components.R15SkeleLeftUpperArmLeftLowerArm.To = Vector2.new(LLA.X, LLA.Y)
						self.Components.R15SkeleLeftLowerArmLeftHand.From = Vector2.new(LLA.X, LLA.Y)
						self.Components.R15SkeleLeftLowerArmLeftHand.To = Vector2.new(LH.X, LH.Y)
						self.Components.R15SkeleUpperTorsoRightUpperArm.From = Vector2.new(UT.X, UT.Y)
						self.Components.R15SkeleUpperTorsoRightUpperArm.To = Vector2.new(RUA.X, RUA.Y)
						self.Components.R15SkeleRightUpperArmRightLowerArm.From = Vector2.new(RUA.X, RUA.Y)
						self.Components.R15SkeleRightUpperArmRightLowerArm.To = Vector2.new(RLA.X, RLA.Y)
						self.Components.R15SkeleRightLowerArmRightHand.From = Vector2.new(RLA.X, RLA.Y)
						self.Components.R15SkeleRightLowerArmRightHand.To = Vector2.new(RH.X, RH.Y)
						self.Components.R15SkeleLowerTorsoLeftUpperLeg.From = Vector2.new(LT.X, LT.Y)
						self.Components.R15SkeleLowerTorsoLeftUpperLeg.To = Vector2.new(LUL.X, LUL.Y)
						self.Components.R15SkeleLeftUpperLegLeftLowerLeg.From = Vector2.new(LUL.X, LUL.Y)
						self.Components.R15SkeleLeftUpperLegLeftLowerLeg.To = Vector2.new(LLL.X, LLL.Y)
						self.Components.R15SkeleLeftLowerLegLeftFoot.From = Vector2.new(LLL.X, LLL.Y)
						self.Components.R15SkeleLeftLowerLegLeftFoot.To = Vector2.new(LF.X, LF.Y)
						self.Components.R15SkeleLowerTorsoRightUpperLeg.From = Vector2.new(LT.X, LT.Y)
						self.Components.R15SkeleLowerTorsoRightUpperLeg.To = Vector2.new(RUL.X, RUL.Y)
						self.Components.R15SkeleRightUpperLegRightLowerLeg.From = Vector2.new(RUL.X, RUL.Y)
						self.Components.R15SkeleRightUpperLegRightLowerLeg.To = Vector2.new(RLL.X, RLL.Y)
						self.Components.R15SkeleRightLowerLegRightFoot.From = Vector2.new(RLL.X, RLL.Y)
						self.Components.R15SkeleRightLowerLegRightFoot.To = Vector2.new(RF.X, RF.Y)
						self.Components.R15SkeleHeadUpperTorso.Color = color
						self.Components.R15SkeleUpperTorsoLowerTorso.Color = color
						self.Components.R15SkeleUpperTorsoLeftUpperArm.Color = color
						self.Components.R15SkeleLeftUpperArmLeftLowerArm.Color = color
						self.Components.R15SkeleLeftLowerArmLeftHand.Color = color
						self.Components.R15SkeleUpperTorsoRightUpperArm.Color = color
						self.Components.R15SkeleRightUpperArmRightLowerArm.Color = color
						self.Components.R15SkeleRightLowerArmRightHand.Color = color
						self.Components.R15SkeleLowerTorsoLeftUpperLeg.Color = color
						self.Components.R15SkeleLeftUpperLegLeftLowerLeg.Color = color
						self.Components.R15SkeleLeftLowerLegLeftFoot.Color = color
						self.Components.R15SkeleLowerTorsoRightUpperLeg.Color = color
						self.Components.R15SkeleRightUpperLegRightLowerLeg.Color = color
						self.Components.R15SkeleRightLowerLegRightFoot.Color = color
						self.Components.R15SkeleHeadUpperTorso.Visible = true
						self.Components.R15SkeleUpperTorsoLowerTorso.Visible = true
						self.Components.R15SkeleUpperTorsoLeftUpperArm.Visible = true
						self.Components.R15SkeleLeftUpperArmLeftLowerArm.Visible = true
						self.Components.R15SkeleLeftLowerArmLeftHand.Visible = true
						self.Components.R15SkeleUpperTorsoRightUpperArm.Visible = true
						self.Components.R15SkeleRightUpperArmRightLowerArm.Visible = true
						self.Components.R15SkeleRightLowerArmRightHand.Visible = true
						self.Components.R15SkeleLowerTorsoLeftUpperLeg.Visible = true
						self.Components.R15SkeleLeftUpperLegLeftLowerLeg.Visible = true
						self.Components.R15SkeleLeftLowerLegLeftFoot.Visible = true
						self.Components.R15SkeleLowerTorsoRightUpperLeg.Visible = true
						self.Components.R15SkeleRightUpperLegRightLowerLeg.Visible = true
						self.Components.R15SkeleRightLowerLegRightFoot.Visible = true
					end
				elseif self.Object:FindFirstChildOfClass("Humanoid") and self.Object:FindFirstChildOfClass("Humanoid").RigType == Enum.HumanoidRigType.R6 then
					if self.Object and self.Object:FindFirstChild("Head") and self.Object:FindFirstChild("Torso") and self.Object:FindFirstChild("Left Arm") and self.Object:FindFirstChild("Right Arm") and self.Object:FindFirstChild("Left Leg") and self.Object:FindFirstChild("Right Leg") then
						local H = WorldToViewportPoint(cam, self.Object.Head.Position)
						local T_Height = self.Object.Torso.Size.Y / 2 - .2
						local UT = WorldToViewportPoint(cam, (self.Object.Torso.CFrame * CFrame.new(0, T_Height, 0)).Position)
						local LT = WorldToViewportPoint(cam, (self.Object.Torso.CFrame * CFrame.new(0, - T_Height, 0)).Position)
						local LA_Height = self.Object["Left Arm"].Size.Y / 2 - .2
						local LUA = WorldToViewportPoint(cam, (self.Object["Left Arm"].CFrame * CFrame.new(0, LA_Height, 0)).Position)
						local LLA = WorldToViewportPoint(cam, (self.Object["Left Arm"].CFrame * CFrame.new(0, - LA_Height, 0)).Position)
						local RA_Height = self.Object["Right Arm"].Size.Y / 2 - .2
						local RUA = WorldToViewportPoint(cam, (self.Object["Right Arm"].CFrame * CFrame.new(0, RA_Height, 0)).Position)
						local RLA = WorldToViewportPoint(cam, (self.Object["Right Arm"].CFrame * CFrame.new(0, - RA_Height, 0)).Position)
						local LL_Height = self.Object["Left Leg"].Size.Y / 2 - .2
						local LUL = WorldToViewportPoint(cam, (self.Object["Left Leg"].CFrame * CFrame.new(0, LL_Height, 0)).Position)
						local LLL = WorldToViewportPoint(cam, (self.Object["Left Leg"].CFrame * CFrame.new(0, - LL_Height, 0)).Position)
						local RL_Height = self.Object["Right Leg"].Size.Y / 2 - .2
						local RUL = WorldToViewportPoint(cam, (self.Object["Right Leg"].CFrame * CFrame.new(0, RL_Height, 0)).Position)
						local RLL = WorldToViewportPoint(cam, (self.Object["Right Leg"].CFrame * CFrame.new(0, - RL_Height, 0)).Position)
						self.Components.R6SkeleHeadSpine.From = Vector2.new(H.X, H.Y)
						self.Components.R6SkeleHeadSpine.To = Vector2.new(UT.X, UT.Y)
						self.Components.R6SkeleSpine.From = Vector2.new(UT.X, UT.Y)
						self.Components.R6SkeleSpine.To = Vector2.new(LT.X, LT.Y)
						self.Components.R6SkeleLeftArm.From = Vector2.new(LUA.X, LUA.Y)
						self.Components.R6SkeleLeftArm.To = Vector2.new(LLA.X, LLA.Y)
						self.Components.R6SkeleLeftArmUpperTorso.From = Vector2.new(UT.X, UT.Y)
						self.Components.R6SkeleLeftArmUpperTorso.To = Vector2.new(LUA.X, LUA.Y)
						self.Components.R6SkeleRightArm.From = Vector2.new(RUA.X, RUA.Y)
						self.Components.R6SkeleRightArm.To = Vector2.new(RLA.X, RLA.Y)
						self.Components.R6SkeleRightArmUpperTorso.From = Vector2.new(UT.X, UT.Y)
						self.Components.R6SkeleRightArmUpperTorso.To = Vector2.new(RUA.X, RUA.Y)
						self.Components.R6SkeleLeftLeg.From = Vector2.new(LUL.X, LUL.Y)
						self.Components.R6SkeleLeftLeg.To = Vector2.new(LLL.X, LLL.Y)
						self.Components.R6SkeleLeftLegLowerTorso.From = Vector2.new(LT.X, LT.Y)
						self.Components.R6SkeleLeftLegLowerTorso.To = Vector2.new(LUL.X, LUL.Y)
						self.Components.R6SkeleRightLeg.From = Vector2.new(RUL.X, RUL.Y)
						self.Components.R6SkeleRightLeg.To = Vector2.new(RLL.X, RLL.Y)
						self.Components.R6SkeleRightLegLowerTorso.From = Vector2.new(LT.X, LT.Y)
						self.Components.R6SkeleRightLegLowerTorso.To = Vector2.new(RUL.X, RUL.Y)
						self.Components.R6SkeleHeadSpine.Color = color
						self.Components.R6SkeleSpine.Color = color
						self.Components.R6SkeleLeftArm.Color = color
						self.Components.R6SkeleLeftArmUpperTorso.Color = color
						self.Components.R6SkeleRightArm.Color = color
						self.Components.R6SkeleRightArmUpperTorso.Color = color
						self.Components.R6SkeleLeftLeg.Color = color
						self.Components.R6SkeleLeftLegLowerTorso.Color = color
						self.Components.R6SkeleRightLeg.Color = color
						self.Components.R6SkeleRightLegLowerTorso.Color = color
						self.Components.R6SkeleHeadSpine.Visible = true
						self.Components.R6SkeleSpine.Visible = true
						self.Components.R6SkeleLeftArm.Visible = true
						self.Components.R6SkeleLeftArmUpperTorso.Visible = true
						self.Components.R6SkeleRightArm.Visible = true
						self.Components.R6SkeleRightArmUpperTorso.Visible = true
						self.Components.R6SkeleLeftLeg.Visible = true
						self.Components.R6SkeleLeftLegLowerTorso.Visible = true
						self.Components.R6SkeleRightLeg.Visible = true
						self.Components.R6SkeleRightLegLowerTorso.Visible = true
					end
				end
			else
				self.Components.R15SkeleHeadUpperTorso.Visible = false
				self.Components.R15SkeleUpperTorsoLowerTorso.Visible = false
				self.Components.R15SkeleUpperTorsoLeftUpperArm.Visible = false
				self.Components.R15SkeleLeftUpperArmLeftLowerArm.Visible = false
				self.Components.R15SkeleLeftLowerArmLeftHand.Visible = false
				self.Components.R15SkeleUpperTorsoRightUpperArm.Visible = false
				self.Components.R15SkeleRightUpperArmRightLowerArm.Visible = false
				self.Components.R15SkeleRightLowerArmRightHand.Visible = false
				self.Components.R15SkeleLowerTorsoLeftUpperLeg.Visible = false
				self.Components.R15SkeleLeftUpperLegLeftLowerLeg.Visible = false
				self.Components.R15SkeleLeftLowerLegLeftFoot.Visible = false
				self.Components.R15SkeleLowerTorsoRightUpperLeg.Visible = false
				self.Components.R15SkeleRightUpperLegRightLowerLeg.Visible = false
				self.Components.R15SkeleRightLowerLegRightFoot.Visible = false
				self.Components.R6SkeleHeadSpine.Visible = false
				self.Components.R6SkeleSpine.Visible = false
				self.Components.R6SkeleLeftArm.Visible = false
				self.Components.R6SkeleLeftArmUpperTorso.Visible = false
				self.Components.R6SkeleRightArm.Visible = false
				self.Components.R6SkeleRightArmUpperTorso.Visible = false
				self.Components.R6SkeleLeftLeg.Visible = false
				self.Components.R6SkeleLeftLegLowerTorso.Visible = false
				self.Components.R6SkeleRightLeg.Visible = false
				self.Components.R6SkeleRightLegLowerTorso.Visible = false
			end
		else
			self.Components.R15SkeleHeadUpperTorso.Visible = false
			self.Components.R15SkeleUpperTorsoLowerTorso.Visible = false
			self.Components.R15SkeleUpperTorsoLeftUpperArm.Visible = false
			self.Components.R15SkeleLeftUpperArmLeftLowerArm.Visible = false
			self.Components.R15SkeleLeftLowerArmLeftHand.Visible = false
			self.Components.R15SkeleUpperTorsoRightUpperArm.Visible = false
			self.Components.R15SkeleRightUpperArmRightLowerArm.Visible = false
			self.Components.R15SkeleRightLowerArmRightHand.Visible = false
			self.Components.R15SkeleLowerTorsoLeftUpperLeg.Visible = false
			self.Components.R15SkeleLeftUpperLegLeftLowerLeg.Visible = false
			self.Components.R15SkeleLeftLowerLegLeftFoot.Visible = false
			self.Components.R15SkeleLowerTorsoRightUpperLeg.Visible = false
			self.Components.R15SkeleRightUpperLegRightLowerLeg.Visible = false
			self.Components.R15SkeleRightLowerLegRightFoot.Visible = false
			self.Components.R6SkeleHeadSpine.Visible = false
			self.Components.R6SkeleSpine.Visible = false
			self.Components.R6SkeleLeftArm.Visible = false
			self.Components.R6SkeleLeftArmUpperTorso.Visible = false
			self.Components.R6SkeleRightArm.Visible = false
			self.Components.R6SkeleRightArmUpperTorso.Visible = false
			self.Components.R6SkeleLeftLeg.Visible = false
			self.Components.R6SkeleLeftLegLowerTorso.Visible = false
			self.Components.R6SkeleRightLeg.Visible = false
			self.Components.R6SkeleRightLegLowerTorso.Visible = false
		end
	else
		self.Components.R15SkeleHeadUpperTorso.Visible = false
		self.Components.R15SkeleUpperTorsoLowerTorso.Visible = false
		self.Components.R15SkeleUpperTorsoLeftUpperArm.Visible = false
		self.Components.R15SkeleLeftUpperArmLeftLowerArm.Visible = false
		self.Components.R15SkeleLeftLowerArmLeftHand.Visible = false
		self.Components.R15SkeleUpperTorsoRightUpperArm.Visible = false
		self.Components.R15SkeleRightUpperArmRightLowerArm.Visible = false
		self.Components.R15SkeleRightLowerArmRightHand.Visible = false
		self.Components.R15SkeleLowerTorsoLeftUpperLeg.Visible = false
		self.Components.R15SkeleLeftUpperLegLeftLowerLeg.Visible = false
		self.Components.R15SkeleLeftLowerLegLeftFoot.Visible = false
		self.Components.R15SkeleLowerTorsoRightUpperLeg.Visible = false
		self.Components.R15SkeleRightUpperLegRightLowerLeg.Visible = false
		self.Components.R15SkeleRightLowerLegRightFoot.Visible = false
		self.Components.R6SkeleHeadSpine.Visible = false
		self.Components.R6SkeleSpine.Visible = false
		self.Components.R6SkeleLeftArm.Visible = false
		self.Components.R6SkeleLeftArmUpperTorso.Visible = false
		self.Components.R6SkeleRightArm.Visible = false
		self.Components.R6SkeleRightArmUpperTorso.Visible = false
		self.Components.R6SkeleLeftLeg.Visible = false
		self.Components.R6SkeleLeftLegLowerTorso.Visible = false
		self.Components.R6SkeleRightLeg.Visible = false
		self.Components.R6SkeleRightLegLowerTorso.Visible = false
	end
	if ESP.PP then
		local TorsoPos, Vis10 = WorldToViewportPoint(cam, locs.Torso.Position)
		if Vis10 then
			if self.Object:FindFirstChildOfClass("Humanoid") and self.Object:FindFirstChildOfClass("Humanoid").RigType == Enum.HumanoidRigType.R15 then
				if self.Object and self.Object:FindFirstChild("LowerTorso") then
					local LT = WorldToViewportPoint(cam, self.Object.LowerTorso.Position)
					self.Components.Ball.Position = Vector2.new(LT.X + 3, LT.Y)
					self.Components.Ball2.Position = Vector2.new(LT.X - 3, LT.Y)
					self.Components.Wanker.From = Vector2.new(LT.X, LT.Y)
					self.Components.Wanker.To = Vector2.new(LT.X, LT.Y + ESP.PPSize)
					self.Components.Ball.Color = color
					self.Components.Ball2.Color = color
					self.Components.Wanker.Color = color
					self.Components.Ball.Visible = true
					self.Components.Ball2.Visible = true
					self.Components.Wanker.Visible = true
				end
			elseif self.Object:FindFirstChildOfClass("Humanoid") and self.Object:FindFirstChildOfClass("Humanoid").RigType == Enum.HumanoidRigType.R6 then
				if self.Object and self.Object:FindFirstChild("Torso") then
					local T_Height = self.Object.Torso.Size.Y / 2 - .2
					local Torso = WorldToViewportPoint(cam, (self.Object.Torso.CFrame * CFrame.new(0, - T_Height, 0)).Position)
					self.Components.Ball.Position = Vector2.new(Torso.X + 3, Torso.Y)
					self.Components.Ball2.Position = Vector2.new(Torso.X - 3, Torso.Y)
					self.Components.Wanker.From = Vector2.new(Torso.X, Torso.Y)
					self.Components.Wanker.To = Vector2.new(Torso.X, Torso.Y + ESP.PPSize)
					self.Components.Ball.Color = color
					self.Components.Ball2.Color = color
					self.Components.Wanker.Color = color
					self.Components.Ball.Visible = true
					self.Components.Ball2.Visible = true
					self.Components.Wanker.Visible = true
				end
			end
		else
			self.Components.Ball.Visible = false
			self.Components.Ball2.Visible = false
			self.Components.Wanker.Visible = false
		end
	else
		self.Components.Ball.Visible = false
		self.Components.Ball2.Visible = false
		self.Components.Wanker.Visible = false
	end
	local TorsoPos, Vis11 = WorldToViewportPoint(cam, locs.Torso.Position)
	if not Vis11 then
		local viewportSize = cam.ViewportSize
		local screenCenter = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
		local objectSpacePoint = (PointToObjectSpace(cam.CFrame, locs.Torso.Position) * Vector3.new(1, 0, 1)).Unit
		local crossVector = Cross(objectSpacePoint, Vector3.new(0, 1, 1))
		local rightVector = Vector2.new(crossVector.X, crossVector.Z)
		local arrowRadius, arrowSize = ESP.OutOfViewArrowsRadius, ESP.OutOfViewArrowsSize
		local arrowPosition = screenCenter + Vector2.new(objectSpacePoint.X, objectSpacePoint.Z) * arrowRadius
		local arrowDirection = (arrowPosition - screenCenter).Unit
		local pointA, pointB, pointC = arrowPosition, screenCenter + arrowDirection * (arrowRadius - arrowSize) + rightVector * arrowSize, screenCenter + arrowDirection * (arrowRadius - arrowSize) + - rightVector * arrowSize
		if ESP.OutOfViewArrows then
			self.Components.Arrow.Visible = true
			self.Components.Arrow.Filled = true
			self.Components.Arrow.Transparency = .5
			self.Components.Arrow.Color = color
			self.Components.Arrow.PointA = pointA
			self.Components.Arrow.PointB = pointB
			self.Components.Arrow.PointC = pointC
		else
			self.Components.Arrow.Visible = false
		end
		if ESP.OutOfViewArrowsOutline then
			self.Components.Arrow2.Visible = true
			self.Components.Arrow2.Filled = false
			self.Components.Arrow2.Transparency = 1
			self.Components.Arrow2.Color = ESP.OutOfViewArrowsOutlineColor
			self.Components.Arrow2.PointA = pointA
			self.Components.Arrow2.PointB = pointB
			self.Components.Arrow2.PointC = pointC
		else
			self.Components.Arrow2.Visible = false
		end
	else
		self.Components.Arrow.Visible = false
		self.Components.Arrow2.Visible = false
	end
	if ESP.Chams then
		local TorsoPos, Vis12 = WorldToViewportPoint(cam, locs.Torso.Position)
		if Vis12 then
			self.Components.Highlight.Enabled = true
			self.Components.Highlight.FillColor = color
			self.Components.Highlight.FillTransparency = ESP.ChamsTransparency
			self.Components.Highlight.OutlineTransparency = ESP.ChamsOutlineTransparency
			self.Components.Highlight.OutlineColor = ESP.ChamsOutlineColor
		else
			self.Components.Highlight.Enabled = false
		end
	else
		self.Components.Highlight.Enabled = false
	end
end
function ESP:Add(obj, options)
	if not obj.Parent and not options.RenderInNil then
		return warn("[KH ESP]:", obj, "has no parent")
	end
	local box = setmetatable({
		Name = options.Name or obj.Name,
		Type = "Box",
		Color = options.Color,
		Size = options.Size or self.BoxSize,
		Object = obj,
		Player = options.Player or Players:GetPlayerFromCharacter(obj),
		PrimaryPart = options.PrimaryPart or obj.ClassName == "Model" and (obj.PrimaryPart or obj:FindFirstChild(ESP.HrpName) or obj:FindFirstChildWhichIsA("BasePart")) or obj:IsA("BasePart") and obj,
		Components = {},
		IsEnabled = options.IsEnabled,
		Temporary = options.Temporary,
		ColorDynamic = options.ColorDynamic,
		RenderInNil = options.RenderInNil,
		Bars = {}
	}, boxBase)
	if self:GetBox(obj) then
		self:GetBox(obj):Remove()
	end
	box.Components["Box"] = Draw("Square", {
		Thickness = self.Thickness,
		Color = color,
		Transparency = 1,
		Filled = false,
		Visible = self.Enabled and self.Boxes
	})
	box.Components["BoxOutline"] = Draw("Square", {
		Thickness = self.Thickness,
		Color = color,
		Transparency = 3,
		Filled = false,
		Visible = self.Enabled and self.Boxes
	})
	box.Components["BoxFill"] = Draw("Square", {
		Thickness = self.Thickness,
		Color = color,
		Transparency = 1,
		Filled = false,
		Visible = self.Enabled and self.Boxes
	})
	box.Components["Name"] = Draw("Text", {
		Text = box.Name,
		Color = box.Color,
		Center = true,
		Outline = true,
		Size = self.TextSize,
		Visible = self.Enabled and self.Names
	})
	box.Components["Distance"] = Draw("Text", {
		Color = box.Color,
		Center = true,
		Outline = true,
		Size = 19,
		Visible = self.Enabled and self.Names
	})
	
	box.Components["Tracer"] = Draw("Line", {
		Thickness = ESP.Thickness,
		Color = box.Color,
		Transparency = 1,
		Visible = self.Enabled and self.Tracers
	})
	box.Components["Items"] = Draw("Text", {
		Color = box.Color,
		Center = true,
		Outline = true,
		Size = self.TextSize,
		Visible = self.Enabled and self.Items
	})
	box.Components["HealthBarOutline"] = Draw("Square", {
		Transparency = 1,
		Thickness = 1,
		Filled = true,
		Visible = self.Enabled and self.Health
	})
	box.Components["HealthBar"] = Draw("Square", {
		Transparency = 1,
		Thickness = 1,
		Visible = self.Enabled and self.Health
	})
	box.Components["HealthText"] = Draw("Text", {
		Color = box.Color,
		Center = true,
		Outline = true,
		Size = self.TextSize,
		Visible = self.Enabled and self.Health
	})
	box.Components["Tracer"] = Draw("Line", {
		Thickness = ESP.Thickness,
		Color = box.Color,
		Transparency = 1,
		Visible = self.Enabled and self.Tracers
	})
	box.Components["R15SkeleHeadUpperTorso"] = Draw("Line", {
		Transparency = 1,
		Thickness = 1,
		Visible = self.Enabled and self.Skeleton
	})
	box.Components["R15SkeleUpperTorsoLowerTorso"] = Draw("Line", {
		Transparency = 1,
		Thickness = 1,
		Visible = self.Enabled and self.Skeleton
	})
	box.Components["R15SkeleUpperTorsoLeftUpperArm"] = Draw("Line", {
		Transparency = 1,
		Thickness = 1,
		Visible = self.Enabled and self.Skeleton
	})
	box.Components["R15SkeleLeftUpperArmLeftLowerArm"] = Draw("Line", {
		Transparency = 1,
		Thickness = 1,
		Visible = self.Enabled and self.Skeleton
	})
	box.Components["R15SkeleLeftLowerArmLeftHand"] = Draw("Line", {
		Transparency = 1,
		Thickness = 1,
		Visible = self.Enabled and self.Skeleton
	})
	box.Components["R15SkeleUpperTorsoRightUpperArm"] = Draw("Line", {
		Transparency = 1,
		Thickness = 1,
		Visible = self.Enabled and self.Skeleton
	})
	box.Components["R15SkeleRightUpperArmRightLowerArm"] = Draw("Line", {
		Transparency = 1,
		Thickness = 1,
		Visible = self.Enabled and self.Skeleton
	})
	box.Components["R15SkeleRightLowerArmRightHand"] = Draw("Line", {
		Transparency = 1,
		Thickness = 1,
		Visible = self.Enabled and self.Skeleton
	})
	box.Components["R15SkeleLowerTorsoLeftUpperLeg"] = Draw("Line", {
		Transparency = 1,
		Thickness = 1,
		Visible = self.Enabled and self.Skeleton
	})
	box.Components["R15SkeleLeftUpperLegLeftLowerLeg"] = Draw("Line", {
		Transparency = 1,
		Thickness = 1,
		Visible = self.Enabled and self.Skeleton
	})
	box.Components["R15SkeleLeftLowerLegLeftFoot"] = Draw("Line", {
		Transparency = 1,
		Thickness = 1,
		Visible = self.Enabled and self.Skeleton
	})
	box.Components["R15SkeleLowerTorsoRightUpperLeg"] = Draw("Line", {
		Transparency = 1,
		Thickness = 1,
		Visible = self.Enabled and self.Skeleton
	})
	box.Components["R15SkeleRightUpperLegRightLowerLeg"] = Draw("Line", {
		Transparency = 1,
		Thickness = 1,
		Visible = self.Enabled and self.Skeleton
	})
	box.Components["R15SkeleRightLowerLegRightFoot"] = Draw("Line", {
		Transparency = 1,
		Thickness = 1,
		Visible = self.Enabled and self.Skeleton
	})
	box.Components["R6SkeleHeadSpine"] = Draw("Line", {
		Transparency = 1,
		Thickness = 1,
		Visible = self.Enabled and self.Skeleton
	})
	box.Components["R6SkeleSpine"] = Draw("Line", {
		Transparency = 1,
		Thickness = 1,
		Visible = self.Enabled and self.Skeleton
	})
	box.Components["R6SkeleLeftArm"] = Draw("Line", {
		Transparency = 1,
		Thickness = 1,
		Visible = self.Enabled and self.Skeleton
	})
	box.Components["R6SkeleLeftArmUpperTorso"] = Draw("Line", {
		Transparency = 1,
		Thickness = 1,
		Visible = self.Enabled and self.Skeleton
	})
	box.Components["R6SkeleRightArm"] = Draw("Line", {
		Transparency = 1,
		Thickness = 1,
		Visible = self.Enabled and self.Skeleton
	})
	box.Components["R6SkeleRightArmUpperTorso"] = Draw("Line", {
		Transparency = 1,
		Thickness = 1,
		Visible = self.Enabled and self.Skeleton
	})
	box.Components["R6SkeleLeftLeg"] = Draw("Line", {
		Transparency = 1,
		Thickness = 1,
		Visible = self.Enabled and self.Skeleton
	})
	box.Components["R6SkeleLeftLegLowerTorso"] = Draw("Line", {
		Transparency = 1,
		Thickness = 1,
		Visible = self.Enabled and self.Skeleton
	})
	box.Components["R6SkeleRightLeg"] = Draw("Line", {
		Transparency = 1,
		Thickness = 1,
		Visible = self.Enabled and self.Skeleton
	})
	box.Components["R6SkeleRightLegLowerTorso"] = Draw("Line", {
		Transparency = 1,
		Thickness = 1,
		Visible = self.Enabled and self.Skeleton
	})
	box.Components["Ball"] = Draw("Circle", {
		Transparency = 1,
		Thickness = 1,
		Radius = 4,
		Visible = self.Enabled and self.PP
	})
	box.Components["Ball2"] = Draw("Circle", {
		Transparency = 1,
		Thickness = 1,
		Radius = 4,
		Visible = self.Enabled and self.PP
	})
	box.Components["Wanker"] = Draw("Line", {
		Transparency = 1,
		Thickness = 1,
		Visible = self.Enabled and self.PP
	})
	box.Components["Arrow"] = Draw("Triangle", {
		Thickness = 1
	})
	box.Components["Arrow2"] = Draw("Triangle", {
		Thickness = 1
	})
	local h = Instance.new("Highlight")
	h.Enabled = ESP.Chams
	h.FillTransparency = .35
	h.OutlineTransparency = .35
	h.FillColor = ESP.Color
	h.OutlineColor = ESP.ChamsOutlineColor
	h.DepthMode = 0
	h.Name = GenerateName(x)
	h.Parent = Folder
	h.Adornee = obj
	box.Components["Highlight"] = h
	self.Objects[obj] = box
	obj.AncestryChanged:Connect(function(_, parent)
		if parent == nil and ESP.AutoRemove ~= false then
			box:Remove()
		end
	end)
	obj:GetPropertyChangedSignal("Parent"):Connect(function()
		if obj.Parent == nil and ESP.AutoRemove ~= false then
			box:Remove()
		end
	end)
	local hum = obj:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.Died:Connect(function()
			if ESP.AutoRemove ~= false then
				box:Remove()
			end
		end)
	end
	return box
end
local barBase = {}
barBase.__index = barBase
function boxBase:AddBar(name, options)
	local bar = setmetatable({
		Name = name,
		Type = "Bar",
		Color = options.Color,
		Components = {},
		Value = 0.4
	}, barBase)

	table.insert(self.Bars, bar)
	bar.Components["BarBackground"] = Draw("Quad", {
		Thickness = ESP.Thickness,
		Color = Color3.fromRGB(26, 26, 26),
		Transparency = 1,
		Filled = true,
		Visible = ESP.Enabled and ESP.Bars
	})
	bar.Components["Bar"] = Draw("Quad", {
		Thickness = ESP.Thickness,
		Color = bar.Color,
		Transparency = 1,
		Filled = true,
		Visible = ESP.Enabled and ESP.Bars
	})
	for i, v in next, bar.Components do
		table.insert(self.Components, v)
	end
	return bar
end
local function CharAdded(char)
	local p = Players:GetPlayerFromCharacter(char)
	if not char:FindFirstChild(ESP.HrpName) then
		local ev
		ev = char.ChildAdded:Connect(function(c)
			if c.Name == ESP.HrpName then
				ev:Disconnect()
				local box = ESP:Add(char, {
					Name = p.Name,
					Player = p,
					PrimaryPart = c
				})
				for i, v in next, ESP.GlobalBars do
					coroutine.wrap(v[3])(box, box:AddBar(v[1], v[2]))
				end
			end
		end)
	else
		local box = ESP:Add(char, {
			Name = p.Name,
			Player = p,
			PrimaryPart = char:FindFirstChild(ESP.HrpName)
		})
		for i, v in next, ESP.GlobalBars do
			coroutine.wrap(v[3])(box, box:AddBar(v[1], v[2]))
		end
	end
end
local function PlayerAdded(p)
	p.CharacterAdded:Connect(CharAdded)
	if p.Character then
		coroutine.wrap(CharAdded)(p.Character)
	end
end
Players.PlayerAdded:Connect(PlayerAdded)
for i, v in next, Players:GetPlayers() do
	if v ~= Me then
		PlayerAdded(v)
	end
end
ESP.OnRenderStepped = game:GetService("RunService"):BindToRenderStep("ESP", (ESP.UseRenderValue and ESP.RenderValue) or Enum.RenderPriority.Camera.Value + 1, function()
	cam = workspace.CurrentCamera
	for i, v in (ESP.Enabled and pairs or ipairs)(ESP.Objects) do
		if v.Update then
			local s, e = pcall(v.Update, v)
			if not s then
				warn("[EU]", e, v.Object:GetFullName())
			end
		end
	end
	for i, v in (pairs or ipairs)(ESP.Render) do 
		if v.Update then
			local s, e = pcall(v.Update, v)
		end
	end
end)
return ESP
