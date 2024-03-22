local Selection = game:GetService("Selection")

local Util = {}

local MAX_INSTANCE_PATH_RESOLVE = 1000

function getPatternContext(str, pattern, init, plain)
	local match = string.match(str, pattern, init)
	local start, finish = string.find(str, pattern, init, plain)

	return match, start, finish
end

function cut(str, pattern, init)
	local match, start, finish = getPatternContext(str, pattern, init)

	if match then
		return match:sub(1, start - 1) .. match:sub(finish + 1, str:len())
	end
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

function tryGetFirstSelection()
	local success, selected = pcall(function()
		return Selection:Get()
	end)

	if success then
		return selected[1]
	end
end

function Util.GetInstanceFromPath(path: string)
	local focus = tryGetFirstSelection() or workspace
	local player = game.Players.LocalPlayer
	local root = nil
	local init = 1

	local unprocessed = path

	if string.match(path, "^%w+") then
		root = traverse(focus, true, string.match(path, "^%w+"))

		local match, start, finish = getPatternContext(path, "^%w+")
		init = init + finish
	elseif string.match(path, "^/%w+") then
		root = game
		root = traverse(root, true, string.match(path, "%w+"))

		local match, start, finish = getPatternContext(path, "^/%w+")
		init = init + finish
	elseif string.match(path, "^/") then
		root = game

		local match, start, finish = getPatternContext(path, "^/")
		init = init + finish
	elseif player and string.match(path, "^~") then
		root = player

		local match, start, finish = getPatternContext(path, "^~")
		init = init + finish
	elseif string.match(path, "^%.%.") then
		root = traverse(focus)

		local match, start, finish = getPatternContext(path, "^%.%.")
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

		local match, start, finish = getPatternContext(path, "^%.%w+")
		init = init + finish
	elseif string.match(path, "^%.") then
		root = focus

		local match, start, finish = getPatternContext(path, "^%.")
		init = init + finish
	else
		return
	end

	local instance = root
	local n = 0

	while init <= path:len() and n < MAX_INSTANCE_PATH_RESOLVE do
		unprocessed = path:sub(init, path:len())

		if string.match(unprocessed, "^/%w+") then
			instance = traverse(instance, true, string.match(unprocessed, "%w+"))

			local match, start, finish = getPatternContext(unprocessed, "^/%w+")
			init = init + finish
		elseif string.match(unprocessed, "^/%.%.") then
			instance = traverse(instance)

			local match, start, finish = getPatternContext(unprocessed, "^/%.%.")
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

			local match, start, finish = getPatternContext(unprocessed, "^%.%w+")
			init = init + finish
		else
			return
		end

		n = n + 1
	end

	return instance
end

return Util