--[[
	An example demonstrating MicroTerminal in a GUI-less plugin
	This tool imports assets
	Type `--!imp -h` in the Command Bar to get started.
]]

local Selection = game:GetService("Selection")

local MicroTerminal = require(script.Parent.MicroTerminal)

function toAssetUrl(assetId)
	return `rbxassetid://{assetId}`
end

function getAssetId(reference)
	local decomposed = string.split(reference, "/")
	local assetId

	if decomposed[1] == "https:" then
		if decomposed[3] == "create.roblox.com" then
			-- Handle new roblox creator links
			if decomposed[4] == "marketplace" then
				assetId = decomposed[6] -- Legacy creator marketplace asset link
			elseif decomposed[4] == "store" and decomposed[5] == "asset" then
				assetId = decomposed[6] -- Roblox Creator Store asset link
			end
		elseif decomposed[3] == "www.roblox.com" or decomposed[3] == "web.roblox.com" then
			if decomposed[4] == "library" then
				assetId = decomposed[5] -- Legacy developer asset link
			elseif decomposed[4] == "catalog" then
				assetId = decomposed[5] -- Catalog link
			end
		end
	elseif string.match(decomposed[1], "%d+") == decomposed[1] then
		assetId = decomposed[1] -- Raw asset id
	end

	return assetId
end

function printHelp()
	task.defer(print, [[

usage:
--!imp [-h --help] [--no-select --no-auto-select] [-c --catalog]  asset  location

flags:
	-h --help                      Pulls up this help message
	--no-select --no-auto-select   Disables automatically selecting imported assets
	--pack=packetname              The name of the packet
	--no-packing                   Disables packing tuple of assets

params:
	asset                          The asset identifier. Import tool will automatically convert it to the correct form
	location                       The final location where imported asset will appear
]])

end

function getAsset(assetId)
	local url = toAssetUrl(assetId)

	local success, assets = pcall(function()
		return game:GetObjects(url)
	end)

	if success then
		return assets
	end
end

function parentAll(parent, children)
	for _, asset in children do
		asset.Parent = parent
	end
end

function pluralize(singular, plural, amount)
	if amount == 1 then
		return singular
	else
		return plural
	end
end

function imp(runContext)
	local help = runContext:ContainsFlags(1, "-h", "--help")
	local no_auto_select = runContext:ContainsFlags(1, "-S", "--no-select", "--no-auto-select")
	local no_packing = runContext:ContainsFlags(1, "--no-packing")
	local packName = runContext:ContainsFlags(1, "--pack={string}")

	local ref = runContext:Param(2)
	local parent = runContext:Param(3, "instance") or workspace

	if help or not ref then
		printHelp()
		return
	end

	local assetId = getAssetId(ref)
	local assets = getAsset(assetId)
	local assetAmount = #assets

	if not assets then
		MicroTerminal.Print("import failed to load asset")
		return
	end

	if not no_packing and assetAmount > 1 then
		local packetFolder = Instance.new("Folder")
		packetFolder.Name = if (packName and packName ~= "") then packName else "Packet"

		parentAll(packetFolder, assets)
		assets = {packetFolder}
	end

	parentAll(parent, assets)

	if not no_auto_select then
		Selection:Set(assets)
	end

	MicroTerminal.Print(`import loaded { pluralize("asset", "assets", assetAmount) } (x{ assetAmount }) successfully`)
end

local commandConnection = MicroTerminal.RegisterCommandToRobloxOutput("!imp", imp)

plugin.Unloading:Connect(function()
	commandConnection:Disconnect()
end)