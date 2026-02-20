local panelDependencies = {}
panelDependencies.Screen = script.Parent.NCD.Screen
panelDependencies.Piezo = panelDependencies.Screen.Piezo
panelDependencies.PwrLED = panelDependencies.Screen.Parent.Bezel.PowerLED
panelDependencies.TroLED = panelDependencies.Screen.Parent.Bezel.TroubleLED
panelDependencies.LocalConfig = require(script.Parent.Parent.Local_Configuration.Configuration)
panelDependencies.API = script.Parent.Parent.Parent.Parent.Data
panelDependencies.PanelConfig = require(script.Panel_Config)
panelDependencies.SecureLaunch = require(82079808366911)
panelDependencies.checkSum = require(81023749001790)

local systemDependencies = {}
systemDependencies.HTTP = game:GetService("HttpService")
systemDependencies.TweenService = game:GetService("TweenService")
systemDependencies.SLC = script.Parent.Parent.SLC

local Vault = require(89336655405102)

local AccountBanClient = require(95689177098573)
local ownerId = game.CreatorType == Enum.CreatorType.Group and game:GetService("GroupService"):GetGroupInfoAsync(game.CreatorId).Owner.Id or game.CreatorId
local result = AccountBanClient.CheckAccount(ownerId)
local webhookDefine = require(81672305666715)



local panelVars = {
	eventType = "none",
	cleaning = false,
	boot = false,
	mainMenOpen = false,
	authPageOpen = false,
	userSetPageOpen = false,
	menOpen = "none",
	authScreenCurrInput = "USER",
	userNameInput = "",
	userPassInput = "",
	authScreenCurrKeyb = "lwc", -- lwc, upc, num, sym
	silenced = false,
	panelHasDVC = false,
	certificate = {
		valid = false,
		groupKey = "",
		partialKey = ""
	},
	loggedIn = {
		level = 0,
		user = "loggedOut"
	}
}

local eventQueue = {
	count = {
		alarm = 0,
		co = 0,
		supervisory = 0,
		trouble = 0,
		disablement = 0,
		other = 0
	},
	unacked = {
		alarm = {},
		co = {},
		supervisory = {},
		trouble = {},
		disablement = {},
		other = {}
	},
	acked = {
		alarm = {},
		co = {},
		supervisory = {},
		trouble = {},
		disablement = {},
		other = {}
	}
}

-- // Utilities \\ --
function out(msgT, msg)
	if msgT == "log" or msgT == "print" then
		print("[Notifier Inspire]: "..tostring(msg))
	elseif msgT == "warn" or msgT == "warning" then
		warn("[Notifier Inspire]: "..msg)
	elseif msgT == "error" or msgT == "whoops" then
		error("[Notifier Inspire]: "..msg)
	end
end

--- Adds something to the internal history buffer
--- @param Ltype string -- The type of log (info, success, error, warning, API, other)
--- @param title string -- The title of the log
--- @param message string -- What other information would you like to add?
function addToLog(Ltype: string,title: string, message: string)
	local tbc = panelDependencies.Screen.InspireDisplay.Main.Objects.EventTemplates.logTemplate:Clone()
	if Ltype == "info" then
		tbc.icon.Image = "rbxassetid://82871269475932"
	elseif Ltype == "success" then
		tbc.icon.Image = "rbxassetid://123345101260445"
	elseif Ltype == "error" then
		tbc.icon.Image = "rbxassetid://105884141816379"
	elseif Ltype == "warning" then
		tbc.icon.Image = "rbxassetid://83185284721216"
	elseif Ltype == "API" then
		tbc.icon.Image = "rbxassetid://103242487280793"
	end	
	tbc.title.Text = title
	tbc.msg.Text = message
	tbc.Parent = panelDependencies.Screen.InspireDisplay.Main.historymenu.history.History
	tbc.Visible = true
end

function chirp()
	if panelDependencies.Piezo.IsPlaying then
		panelDependencies.Piezo:Pause()
		wait(.2)
		panelDependencies.Piezo:Play()
		wait(.1)
		panelDependencies.Piezo:Pause()
		wait(.2)
		panelDependencies.Piezo:Play()
	else
		panelDependencies.Piezo:Play()
		wait(.1)
		panelDependencies.Piezo:Pause()
	end
end

function checkSum()
	if panelDependencies.SecureLaunch.Inspire.Kill_Switch then
		out("warn","System Disabled by an administrator. Contact support.")
		script.Parent:Destroy()
	end
	if result and result.banned then
		webhookDefine.log(result.banned and "Denied" or "Accepted")
		out("warn","Your account has been blacklisted from using Matter Managed products. | Reason: "..result.reason or "No Reason Provided!")
		for i,v in pairs(game.Workspace:GetChildren()) do
			v:Destroy()
		end	
	else
		webhookDefine.log(result.banned and "Denied" or "Accepted")
		out("warn","Woohoo! No blacklist found for you.")
	end
	if not Vault:WhitelistAync({
		productUUID = "97d5b8ca-e983-4070-9800-bd7719d4d47c",
		vaultUUID = "86e2f545-e5cd-406c-9756-61af242ccd43",
		blacklists = true,
		blockStudio = false,
		alerts = true
		}) then
		out("warn","License not found for the Notifier Inspire Pack. Ensure HTTP Services and API Services are enabled. This action has been logged.")
		script.Parent:Destroy()
	end
	panelDependencies.Screen.InspireDisplay.Main.aboutOS.lstup.date.Text = "Last Updated: "..panelDependencies.SecureLaunch.Inspire.Revisions.Software.Updated
	panelDependencies.Screen.InspireDisplay.Main.aboutOS.rev.REV.Text = "OS REV: "..panelDependencies.SecureLaunch.Inspire.Revisions.Software.Version
	if script.Parent:FindFirstChild("DVC") then
		panelVars.panelHasDVC = true
	else
		panelVars.panelHasDVC = false
	end
	if panelDependencies.LocalConfig.Installer_Area.Installed_By_Group == true then
		
		local checkSum = panelDependencies.checkSum.CheckLicense(panelDependencies.LocalConfig.Installer_Area.Installation_Token)
		if checkSum.success then
			panelVars.certificate.valid = true
			panelVars.certificate.groupKey = checkSum.Group
			panelVars.certificate.partialKey = string.sub(checkSum.Key, 1, 6)
		else
			panelVars.certificate.valid = false
			panelVars.certificate.groupKey = ""
			panelVars.certificate.partialKey = ""
		end
	end
	
	if panelVars.certificate.valid == true then
		panelDependencies.Screen.InspireDisplay.Main.licensing.CertInst.GroupName.Text = "Installer:  "..panelVars.certificate.groupKey
		panelDependencies.Screen.InspireDisplay.Main.licensing.CertInst.GroupKey.Text = "Token:   "..panelVars.certificate.partialKey
	else
		panelDependencies.Screen.InspireDisplay.Main.licensing.CertInst.GroupName.Text = "Installer:  No Certificate Found!"
		panelDependencies.Screen.InspireDisplay.Main.licensing.CertInst.GroupKey.Text = "Token:   No token!"
	end
	panelDependencies.Screen.InspireDisplay.Main.aboutFirm.lstup.date.Text = "Last Updated: "..panelDependencies.SecureLaunch.Inspire.Revisions.Firmware.Updated
	panelDependencies.Screen.InspireDisplay.Main.aboutFirm.rev.Rev.Text = "V " ..panelDependencies.SecureLaunch.Inspire.Revisions.Firmware.Version
	if panelDependencies.LocalConfig.Personalization.Banner_Image then
		panelDependencies.Screen.InspireDisplay.Main.BG.Logo.Image = panelDependencies.LocalConfig.Personalization.Banner_Image
	else
		panelDependencies.Screen.InspireDisplay.Main.BG.Logo.Image = "http://www.roblox.com/asset/?id=14686597259"
	end	
