local HttpService = game:GetService("HttpService")
local API = script.Parent.Parent.Parent.Data


local function sendWebhookEmbed(eventCode, eventInfo, webhookUrl, embedColor)
	-- Convert Color3 to a decimal integer for Discord
	local r = math.floor(embedColor.R * 255)
	local g = math.floor(embedColor.G * 255)
	local b = math.floor(embedColor.B * 255)
	local decimalColor = (r * 65536) + (g * 256) + b

	local data = {
		["username"] = "Notifier Inspire",
		["avatar_url"] = "https://cdn.matterrbx.com/images/pulsar/pulsar-logo.png", -- Replace with your image URL
		["embeds"] = {{
			["title"] = "New Event: (" .. eventCode .. ")",
			["color"] = decimalColor,
			["fields"] = {
				{["name"] = "Device Name", ["value"] = eventInfo.DeviceName, ["inline"] = false},
				{["name"] = "Device Type", ["value"] = eventInfo.DeviceType, ["inline"] = false},
				{["name"] = "Address", ["value"] = eventInfo.DeviceAddress, ["inline"] = false},
				{["name"] = "Zone", ["value"] = eventInfo.DeviceZone, ["inline"] = false}
			},
			["footer"] = {
				["text"] = "A Matter Service | " .. os.date("%X"),
				["icon_url"] = "https://example.com/footer-icon.png" -- Replace with your icon URL
			}
		}}
	}

	-- Encode the table into JSON
	local finalData = HttpService:JSONEncode(data)

	-- Wrap in pcall to prevent the script from crashing if the request fails
	local success, response = pcall(function()
		return HttpService:PostAsync(webhookUrl, finalData)
	end)

	if not success then
		local info = {
			EventType = "COMM_SENT",
			Error = false,
			EventDetails = "CLSS Communicated event to external service."
		}
		API:Fire("Halot_Event",info)
	else
		local info = {
			EventType = "COMM_FAIL",
			Error = true,
			EventDetails = "CLSS Failed to communicate with an external service."
		}
		API:Fire("Halot_Event",info)
	end
end


API.Event:Connect(function(data,data1,data2,data3,data4,data5,data6,data7)
	if data == "Halot_Event" then return end -- Prevent Halot events from reporting.
end)
