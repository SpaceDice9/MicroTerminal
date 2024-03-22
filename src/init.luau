local Selection = game:GetService("Selection")
local LogService = game:GetService("LogService")

local Util = require(script.util)
local Types = require(script.types)

local MicroTerminal = {}

local CHAR_SPACE = 32
local CHAR_BACKSLASH = 92

local Expectors: {[string]: Expector} = require(script.expectors)

function MicroTerminal.GetInstanceFromPath(path: string)
	return Util.GetInstanceFromPath(path)
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

		if string.sub(message, 1, 4 + string.len(prefix) + 1) ~= "> --" .. prefix .. " " then
			return
		end

		local commandString = string.sub(message, 5)
		local runContext = MicroTerminal.TokensToRunContext(MicroTerminal.GetTokens(commandString))
		local returnValue = func(runContext)

		if returnValue == nil then
			return
		end

		MicroTerminal.Print(returnValue)
	end)
end

MicroTerminal.Expectors = Expectors

export type RunContext = Types.RunContext
export type Expector = Types.Expector

return MicroTerminal