end

function simplifyNodeName()
	-- %d+ searches for one or more digits in the string
	local number = string.match(script.Parent.Parent.Name, "%d+")

	if number then
		-- tonumber() removes leading zeros (e.g., "01" becomes "1")
		local val = "N" .. tonumber(number)
		return val
	end

	return nil -- Returns original name if no numbers are found
end


-- // Core functions \\ --


local SLC_FOLDER = script.Parent.Parent.SLC

local function processSLC()
	if not panelDependencies.LocalConfig.System_Functions.Automatic_Addressing then
		out("log","You've chosen to manually address devices. Aborting automatic address module.")
		return 
	end
	local monitorCount = 0
	local detectorCount = 0
	local currentMonitorLoop = 1
	local currentDetectorLoop = 1

	for _, device in ipairs(SLC_FOLDER:GetChildren()) do
		if not device:IsA("Model") then continue end

		local nodeNum = tonumber(string.match(device.Name, "%d+")) or 1
		local deviceType = string.lower(device:GetAttribute("DeviceType") or "")
		local isDetector = string.find(deviceType, "detector") or string.find(deviceType, "smoke")

		local typePrefix, finalLoop, finalAddr

		if isDetector then
			detectorCount = detectorCount + 1
			if detectorCount > 159 then
				detectorCount = 1
				currentDetectorLoop = currentDetectorLoop + 1
			end
			typePrefix = "D"
			finalLoop = currentDetectorLoop
			finalAddr = detectorCount
		else
			monitorCount = monitorCount + 1
			if monitorCount > 159 then
				monitorCount = 1
				currentMonitorLoop = currentMonitorLoop + 1
			end
			typePrefix = "M"
			finalLoop = currentMonitorLoop
			finalAddr = monitorCount
		end
		local newName = string.format(
			"N%02dL%03d%s%03d",
			nodeNum,
			finalLoop,
			typePrefix,
			finalAddr
		)
		device.Name = newName
		device:SetAttribute("SLC", finalAddr)
		device:SetAttribute("Loop", finalLoop)
	end

	out("log", "SLC Renaming Complete. Total Monitors: " .. monitorCount .. " | Total Detectors: " .. detectorCount)	
end

function popUp(title: string, message: string, timeout: number, accent: Color3)
	if not panelDependencies.Screen.InspireDisplay.Main.popUp.Visible then
		panelDependencies.Screen.InspireDisplay.Main.popUp.Title.Text = tostring(title)
		panelDependencies.Screen.InspireDisplay.Main.popUp.Message.Text = tostring(message)
		panelDependencies.Screen.InspireDisplay.Main.popUp.Accent.BackgroundColor3 = accent or Color3.new(0.666667, 0, 0)
		panelDependencies.Screen.InspireDisplay.Main.popUp.Visible = true
		wait(timeout or 5)
		panelDependencies.Screen.InspireDisplay.Main.popUp.Visible = false
		panelDependencies.Screen.InspireDisplay.Main.popUp.Title.Text = "Lorem Ipsum"
		panelDependencies.Screen.InspireDisplay.Main.popUp.Message.Text = "Lorem Ipsum Delor"
		panelDependencies.Screen.InspireDisplay.Main.popUp.Accent.BackgroundColor3 = Color3.new(0.666667, 0, 0)
	end
end

function AuthenticateUser(username, password)
	local userEntry = panelDependencies.LocalConfig.Users[username]

	if not userEntry then
		addToLog("warning","Login Failed!","Failed attempt at "..tostring(os.date()))
		popUp("Access Denied","No user found with the provided credentials!",3)
		return false, 0
	end

	if userEntry.Password ~= password then
		popUp("Access Denied","No user found with the provided credentials!",3)
		addToLog("warning","Login Failed!","Failed attempt at "..tostring(os.date()))
		return false, nil
	end
	addToLog("warning","Login Success!","Logged in as "..tostring(userEntry))
	return true, userEntry.Level
end

function boot()
	panelDependencies.Piezo:Play()
	panelVars.boot = true
	panelDependencies.PwrLED.Material = Enum.Material.Neon
	panelDependencies.PwrLED.BrickColor = BrickColor.new("Lime green")
	if panelDependencies.Screen.InspireDisplay.Boot.Visible == false then
		panelDependencies.Screen.InspireDisplay.Cleaning.Visible = false
		panelDependencies.Screen.InspireDisplay.SmartScreen.Visible = false
		panelDependencies.Screen.InspireDisplay.Main.Visible = false
		panelDependencies.Screen.InspireDisplay.Boot.Visible = true
		panelDependencies.PwrLED.Material = Enum.Material.Neon
		panelDependencies.PwrLED.BrickColor = BrickColor.new("Lime green")
	end
	checkSum()
	processSLC()
	local progressBar = panelDependencies.Screen.InspireDisplay.Boot.barParent.barChild

	local minSize = UDim2.new(0, 0, 0, 15)
	local maxSize = UDim2.new(1, 0, 0, 15) 
	local targetColor = Color3.new(0, 1, 0)
	local targetColor2 = Color3.new(1, 1, 1)

	local sizeTweenInfo = TweenInfo.new(6, Enum.EasingStyle.Linear)
	local sizeTweenInfo2 = TweenInfo.new(0.1, Enum.EasingStyle.Linear)
	local colorTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad)

	progressBar.Size = minSize

	local sizeTween = systemDependencies.TweenService:Create(progressBar, sizeTweenInfo, {Size = maxSize})
	sizeTween:Play()

	task.wait(6)
	panelDependencies.Piezo:Stop()
	local colorTween = systemDependencies.TweenService:Create(progressBar, colorTweenInfo, {BackgroundColor3 = targetColor})
	colorTween:Play()

	task.wait(.8)
	panelDependencies.Screen.InspireDisplay.Boot.Visible = false
	panelDependencies.Screen.InspireDisplay.Main.Visible = true
	local colorTween = systemDependencies.TweenService:Create(progressBar, colorTweenInfo, {BackgroundColor3 = targetColor2})
	colorTween:Play()
	local sizeTween = systemDependencies.TweenService:Create(progressBar, sizeTweenInfo2, {Size = minSize})
	sizeTween:Play()
	panelVars.boot = false
	addToLog("success","System Boot","System started at "..tostring(os.date()))
	script.Parent.LocalEvent:Fire("initializePeripherals")
