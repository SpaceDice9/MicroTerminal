local MicroTerminal = {}

local CHAR_SPACE = 32
local CHAR_BACKSLASH = 92

local RunContext = {}
RunContext.__index = RunContext

function RunContext:ContainsShortFlag(index, shortFlag)
	local options = self.Flags[index]

	for _, option in options do
		if string.match(option, shortFlag) ~= "" then
			return true
		end
	end

	return nil
end

function RunContext:_GetLongFlag(longFlag, comparisonFlag)
	local isolatedFlag = string.split(longFlag, "=")

	if isolatedFlag[1] == comparisonFlag then
		return true, isolatedFlag[2]
	end
end

function RunContext:ContainsLongFlag(index, longFlag)
	local options = self.Flags[index]

	for _, option in options do
		local exists, stringValue = self:_GetLongFlag(option, longFlag)

		if exists then
			return stringValue or true
		end
	end

	return nil
end

function RunContext:ContainsFlags(index, ...)
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

function MicroTerminal.IsFlag(token)
	return string.match(token, "^%-")
end

function MicroTerminal.IsLongFlag(token)
	return string.match(token, "^%-%-")
end

function MicroTerminal.IsShortFlag(token)
	return (MicroTerminal.IsFlag(token) and not MicroTerminal.IsLongFlag(token))
end

function MicroTerminal.GetTokens(inputString)
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

function MicroTerminal.TokensToRunContext(tokens)
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

return MicroTerminal