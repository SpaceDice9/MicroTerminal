local Selection = game:GetService("Selection")
local InstancePath = require(script.Parent.InstancePath)

local Util = {}

function tryGetFirstSelection()
	local success, selected = pcall(function()
		return Selection:Get()
	end)

	if success then
		return selected[1]
	end
end

function Util.GetInstanceFromPath(path: string)
	return InstancePath.new(game, game:GetService("Players").LocalPlayer or workspace, tryGetFirstSelection()):Resolve(path)
end

return Util