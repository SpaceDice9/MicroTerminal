local InstancePath = {}
InstancePath.__index = InstancePath

local MAX_INSTANCE_PATH_RESOLVE = 1000

function InstancePath.new(root, home, focus)
	root = root or game
	home = home or game:GetService("Players").LocalPlayer or workspace
	focus = focus or home

	local instancePath = {
		Root = root,
		Home = home,
		Focus = focus
	}

	setmetatable(instancePath, InstancePath)

	return instancePath
end

function traverse(instance, toChild, name)
	if instance then
		if toChild then
			return instance:FindFirstChild(name)
		else
			return instance.Parent
		end
	end
end

function tryAccessProperty(instance, property)
	return pcall(function()
		return instance[property]
	end)
end

-- use ; instead of /
-- it's really ugly but it wouldn't work with the output any other way
function InstancePath:Resolve(path: string): Instance?
	local focus = self.Focus
	local home = self.Home
	local root = self.Root
	local init = 1

	local unprocessed = path

	if string.match(path, "^%w+") then
		root = traverse(focus, true, string.match(path, "^%w+"))

		local _, finish = string.find(path, "^%w+")
		init = init + finish
	elseif string.match(path, "^;%w+") then
		root = game
		root = traverse(root, true, string.match(path, "%w+"))

		local _, finish = string.find(path, "^;%w+")
		init = init + finish
	elseif string.match(path, "^;") then
		root = game

		local _, finish = string.find(path, "^;")
		init = init + finish
	elseif home and string.match(path, "^~") then
		root = home

		local _, finish = string.find(path, "^~")
		init = init + finish
	elseif string.match(path, "^%.%.") then
		root = traverse(focus)

		local _, finish = string.find(path, "^%.%.")
		init = init + finish
	elseif string.match(path, "^%.%w+") then
		local success, value = tryAccessProperty(focus, string.match(path, "%w+"))

		if not success then
			return
		end

		if typeof(value) ~= "Instance" then
			return
		end

		root = value

		local _, finish = string.find(path, "^%.%w+")
		init = init + finish
	elseif string.match(path, "^%.") then
		root = focus

		local _, finish = string.find(path, "^%.")
		init = init + finish
	else
		return
	end

	local instance = root
	local n = 0

	while init <= path:len() and n < MAX_INSTANCE_PATH_RESOLVE do
		unprocessed = path:sub(init, path:len())

		if string.match(unprocessed, "^;%w+") then
			instance = traverse(instance, true, string.match(unprocessed, "%w+"))

			local _, finish = string.find(unprocessed, "^;%w+")
			init = init + finish
		elseif string.match(unprocessed, "^;%.%.") then
			instance = traverse(instance)

			local _, finish = string.find(unprocessed, "^;%.%.")
			init = init + finish
		elseif string.match(unprocessed, "^%.%w+") then
			local success, value = tryAccessProperty(instance, string.match(unprocessed, "%w+"))

			if not success then
				return
			end

			if typeof(value) ~= "Instance" then
				return
			end

			instance = value

			local _, finish = string.find(unprocessed, "^%.%w+")
			init = init + finish
		else
			return
		end

		n = n + 1
	end

	return instance
end

return InstancePath