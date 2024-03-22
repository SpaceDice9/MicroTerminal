local Selection = game:GetService("Selection")
local LogService = game:GetService("LogService")

local Types = require(script.types)

local MicroTerminal = {}

local CHAR_SPACE = 32
local CHAR_BACKSLASH = 92
local MAX_INSTANCE_PATH_RESOLVE = 1000

local Expectors: {[string]: Expector} = {}

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

function MicroTerminal.GetInstanceFromPath(path: string)
	local focus = Selection:Get()[1] or workspace
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

function Expectors.boolean(valueString)
	if valueString == "true" then
		return true, true
	elseif valueString == "false" then
		return true, false
	end

	return false, nil
end

function Expectors.number(valueString)
	if tonumber(valueString) then
		return true, tonumber(valueString)
	end

	return false, nil
end

function Expectors.string(valueString)
	return true, valueString
end

function Expectors.instance(valueString)
	local instance = MicroTerminal.GetInstanceFromPath(valueString)

	if instance then
		return true, instance
	end

	return false, nil
end

function Expectors.exists(valueString)
	return true, true
end

local RunContext = {}
RunContext.__index = RunContext

function RunContext._GetExpectationFromComparisonFlag(comparisonFlag)
	local isolatedFlag = string.split(comparisonFlag, "=")

	if #isolatedFlag == 1 then
		return
	end

	local expectorName = string.match(isolatedFlag[2], "^{(.+)}$")
	local expector = Expectors[expectorName]

	if expector then
		return expector
	end
end

function RunContext:ContainsShortFlag(index: number, shortFlag: string): true | nil
	local options = self.Flags[index]

	for _, option in options do
		if MicroTerminal.IsShortFlag(option) and string.match(option, shortFlag) ~= "" then
			return true
		end
	end

	return nil
end

function RunContext:_GetLongFlag(longFlag, comparisonFlag)
	local isolatedFlag = string.split(longFlag, "=")
	local isolatedComparisonFlag = string.split(comparisonFlag, "=")

	if isolatedFlag[1] == isolatedComparisonFlag[1] then
		local valueString = isolatedFlag[2]
		local expector = RunContext._GetExpectationFromComparisonFlag(comparisonFlag) or Expectors.exists
		local success, value = expector(valueString)

		return true, value
	end
end

function RunContext:ContainsLongFlag(index: number, longFlag: string): any
	local options = self.Flags[index]

	for _, option in options do
		local exists, value = self:_GetLongFlag(option, longFlag)

		if exists then
			return value
		end
	end

	return nil
end

function RunContext:ContainsFlags(index: number, ...: string): any
	local flags = {...}
	local value = nil

	for _, flag in flags do
		if MicroTerminal.IsLongFlag(flag) then
			value = self:ContainsLongFlag(index, flag)
		else
			value = self:ContainsShortFlag(index, flag)
		end

		if value ~= nil then
			return value
		end
	end
end

function RunContext:Param(index: number, expectation: string?): any
	local param = self.Params[index]
	local value = param

	if not param then
		return
	end

	if expectation then
		local expector = Expectors[expectation]

		if expector then
			local success
			success, value = expector(param)
		end
	end

	return value
end

function MicroTerminal._GetEndOfTokenIndex(charArray, init)
	local escaping = false

	for i = init, #charArray do
		local char = charArray[i]

		if escaping then
			escaping = false
			continue
		end

		if char == CHAR_BACKSLASH then
			escaping = true

			-- removes the backslash from the string
			table.remove(charArray, i)
			i -= 1
		elseif char == CHAR_SPACE then
			return i
		end
	end

	return #charArray + 1
end

function MicroTerminal._GetNextTokenIndex(charArray, init)
	for i = init, #charArray do
		local char = charArray[i]

		if char ~= CHAR_SPACE then
			return i
		end
	end

	return #charArray
end

function MicroTerminal.IsFlag(token: string): boolean
	return not not string.match(token, "^%-")
end

function MicroTerminal.IsLongFlag(token: string): boolean
	return not not string.match(token, "^%-%-")
end

function MicroTerminal.IsShortFlag(token: string): boolean
	return (MicroTerminal.IsFlag(token) and not MicroTerminal.IsLongFlag(token))
end

function MicroTerminal.GetTokens(inputString: string): {string}
	local tokens = {}
	local charArray = {string.byte(inputString, 1, string.len(inputString))}
	local cursor = 1

	while cursor < #charArray do
		cursor = MicroTerminal._GetNextTokenIndex(charArray, cursor)
		local endOfToken = MicroTerminal._GetEndOfTokenIndex(charArray, cursor)

		if endOfToken > cursor then
			local token = string.char(table.unpack(charArray, cursor, endOfToken - 1))

			table.insert(tokens, token)
		end

		cursor = endOfToken
	end

	return tokens
end

function MicroTerminal.TokensToRunContext(tokens: {string}): RunContext
	local runContext = {
		Params = {},
		Flags = {}
	}

	for _, token in tokens do
		if MicroTerminal.IsFlag(token) then
			local options = runContext.Flags[#runContext.Flags]
			table.insert(options, token)
		else
			table.insert(runContext.Params, token)
			table.insert(runContext.Flags, {})
		end
	end

	setmetatable(runContext, RunContext)

	return runContext
end

function MicroTerminal.Print(value: any)
	task.defer(print, ">> ", value)
end

function MicroTerminal.PrintCommand(commandString: string)
	task.defer(print, "> --" .. commandString)
end

function MicroTerminal.RegisterCommand(prefix: string, func: (RunContext) -> (string?)): RBXScriptConnection
	return LogService.MessageOut:Connect(function(message, messageType)
		if messageType ~= Enum.MessageType.MessageOutput then
			return
		end

		if string.sub(message, 1, 4 + string.len(prefix)) == "> --" .. prefix then
			local commandString = string.sub(message, 5)
			local runContext = MicroTerminal.TokensToRunContext(MicroTerminal.GetTokens(commandString))
			local returnValue = func(runContext)

			if returnValue == nil then
				return
			end

			MicroTerminal.Print(returnValue)
		end
	end)
end

MicroTerminal.Expectors = Expectors

export type RunContext = Types.RunContext
export type Expector = Types.Expector

return MicroTerminal