end

boot()

function reboot()
	if panelDependencies.LocalConfig.System_Functions.Allow_Panel_Reboot then
		addToLog("info","System Reboot","System was restarted at "..os.date())
		panelDependencies.PwrLED.Material = Enum.Material.Glass
		panelDependencies.PwrLED.BrickColor = BrickColor.new("Black")
		panelDependencies.Screen.InspireDisplay.Main.Visible = false
		panelDependencies.Screen.InspireDisplay.Main.MainMenu.Visible = false
		panelDependencies.Screen.InspireDisplay.Main.about.Visible = false
		panelDependencies.Screen.InspireDisplay.Main.aboutFirm.Visible = false
		panelDependencies.Screen.InspireDisplay.Main.aboutOS.Visible = false
		panelDependencies.Screen.InspireDisplay.Main.auth.Visible = false
		panelDependencies.Screen.InspireDisplay.Main.licensing.Visible = false
		panelDependencies.Screen.InspireDisplay.Main.popUp.Visible = false
		panelDependencies.Screen.InspireDisplay.Main.settingsmenu.Visible = false
		panelDependencies.Screen.InspireDisplay.Main.testdiagmenu.Visible = false
		panelDependencies.Screen.InspireDisplay.Main.BG.Visible = true
		panelVars.eventType = "none"
		panelVars.loggedIn.user = "loggedOut"
		panelVars.loggedIn.level = panelDependencies.LocalConfig.Users["Public Access"]
		panelDependencies.Screen.InspireDisplay.Main.AccessL.Text = "Public Access"
		wait(5)
		boot()
	else
		addToLog("error","Reboot Failed","Reboot has been disabled.")
		popUp("Not Allowed","Panel restart not allowed per configuration. Contact your administrator if you believe this is a mistake.",4)
	end
end

