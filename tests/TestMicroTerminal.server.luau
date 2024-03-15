--[[ Test for MicroTerminal ]]

local BytLib = require(script.BytLib)
local microTerminal = BytLib.Require(game.ServerStorage.MicroTerminal)

print("        [[ Test MicroTerminal ]]")

function toCharArray(str)
	return {string.byte(str, 1, string.len(str))}
end

local passed = true

do
	passed = true
		and (microTerminal._GetEndOfTokenIndex(toCharArray "gdex --readout", 1) == 5)
		and (microTerminal._GetEndOfTokenIndex(toCharArray "gdex --readout", 6) == 15)
		and (microTerminal._GetEndOfTokenIndex(toCharArray "gdex --readout --verbose", 6) == 15)
		and (microTerminal._GetEndOfTokenIndex(toCharArray "gdex--readout", 1) == 14)
	print("_GetEndOfTokenIndex", passed)
end

do
	passed = true
		and (microTerminal._GetNextTokenIndex(toCharArray "   gdex", 1) == 4)
		and (microTerminal._GetNextTokenIndex(toCharArray "gdex --readout", 5) == 6)
		and (microTerminal._GetNextTokenIndex(toCharArray "gdex --readout  ", 15) == 16)
	print("_GetNextTokenIndex", passed)
end

function table_compare(t1, t2)
	for k, v in t1 do
		if v ~= t2[k] then
			return false
		end
	end

	for k, v in t2 do
		if v ~= t1[k] then
			return false
		end
	end

	return true
end

do
	passed = true
		and table_compare({"gdex"}, microTerminal.GetTokens("gdex "))
		and table_compare({"gdex", "--readout"}, microTerminal.GetTokens("gdex --readout"))
		and table_compare({"gdex", "--readout", "-v"}, microTerminal.GetTokens("gdex  --readout  -v"))
		and table_compare({"gdex", "--readout", "-v"}, microTerminal.GetTokens("gdex  --readout  -v   "))
	print("GetTokens", passed)
end

do
	passed = true
		and (microTerminal.IsFlag("--"))
		and (microTerminal.IsFlag("--verbose"))
		and (microTerminal.IsFlag("--tmode=skipall"))
		and (microTerminal.IsFlag("-v"))
		and (microTerminal.IsFlag("-"))
		and (not microTerminal.IsFlag("verbose"))
		and (not microTerminal.IsFlag("a--verbose"))
	print("IsFlag", passed)
end

do
	passed = true
		and (microTerminal.IsLongFlag("--"))
		and (microTerminal.IsLongFlag("--verbose"))
		and (microTerminal.IsLongFlag("--tmode=skipall"))
		and (not microTerminal.IsLongFlag("-v"))
		and (not microTerminal.IsLongFlag("-"))
		and (not microTerminal.IsLongFlag("verbose"))
		and (not microTerminal.IsLongFlag("a--verbose"))
	print("IsLongFlag", passed)
end

do
	passed = true
		and (not microTerminal.IsShortFlag("--"))
		and (not microTerminal.IsShortFlag("--verbose"))
		and (not microTerminal.IsShortFlag("--tmode=skipall"))
		and (microTerminal.IsShortFlag("-v"))
		and (microTerminal.IsShortFlag("-"))
		and (not microTerminal.IsShortFlag("verbose"))
		and (not microTerminal.IsShortFlag("a--verbose"))
	print("IsShortFlag", passed)
end

local runContext = microTerminal.TokensToRunContext(microTerminal.GetTokens("gdex -abc --vbucks=100 --cash= --verbose --tmode=shallow ./field --readout --nmode=false -I"))

do
	passed = true
		and (runContext:ContainsFlags(1, "-v"))
		and (runContext:ContainsFlags(1, "-v", "--verbose"))
		and (runContext:ContainsFlags(1, "--catalog", "-c"))
		and (not runContext:ContainsFlags(1, "--readout"))

		and (runContext:ContainsFlags(1, "--tmode={string}", "-T") == "shallow")
		and (runContext:ContainsFlags(1, "--vbucks={number}") == 100)
		and (runContext:ContainsFlags(1, "--cash={number}") == nil)

		and (runContext:ContainsFlags(2, "--readout"))
		and (runContext:ContainsFlags(2, "-I"))
		and (runContext:ContainsFlags(2, "--readout={exists}"))
		and (runContext:ContainsFlags(2, "--nmode={boolean}") == false)
	print("runContext:ContainsFlags", passed)
end

runContext = microTerminal.TokensToRunContext(microTerminal.GetTokens("gdex --vbucks=100 --cash= --verbose --tmode=shallow --readout=/Workspace --nmode=false"))

do
	passed = true
		and (runContext:ContainsFlags(1, "--tmode={string}") == "shallow")
		and (runContext:ContainsFlags(1, "--vbucks={number}") == 100)
		and (runContext:ContainsFlags(1, "--cash={number}") == nil)
		and (runContext:ContainsFlags(1, "--readout={instance}") == workspace)
		and (runContext:ContainsFlags(1, "--nmode={boolean}") == false)
	print("runContext:ContainsFlags [expectors]", passed)
end

do
	passed = true
		and (microTerminal.GetInstanceFromPath("/Workspace") == workspace)
		and (microTerminal.GetInstanceFromPath("/Workspace/Baseplate") == workspace.Baseplate)
		and (microTerminal.GetInstanceFromPath("/Workspace/Baseplate/Texture/..") == workspace.Baseplate)
		and (microTerminal.GetInstanceFromPath("/Workspace/Baseplate/Texture.Parent") == workspace.Baseplate)
	print("GetInstanceFromPath", passed)
end

do
	passed = true
		and (runContext._GetExpectationFromComparisonFlag("--nmode={number}") == microTerminal.Expectors.number)
		and (runContext._GetExpectationFromComparisonFlag("--nmode={boolean}") == microTerminal.Expectors.boolean)
		and (not runContext._GetExpectationFromComparisonFlag("--nmode={boolean}{}"))
		and (runContext._GetExpectationFromComparisonFlag("--nmode={string}") == microTerminal.Expectors.string)
		and (runContext._GetExpectationFromComparisonFlag("--nmode={exists}") == microTerminal.Expectors.exists)
	print("runContext._GetExpectationFromComparisonFlag", passed)
end