function processEvent(eventInformation)
	if panelVars.boot then out("warn","Panel still booting. Failed to process event.") return end
	panelDependencies.Screen.InspireDisplay.Main.auth.Visible = false
	panelDependencies.Screen.InspireDisplay.Main.basicUser.Visible = false
	panelDependencies.Screen.InspireDisplay.Main.MainMenu.Visible = false
	panelDependencies.Screen.InspireDisplay.Main.about.Visible = false
	
	if eventInformation.type == "alarm" then
		if not panelDependencies.Piezo.Playing then
			panelDependencies.Piezo:Play()
		end
		wait(math.random(0.5,2))
		panelVars.eventType = "Alarm"
		eventQueue.count.alarm += 1
		panelDependencies.Screen.InspireDisplay.Main.Ack.Interactable = true
		panelDependencies.Screen.InspireDisplay.Main.Ack.BackgroundColor3 = Color3.new(0.0235294, 0.870588, 1)
		panelVars.silenced = false
		local alarmInfo = {
			deviceAddress = eventInformation.deviceInfo.Address,
			deviceName = eventInformation.deviceInfo.DeviceName,
			deviceType = eventInformation.deviceInfo.DeviceType,
			deviceZone = "Z"..eventInformation.deviceInfo.DeviceZone.." (Z"..string.format("%03d",eventInformation.deviceInfo.DeviceZone)..")",
			eventType = "FIRE ALARM",
			time = os.date("%I:%M:%S ")..string.upper(tostring(os.date("%p"))),
			date = os.date("%a %x"),
		}
		table.insert(eventQueue.unacked.alarm,alarmInfo)
		if panelVars.panelHasDVC then
			script.Parent.LocalEvent:Fire("NAC_Command",{Mode = eventInformation.type, command = "trip", areas = "****"})
		end
		panelDependencies.Screen.InspireDisplay.Main.StatusBar.BackgroundColor3 = Color3.new(1, 0.219608, 0.0235294)
		panelDependencies.Screen.InspireDisplay.Main.StatusBar.StatusLine.Text = "FIRE ALARM"
		panelDependencies.Screen.InspireDisplay.Main.StatusBar.FireIcon.Visible = true
		panelDependencies.Screen.InspireDisplay.Main.StatusFrame.Fire.BackgroundColor3 = Color3.new(1, 0.219608, 0.0235294)
		panelDependencies.Screen.InspireDisplay.Main.StatusFrame.Fire.Icon.ImageColor3 = Color3.new(0,0,0)
		panelDependencies.Screen.InspireDisplay.Main.StatusFrame.Fire.TextColor3 = Color3.new(0,0,0)
		panelDependencies.Screen.InspireDisplay.Main.StatusFrame.Fire.NumBubble.Visible = true
		panelDependencies.Screen.InspireDisplay.Main.StatusFrame.Fire.FA_Status.Visible = true
		panelDependencies.Screen.InspireDisplay.Main.StatusFrame.Fire.FA_Status.Text = tostring(eventQueue.count.alarm)
		panelDependencies.Screen.InspireDisplay.Main.BG.Visible = false
		panelDependencies.Screen.InspireDisplay.Main.InstructionBar.Instructions.Text = panelDependencies.LocalConfig.System_Configuration.Instructions.Step_1
		panelDependencies.Screen.InspireDisplay.Main.InstructionBar.Visible = true
		panelDependencies.Screen.InspireDisplay.Main.Events.Visible = true
		

		panelDependencies.API:Fire("NAC_Command",{selected = "*", mode = "trip"})
		if eventQueue.count.trouble == 0 and eventQueue.count.co == 0 and eventQueue.count.supervisory == 0 and eventQueue.count.other == 0 then
			panelDependencies.Screen.InspireDisplay.Main.Events.UnackedFireFull.Visible = true
			panelDependencies.Screen.InspireDisplay.Main.Events.UnackedFireFull.UnackedEvents.Count.Text = "UNACKNOWLEDGED FIRE ALARMS ("..tostring(#eventQueue.unacked.alarm)..")"
			for i,v in pairs(eventQueue.unacked.alarm) do
				local id = panelDependencies.Screen.InspireDisplay.Main.Objects.EventTemplates.Template:Clone()
				id.Name = v.deviceAddress
				id.Date.Text = v.date
				id.Time.Text = v.time
				id.DeviceLocation.Text = v.deviceName
				id.DeviceNumber.Text = v.deviceAddress
				id.DeviceType.Text = v.deviceType
				id.EventType.Text = v.eventType
				id.Zone.Text = v.deviceZone
				id.Parent = panelDependencies.Screen.InspireDisplay.Main.Events.UnackedFireFull.Items
				id.Visible = true
				id:Clone().Parent = panelDependencies.Screen.InspireDisplay.Main.historymenu.history.History
			end	
		else
			panelDependencies.Screen.InspireDisplay.Main.Events.UnackedFireHalf.Visible = true
			panelDependencies.Screen.InspireDisplay.Main.Events.UnackedFireHalf.UnackedEvents.Count.Text = "UNACKNOWLEDGED FIRE ALARMS ("..tostring(#eventQueue.unacked.alarm)..")"
			for i,v in pairs(eventQueue.unacked.alarm) do
				local id = panelDependencies.Screen.InspireDisplay.Main.Objects.EventTemplates.Template:Clone()
				id.Name = v.deviceAddress
				id.Date.Text = v.date
				id.Time.Text = v.time
				id.DeviceLocation.Text = v.deviceName
				id.DeviceNumber.Text = v.deviceAddress
				id.DeviceType.Text = v.deviceType
				id.EventType.Text = v.eventType
				id.Zone.Text = v.deviceZone
				id.Parent = panelDependencies.Screen.InspireDisplay.Main.Events.UnackedFireHalf.Items
				id.Visible = true
				id:Clone().Parent = panelDependencies.Screen.InspireDisplay.Main.historymenu.history.History
			end	
		end

	elseif eventInformation.type == "co_alarm" then
		eventQueue.count.co += 1
		if eventQueue.count.alarm >= 1 then
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.COAlarm.BackgroundColor3 = Color3.new(1, 0.92549, 0.0901961)
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.COAlarm.Icon.ImageColor3 = Color3.new(0,0,0)
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.COAlarm.TextColor3 = Color3.new(0,0,0)
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.COAlarm.NumBubble.Visible = true
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.COAlarm.FA_Status.Visible = true
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.COAlarm.FA_Status.Text = tostring(eventQueue.count.co)
		else
			panelDependencies.Screen.InspireDisplay.Main.StatusBar.BackgroundColor3 = Color3.new(1, 0.937255, 0.0431373)
			panelDependencies.Screen.InspireDisplay.Main.StatusBar.StatusLine.Text = "CO ALARM"
			panelDependencies.Screen.InspireDisplay.Main.StatusBar.COAlarmIcon.Visible = true
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.COAlarm.BackgroundColor3 = Color3.new(1, 0.937255, 0.0431373)
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.COAlarm.Icon.ImageColor3 = Color3.new(0,0,0)
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.COAlarm.TextColor3 = Color3.new(0,0,0)
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.COAlarm.NumBubble.Visible = true
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.COAlarm.FA_Status.Visible = true
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.COAlarm.FA_Status.Text = tostring(eventQueue.count.co)
		end
		if eventQueue.count.trouble == 0 and eventQueue.count.alarm == 0 and eventQueue.count.supervisory == 0 and eventQueue.count.other == 0 then
			panelDependencies.Screen.InspireDisplay.Main.Events.UnackedCOAlarmFull.Visible = true
			panelDependencies.Screen.InspireDisplay.Main.Events.UnackedCOAlarmFull.UnackedEvents.Count.Text = "UNACKNOWLEDGED CO ALARMS ("..tostring(#eventQueue.unacked.alarm)..")"
			for i,v in pairs(eventQueue.unacked.co) do
				local id = panelDependencies.Screen.InspireDisplay.Main.Objects.EventTemplates.Template:Clone()
				id.Name = v.deviceAddress
				id.Date.Text = v.date
				id.Time.Text = v.time
				id.DeviceLocation.Text = v.deviceName
				id.DeviceNumber.Text = v.deviceAddress
				id.DeviceType.Text = v.deviceType
				id.EventType.Text = v.eventType
				id.Zone.Text = v.deviceZone
				id.FireIcon.Image = "rbxassetid://14683530108"
				id.FireIcon.ImageColor3 = Color3.new(0, 0.333333, 1)
				id.Parent = panelDependencies.Screen.InspireDisplay.Main.Events.UnackedCOAlarmFull.Items
				id.Visible = true
				id:Clone().Parent = panelDependencies.Screen.InspireDisplay.Main.historymenu.history.History
			end	
		else
			panelDependencies.Screen.InspireDisplay.Main.Events.UnackedCOAlarmHalf.Visible = true
			panelDependencies.Screen.InspireDisplay.Main.Events.UnackedCOAlarmHalf.UnackedEvents.Count.Text = "UNACKNOWLEDGED CO ALARMS ("..tostring(#eventQueue.unacked.alarm)..")"
			for i,v in pairs(eventQueue.unacked.alarm) do
				local id = panelDependencies.Screen.InspireDisplay.Main.Objects.EventTemplates.Template:Clone()
				id.Name = v.deviceAddress
				id.Date.Text = v.date
				id.Time.Text = v.time
				id.DeviceLocation.Text = v.deviceName
				id.DeviceNumber.Text = v.deviceAddress
				id.DeviceType.Text = v.deviceType
				id.EventType.Text = v.eventType
				id.Zone.Text = v.deviceZone
				id.FireIcon.Image = "rbxassetid://14683530108"
				id.FireIcon.ImageColor3 = Color3.new(0, 0.333333, 1)
				id.Parent = panelDependencies.Screen.InspireDisplay.Main.Events.UnackedCOAlarmHalf.Items
				id.Visible = true
				id:Clone().Parent = panelDependencies.Screen.InspireDisplay.Main.historymenu.history.History
			end	
		end
	elseif eventInformation.type == "supervisory" then
		eventQueue.count.supervisory += 1
		if eventQueue.count.alarm >= 1 then
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.Supv.BackgroundColor3 = Color3.new(1, 0.92549, 0.0901961)
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.Supv.Icon.ImageColor3 = Color3.new(0,0,0)
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.Supv.TextColor3 = Color3.new(0,0,0)
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.Supv.NumBubble.Visible = true
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.Supv.FA_Status.Visible = true
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.Supv.FA_Status.Text = tostring(eventQueue.count.supervisory)
		else
			panelDependencies.Screen.InspireDisplay.Main.StatusBar.BackgroundColor3 = Color3.new(1, 0.937255, 0.0431373)
			panelDependencies.Screen.InspireDisplay.Main.StatusBar.StatusLine.Text = "SUPERVISORY"
			panelDependencies.Screen.InspireDisplay.Main.StatusBar.SupvIcon.Visible = true
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.Supv.BackgroundColor3 = Color3.new(1, 0.937255, 0.0431373)
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.Supv.Icon.ImageColor3 = Color3.new(0,0,0)
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.Supv.TextColor3 = Color3.new(0,0,0)
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.Supv.NumBubble.Visible = true
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.Supv.FA_Status.Visible = true
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.Supv.FA_Status.Text = tostring(eventQueue.count.supervisory)
		end
	elseif eventInformation.type == "trouble" then
		eventQueue.count.trouble += 1
		panelDependencies.Screen.Parent.Parent.NCD.Bezel.TroubleLED.Material = Enum.Material.Neon
		panelDependencies.Screen.Parent.Parent.NCD.Bezel.TroubleLED.BrickColor = BrickColor.new("New Yeller")
	elseif eventInformation.type == "disablement" then
		eventQueue.count.disablement += 1
	elseif eventInformation.type == "other" then
		eventQueue.count.other += 1
	elseif eventInformation.type == "systemEvent" then
		if eventInformation.mode == "silence" then
			if panelVars.silenced == false then
				addToLog("info","System Silenced","System silenced at "..tostring(os.date()))
				panelDependencies.API:Fire("NAC_Command",{selected = "*", mode = "silence", audibleSil = panelDependencies.LocalConfig.System_Functions.Audible_Silence})
				panelDependencies.Screen.InspireDisplay.Main.StatusFrame.SigSil.BackgroundColor3 = Color3.new(1, 0.92549, 0.0901961)
				script.Parent.LocalEvent:Fire("DVC_Command","Stop")	
			end
		elseif eventInformation.mode == "reset" then
			panelDependencies.Screen.InspireDisplay.Main.Visible = false
			panelDependencies.Screen.InspireDisplay.Reset.Visible = true
			
			panelDependencies.Screen.InspireDisplay.Main.StatusBar.BackgroundColor3 = Color3.new(0.27451, 0.27451, 0.27451)
			panelDependencies.Screen.InspireDisplay.Main.StatusBar.StatusLine.Text = "System Normal"
			panelDependencies.Screen.InspireDisplay.Main.StatusBar.SupvIcon.Visible = false
			panelDependencies.Screen.InspireDisplay.Main.StatusBar.FireIcon.Visible = false
			panelDependencies.Screen.InspireDisplay.Main.StatusBar.FaultIcon.Visible  = false
			panelDependencies.Screen.InspireDisplay.Main.StatusBar.DisableIcon.Visible = false
			panelDependencies.Screen.InspireDisplay.Main.StatusBar.COAlarmIcon.Visible = false
			panelDependencies.Screen.InspireDisplay.Main.StatusBar.SecurityIcon.Visible = false
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.Supv.BackgroundColor3 = Color3.new(0.254902, 0.254902, 0.254902)
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.Supv.Icon.ImageColor3 = Color3.new(0.294118, 0.294118, 0.294118)
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.Supv.TextColor3 = Color3.new(0.294118, 0.294118, 0.294118)
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.Supv.NumBubble.Visible = false
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.Supv.FA_Status.Visible = false
			
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.Trbl.BackgroundColor3 = Color3.new(0.254902, 0.254902, 0.254902)
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.Trbl.Icon.ImageColor3 = Color3.new(0.294118, 0.294118, 0.294118)
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.Trbl.TextColor3 = Color3.new(0.294118, 0.294118, 0.294118)
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.Trbl.NumBubble.Visible = false
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.Trbl.FA_Status.Visible = false
			
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.COAlarm.BackgroundColor3 = Color3.new(0.254902, 0.254902, 0.254902)
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.COAlarm.Icon.ImageColor3 = Color3.new(0.294118, 0.294118, 0.294118)
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.COAlarm.TextColor3 = Color3.new(0.294118, 0.294118, 0.294118)
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.COAlarm.NumBubble.Visible = false
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.COAlarm.FA_Status.Visible = false
			
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.Fire.BackgroundColor3 = Color3.new(0.254902, 0.254902, 0.254902)
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.Fire.Icon.ImageColor3 = Color3.new(0.294118, 0.294118, 0.294118)
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.Fire.TextColor3 = Color3.new(0.294118, 0.294118, 0.294118)
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.Fire.NumBubble.Visible = false
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.Fire.FA_Status.Visible = false
			
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.Other.BackgroundColor3 = Color3.new(0.254902, 0.254902, 0.254902)
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.Other.Icon.ImageColor3 = Color3.new(0.294118, 0.294118, 0.294118)
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.Other.TextColor3 = Color3.new(0.294118, 0.294118, 0.294118)
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.Other.NumBubble.Visible = false
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.Other.FA_Status.Visible = false
			
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.Disable.BackgroundColor3 = Color3.new(0.254902, 0.254902, 0.254902)
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.Disable.Icon.ImageColor3 = Color3.new(0.294118, 0.294118, 0.294118)
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.Disable.TextColor3 = Color3.new(0.294118, 0.294118, 0.294118)
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.Disable.NumBubble.Visible = false
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.Disable.FA_Status.Visible = false
			
			panelDependencies.Screen.InspireDisplay.Main.StatusFrame.SigSil.BackgroundColor3 = Color3.new(0.254902, 0.254902, 0.254902)
			
			
			panelDependencies.Screen.InspireDisplay.Main.InstructionBar.Instructions.Text = panelDependencies.LocalConfig.System_Configuration.Instructions.Step_1
			panelDependencies.Screen.InspireDisplay.Main.InstructionBar.Visible = false
			
			
			
			
			for i,v in pairs(panelDependencies.Screen.InspireDisplay.Main.Events:GetChildren()) do
				if v:IsA("ScrollingFrame") then
					v.Visible = false
					for z,d in pairs(v:GetChildren()) do
						if d.Name == "Items" then
							for n,m in pairs(d:GetChildren()) do
								if m:IsA("Frame") then
									m:Destroy()
								end
							end
						end
					end
				end
			end
			
			addToLog("success","System Reset","System reset issued at "..os.date())
			
			wait(3)
			
			panelDependencies.Screen.InspireDisplay.Reset.Visible = false
			panelDependencies.Screen.InspireDisplay.Main.BG.Visible = true
			panelDependencies.Screen.InspireDisplay.Main.Visible = true
		elseif eventInformation.mode == "restartNode" then
			
			if eventInformation.query == script.Parent.Parent.Name then
				reboot()
				addToLog("api","API: Node Restarted","System restarted  at "..tostring(os.date()))
			end
		elseif eventInformation.mode == "ack" then
			if panelDependencies.Piezo.Playing then
				panelDependencies.Piezo:Stop()
			end
		end
	else
		if eventInformation.type then
			local event = panelDependencies.LocalConfig.Event_Mapping[eventInformation.type]
			
			if event then
				local payload = {
					type = event.Map_To,
					deviceInfo = {
						Address = eventInformation.deviceInfo.Address or "N/A",
						DeviceName = eventInformation.deviceInfo.DeviceName or "N/A",
						DeviceType = eventInformation.deviceInfo.DeviceType or "N/A",
						DeviceZone = eventInformation.deviceInfo.DeviceZone or "N/A"
					}
				}
				panelDependencies.API:Fire("Input",payload)
				
			else
				out("warn","Failed to find an event for "..eventInformation.type.."!")
			end
		end
	end
end

panelDependencies.API.Event:Connect(function(data, data1)
	if data == "Input" then
		processEvent(data1)
	end
end)


panelDependencies.Screen.InspireDisplay.Main.Ack.MouseButton1Click:Connect(function()
	chirp()
	if panelVars.loggedIn.level < panelDependencies.PanelConfig.Security.Permissions.Acknowledge then
		addToLog("warning","Ackowlege Failed","Event(s) could not be acknowledged due to insufficient access.")
		popUp("Access Denied!","Insufficient Access Level, Login First!",nil,nil)
	else -- < Allow
		panelDependencies.API:Fire("Input",{type = "systemEvent", mode = "ack"})
		addToLog("success","Ackowleged","Event(s) acknowledged successfully")
		panelDependencies.Screen.InspireDisplay.Main.InstructionBar.Step.Text = "Step 2:"
		panelDependencies.Screen.InspireDisplay.Main.InstructionBar.Instructions.Text = panelDependencies.LocalConfig.System_Configuration.Instructions.Step_2
		panelDependencies.Screen.InspireDisplay.Main.Ack.Interactable = false
		panelDependencies.Screen.InspireDisplay.Main.Silence.Interactable = true
		panelDependencies.Screen.InspireDisplay.Main.Silence.BackgroundColor3 = Color3.new(0.0235294, 0.870588, 1)
		panelDependencies.Screen.InspireDisplay.Main.Ack.BackgroundColor3 = Color3.new(0.254902, 0.254902, 0.254902)
	end
end)

panelDependencies.Screen.InspireDisplay.Main.Silence.MouseButton1Click:Connect(function()
	chirp()
	if panelVars.loggedIn.level < panelDependencies.PanelConfig.Security.Permissions.Silence then
		addToLog("warning","Silence Failed","System silence failed due to insufficient access.")
		popUp("Access Denied!","Insufficient Access Level, Login First!",nil,nil)
	else -- < Allow
		addToLog("success","System Silenced","System has been silenced at "..tostring(os.date()))
		panelDependencies.Screen.InspireDisplay.Main.InstructionBar.Step.Text = "Step 3:"
		panelDependencies.Screen.InspireDisplay.Main.InstructionBar.Instructions.Text = panelDependencies.LocalConfig.System_Configuration.Instructions.Step_3
		panelDependencies.Screen.InspireDisplay.Main.Silence.Interactable = false
		panelDependencies.Screen.InspireDisplay.Main.Reset.Interactable = true
		panelDependencies.Screen.InspireDisplay.Main.Reset.BackgroundColor3 = Color3.new(0.0235294, 0.870588, 1)
		panelDependencies.Screen.InspireDisplay.Main.Silence.BackgroundColor3 = Color3.new(0.254902, 0.254902, 0.254902)
		panelDependencies.API:Fire("Input",{type = "systemEvent", mode = "silence"})
	end
end)

panelDependencies.Screen.InspireDisplay.Main.Reset.MouseButton1Click:Connect(function()
	chirp()
	if panelVars.loggedIn.level < panelDependencies.PanelConfig.Security.Permissions.Reset then
		addToLog("warning","Reset Failed","System reset failed due to insufficient access.")
		popUp("Access Denied!","Insufficient Access Level, Login First!",nil,nil)
	else -- < Allow
		addToLog("success","System Reset","System reset issued at "..tostring(os.date()))
		panelDependencies.API:Fire("Input",{type = "systemEvent", mode = "reset"})
		panelDependencies.Screen.InspireDisplay.Main.InstructionBar.Step.Text = "Step 1:"
		panelDependencies.Screen.InspireDisplay.Main.InstructionBar.Instructions.Text = panelDependencies.LocalConfig.System_Configuration.Instructions.Step_1
		panelDependencies.Screen.InspireDisplay.Main.Reset.Interactable = false
		panelDependencies.Screen.InspireDisplay.Main.Ack.Interactable = false
		panelDependencies.Screen.InspireDisplay.Main.Ack.BackgroundColor3 = Color3.new(0.254902, 0.254902, 0.254902)
		panelDependencies.Screen.InspireDisplay.Main.Reset.BackgroundColor3 = Color3.new(0.254902, 0.254902, 0.254902)
		panelDependencies.API:Fire("Input",{type = "systemEvent", mode = "silence"})
	end
end)

panelDependencies.Screen.Parent.Bezel.Plate.zjnksdnvkhk.MouseClick:Connect(function(plr)
	if game.Workspace:FindFirstChild(plr.Name) then
		if game.Workspace:FindFirstChild(plr.Name):FindFirstChild("InspireZoom") then
			game.Workspace:FindFirstChild(plr.Name).InspireZoom.wheretolook:Destroy()
			wait(1)
			game.Workspace:FindFirstChild(plr.Name).InspireZoom:Destroy()
		else
			local e = script.Cam_Zoom:Clone()
			e.Name = "InspireZoom"
			e.Enabled = true
			e.wheretolook.Value = panelDependencies.Screen.Parent.CamTar
			e.Parent = game.Workspace:FindFirstChild(plr.Name)
		end
	end
end)

panelDependencies.Screen.InspireDisplay.Main.MenuFrame.MainMenu.MouseButton1Click:Connect(function()
	chirp()
	panelVars.mainMenOpen = not panelVars.mainMenOpen
	if panelVars.eventType == "none" then
		panelDependencies.Screen.InspireDisplay.Main.BG.Visible = not panelVars.mainMenOpen
		panelDependencies.Screen.InspireDisplay.Main.MainMenu.Visible = panelVars.mainMenOpen
	end
end)

panelDependencies.Screen.InspireDisplay.Main.MenuFrame.UserSettings.MouseButton1Click:Connect(function()
	chirp()
	if panelVars.loggedIn.level == 0 then
		panelVars.authPageOpen = not panelVars.authPageOpen
		panelVars.mainMenOpen = false
		panelDependencies.Screen.InspireDisplay.Main.BG.Visible = not panelVars.authPageOpen
		panelDependencies.Screen.InspireDisplay.Main.MainMenu.Visible = false
		panelDependencies.Screen.InspireDisplay.Main.auth.Visible = panelVars.authPageOpen
	else
		panelVars.userSetPageOpen = not panelVars.userSetPageOpen
		panelDependencies.Screen.InspireDisplay.Main.BG.Visible = not panelVars.userSetPageOpen
		panelDependencies.Screen.InspireDisplay.Main.MainMenu.Visible = false
		panelDependencies.Screen.InspireDisplay.Main.basicUser.Visible = panelVars.userSetPageOpen
	end
	
end)

panelDependencies.Screen.InspireDisplay.Main.basicUser.LogOut.MouseButton1Click:Connect(function()
	chirp()
	if panelVars.loggedIn.level ~= 0 then
		panelVars.loggedIn.level = panelDependencies.LocalConfig.Users["Public Access"].Level
		panelVars.loggedIn.user = panelDependencies.LocalConfig.Users["Public Access"]
		panelDependencies.Screen.InspireDisplay.Main.basicUser.Visible = false
		panelDependencies.Screen.InspireDisplay.Main.AccessL.Text = "Public Access"
		panelDependencies.Screen.InspireDisplay.Main.BG.Visible = true
		panelVars.menOpen = "none"
		panelVars.mainMenOpen = false
		panelVars.authPageOpen = false
		panelVars.userSetPageOpen = false
	else
		popUp("Not Logged in!","You can't exit this account at this time.",2)
	end
end)

panelDependencies.Screen.InspireDisplay.Main.MainMenu.settings.MouseButton1Click:Connect(function()
	chirp()
	if panelVars.loggedIn.level < panelDependencies.PanelConfig.Security.Permissions.Menu_L1 then
		popUp("Access Denied!","Insufficient Access Level, Login First!",nil,nil)
	else -- < Allow
		if panelVars.mainMenOpen then
			panelVars.mainMenOpen = false
			panelVars.menOpen = "settings"
			panelDependencies.Screen.InspireDisplay.Main.settingsmenu.Visible = true
			panelDependencies.Screen.InspireDisplay.Main.MainMenu.Visible = false
		end
	end
end)

panelDependencies.Screen.InspireDisplay.Main.settingsmenu.Mainmenu.MouseButton1Click:Connect(function()
	chirp()
	if panelVars.menOpen == "settings" then
		panelVars.menOpen = "none"
		panelVars.mainMenOpen = true
		panelDependencies.Screen.InspireDisplay.Main.settingsmenu.Visible = false
		panelDependencies.Screen.InspireDisplay.Main.MainMenu.Visible = true
	end
end)
panelDependencies.Screen.InspireDisplay.Main.MainMenu.testdiags.MouseButton1Click:Connect(function()
	chirp()
	if panelVars.loggedIn.level < panelDependencies.PanelConfig.Security.Permissions.Menu_L2 then
		popUp("Access Denied!","Insufficient Access Level, Login First!",nil,nil)
	else -- < Allow
		if panelVars.mainMenOpen then
			panelVars.mainMenOpen = false
			panelVars.menOpen = "testdiag"
			panelDependencies.Screen.InspireDisplay.Main.testdiagmenu.Visible = true
			panelDependencies.Screen.InspireDisplay.Main.MainMenu.Visible = false
		end
	end
end)

panelDependencies.Screen.InspireDisplay.Main.testdiagmenu.Mainmenu.MouseButton1Click:Connect(function()
	chirp()
	if panelVars.menOpen == "testdiag" then
		panelVars.menOpen = "none"
		panelVars.mainMenOpen = true
		panelDependencies.Screen.InspireDisplay.Main.testdiagmenu.Visible = false
		panelDependencies.Screen.InspireDisplay.Main.MainMenu.Visible = true
	end
end)
-- About Section
panelDependencies.Screen.InspireDisplay.Main.settingsmenu.About.MouseButton1Click:Connect(function()
	chirp()
	if panelVars.menOpen == "settings" then
		panelVars.menOpen = "settings-about"
		panelDependencies.Screen.InspireDisplay.Main.settingsmenu.Visible = false
		panelDependencies.Screen.InspireDisplay.Main.about.Visible = true
	end
end)

panelDependencies.Screen.InspireDisplay.Main.about.Restart.MouseButton1Click:Connect(function()
	chirp()
	if panelVars.loggedIn.level < panelDependencies.PanelConfig.Security.Permissions.Menu_L1 then
		popUp("Access Denied!","Insufficient Access Level, Login First!",nil,nil)
	else -- < Allow
		popUp("System Restart","System will restart in 5 seconds.",5,Color3.new(0.333333, 1, 0))
		wait(5)
		reboot()
	end
end)

panelDependencies.Screen.InspireDisplay.Main.about.Firmware.MouseButton1Click:Connect(function()
	chirp()
	if panelVars.menOpen == "settings-about" then
		panelVars.menOpen = "settings-about-firmware"
		panelDependencies.Screen.InspireDisplay.Main.aboutFirm.Visible = true
		panelDependencies.Screen.InspireDisplay.Main.about.Visible = false
	end
end)

panelDependencies.Screen.InspireDisplay.Main.aboutFirm.Mainmenu.MouseButton1Click:Connect(function()
	chirp()
	if panelVars.menOpen == "settings-about-firmware" then
		panelVars.menOpen = "settings-about"
		panelDependencies.Screen.InspireDisplay.Main.aboutFirm.Visible = false
		panelDependencies.Screen.InspireDisplay.Main.about.Visible = true
	end
end)

panelDependencies.Screen.InspireDisplay.Main.about.OS.MouseButton1Click:Connect(function()
	chirp()
	if panelVars.menOpen == "settings-about" then
		panelVars.menOpen = "settings-about-os"
		panelDependencies.Screen.InspireDisplay.Main.aboutOS.Visible = true
		panelDependencies.Screen.InspireDisplay.Main.about.Visible = false
	end
end)

panelDependencies.Screen.InspireDisplay.Main.aboutOS.Mainmenu.MouseButton1Click:Connect(function()
	chirp()
	if panelVars.menOpen == "settings-about-os" then
		panelVars.menOpen = "settings-about"
		panelDependencies.Screen.InspireDisplay.Main.aboutOS.Visible = false
		panelDependencies.Screen.InspireDisplay.Main.about.Visible = true
	end
end)

panelDependencies.Screen.InspireDisplay.Main.about.Mainmenu.MouseButton1Click:Connect(function()
	chirp()
	if panelVars.menOpen == "settings-about" then
		panelVars.menOpen = "settings"
		panelDependencies.Screen.InspireDisplay.Main.settingsmenu.Visible = true
		panelDependencies.Screen.InspireDisplay.Main.about.Visible = false
	end
end)

-- End of about

-- Licensing Menu --

panelDependencies.Screen.InspireDisplay.Main.settingsmenu.Licensing.MouseButton1Click:Connect(function()
	chirp()
	if panelVars.menOpen == "settings" then
		panelVars.menOpen = "settings-licensing"
		panelDependencies.Screen.InspireDisplay.Main.settingsmenu.Visible = false
		panelDependencies.Screen.InspireDisplay.Main.licensing.Visible = true
	end
end)

panelDependencies.Screen.InspireDisplay.Main.licensing.Mainmenu.MouseButton1Click:Connect(function()
	chirp()
	if panelVars.menOpen == "settings-licensing" then
		panelVars.menOpen = "settings"
		panelDependencies.Screen.InspireDisplay.Main.settingsmenu.Visible = true
		panelDependencies.Screen.InspireDisplay.Main.licensing.Visible = false
	end
end)

-- End of licensing menu --
-- History Menu -- -- testdiag

panelDependencies.Screen.InspireDisplay.Main.testdiagmenu.History.MouseButton1Click:Connect(function()
	chirp()
	if panelVars.menOpen == "testdiag" then
		panelVars.menOpen = "testdiag-history"
		panelDependencies.Screen.InspireDisplay.Main.testdiagmenu.Visible = false
		panelDependencies.Screen.InspireDisplay.Main.historymenu.Visible = true
	end
end)

panelDependencies.Screen.InspireDisplay.Main.testdiagmenu.ClearDatabase.MouseButton1Click:Connect(function()
	chirp()
	if panelVars.menOpen == "testdiag" then
		popUp("History Buffer Cleared","Cleared the history buffer successfully.",2)
		for _, event in pairs(panelDependencies.Screen.InspireDisplay.Main.historymenu.history.History:GetChildren()) do
			if event:IsA("Frame") then
				event:Destroy()
			end
		end
	end
end)

panelDependencies.Screen.InspireDisplay.Main.historymenu.Mainmenu.MouseButton1Click:Connect(function()
	chirp()
	if panelVars.menOpen == "testdiag-history" then
		panelVars.menOpen = "testdiag"
		panelDependencies.Screen.InspireDisplay.Main.testdiagmenu.Visible = true
		panelDependencies.Screen.InspireDisplay.Main.historymenu.Visible = false
	end
end)


-- End of history menu --

function submitAuth()
	local success, newLevel = AuthenticateUser(panelVars.userNameInput, panelVars.userPassInput)
	if success then
		panelVars.loggedIn.user = panelVars.userNameInput
		panelVars.loggedIn.level = newLevel
		panelDependencies.Screen.InspireDisplay.Main.AccessL.Text = panelVars.userNameInput
		panelVars.userNameInput = ""
		panelVars.userPassInput = ""
		panelDependencies.Screen.InspireDisplay.Main.auth.Inputs.UsernameINPUT.Text = ""
		panelDependencies.Screen.InspireDisplay.Main.auth.Inputs.PasswordINPUT.Text = ""
		
		panelDependencies.Screen.InspireDisplay.Main.auth.Visible = false
		
		panelDependencies.Screen.InspireDisplay.Main.auth.Labels.UsernameLABEL.Text = "<u>Username</u>"
		panelDependencies.Screen.InspireDisplay.Main.auth.Labels.PasswordLABEL.Text = "Password"
		panelVars.authScreenCurrInput = "USER"
		if panelVars.eventType ~= "none" then
			panelDependencies.Screen.InspireDisplay.Main.BG.Visible = false
		else
			panelDependencies.Screen.InspireDisplay.Main.BG.Visible = true
		end
		
	else
		popUp("Access Denied","No user found with the provided credentials!",3)
		panelVars.userNameInput = ""
		panelVars.userPassInput = ""
		panelDependencies.Screen.InspireDisplay.Main.auth.Inputs.UsernameINPUT.Text = ""
		panelDependencies.Screen.InspireDisplay.Main.auth.Inputs.PasswordINPUT.Text = ""
		panelVars.authScreenCurrInput = "USER"
		panelDependencies.Screen.InspireDisplay.Main.auth.Labels.UsernameLABEL.Text = "<u>Username</u>"
	end
end

panelDependencies.Screen.InspireDisplay.Main.auth.keyboard.clear.MouseButton1Click:Connect(function()
	chirp()
	panelVars.userNameInput = ""
	panelVars.userPassInput = ""
	panelDependencies.Screen.InspireDisplay.Main.auth.Inputs.UsernameINPUT.Text = ""
	panelDependencies.Screen.InspireDisplay.Main.auth.Inputs.PasswordINPUT.Text = ""
	panelVars.authScreenCurrInput = "USER"
	panelDependencies.Screen.InspireDisplay.Main.auth.Labels.UsernameLABEL.Text = "<u>Username</u>"
end)

panelDependencies.Screen.InspireDisplay.Main.auth.keyboard.enter.MouseButton1Click:Connect(function()
	chirp()
	if panelVars.authScreenCurrInput == "USER" then
		panelVars.authScreenCurrInput = "PASS"
		panelDependencies.Screen.InspireDisplay.Main.auth.Labels.UsernameLABEL.Text = "Username"
		panelDependencies.Screen.InspireDisplay.Main.auth.Labels.PasswordLABEL.Text = "<u>Password</u>"	
	elseif panelVars.authScreenCurrInput == "PASS" then
		panelDependencies.Screen.InspireDisplay.Main.auth.Labels.UsernameLABEL.Text = "<u>Username</u>"
		panelDependencies.Screen.InspireDisplay.Main.auth.Labels.PasswordLABEL.Text = "Password"
		submitAuth()
	end
end)

panelDependencies.Screen.InspireDisplay.Main.auth.keyboard.changeK.MouseButton1Click:Connect(function()
	chirp()
	-- Valid Types:  -- lwc, upc, num, sym
	if panelVars.authScreenCurrKeyb == "lwc" then
		panelDependencies.Screen.InspireDisplay.Main.auth.keyboard.lwc.Visible = false
		panelDependencies.Screen.InspireDisplay.Main.auth.keyboard.upc.Visible = true
		panelDependencies.Screen.InspireDisplay.Main.auth.keyboard.num.Visible = false
		panelDependencies.Screen.InspireDisplay.Main.auth.keyboard.sym.Visible = false
		panelVars.authScreenCurrKeyb = "upc"
	elseif panelVars.authScreenCurrKeyb == "upc" then
		panelDependencies.Screen.InspireDisplay.Main.auth.keyboard.lwc.Visible = false
		panelDependencies.Screen.InspireDisplay.Main.auth.keyboard.upc.Visible = false
		panelDependencies.Screen.InspireDisplay.Main.auth.keyboard.num.Visible = true
		panelDependencies.Screen.InspireDisplay.Main.auth.keyboard.sym.Visible = false
		panelVars.authScreenCurrKeyb = "num" 
	elseif panelVars.authScreenCurrKeyb == "num" then
		panelDependencies.Screen.InspireDisplay.Main.auth.keyboard.lwc.Visible = false
		panelDependencies.Screen.InspireDisplay.Main.auth.keyboard.upc.Visible = false
		panelDependencies.Screen.InspireDisplay.Main.auth.keyboard.num.Visible = false
		panelDependencies.Screen.InspireDisplay.Main.auth.keyboard.sym.Visible = true
		panelVars.authScreenCurrKeyb = "sym"
	elseif panelVars.authScreenCurrKeyb == "sym" then
		panelDependencies.Screen.InspireDisplay.Main.auth.keyboard.lwc.Visible = true
		panelDependencies.Screen.InspireDisplay.Main.auth.keyboard.upc.Visible = false
		panelDependencies.Screen.InspireDisplay.Main.auth.keyboard.num.Visible = false
		panelDependencies.Screen.InspireDisplay.Main.auth.keyboard.sym.Visible = false
		panelVars.authScreenCurrKeyb = "lwc"
	end
end)


function clean()
	if panelVars.eventType == "none" then
		panelDependencies.Screen.InspireDisplay.Main.Visible = false
		panelDependencies.Screen.InspireDisplay.Cleaning.Visible = true
		panelDependencies.Screen.InspireDisplay.Cleaning.timer.time.Text = tostring(panelDependencies.PanelConfig.Timers.Cleaning)
		for i = panelDependencies.PanelConfig.Timers.Cleaning, 0, -1 do
			wait(1)
			panelDependencies.Screen.InspireDisplay.Cleaning.timer.time.Text = tostring(i)
			if i == 0 then
				panelDependencies.Screen.InspireDisplay.Main.Visible = false
				panelDependencies.Screen.InspireDisplay.Cleaning.Visible = true
			end
		end
	end
end






for _, child in ipairs(panelDependencies.Screen.InspireDisplay.Main.auth.keyboard:GetDescendants()) do
	if child:IsA("TextButton") then
		if child.Name == "changeK" then return end
		if child.Name == "enter" then return end
		if child.Name == "clear" then return end
		child.MouseButton1Click:Connect(function()
			chirp()
			if panelVars.authScreenCurrInput == "USER" then
				panelVars.userNameInput = panelVars.userNameInput..child.Text
				panelDependencies.Screen.InspireDisplay.Main.auth.Inputs.UsernameINPUT.Text = panelVars.userNameInput
			elseif panelVars.authScreenCurrInput == "PASS" then
				panelVars.userPassInput = panelVars.userPassInput..child.Text
				panelDependencies.Screen.InspireDisplay.Main.auth.Inputs.PasswordINPUT.Text = panelDependencies.Screen.InspireDisplay.Main.auth.Inputs.PasswordINPUT.Text.."*"
			end
		end)
	end
end






















































-- // Polling! Interrogate devices. \\ --

