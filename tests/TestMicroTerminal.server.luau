--[[ Test for MicroTerminal ]]

local BytLib = require(script.BytLib)
local microTerminal = BytLib.Require(game.ServerStorage.MicroTerminal)

print("        [[ Test MicroTerminal ]]")

function toCharArray(str)
	return {string.byte(str, 1, string.len(str))}
end

local passed = true
local allTestsPassed = true

do
	passed = true
		and (microTerminal._GetEndOfTokenIndex(toCharArray "gdex --readout", 1) == 5)
		and (microTerminal._GetEndOfTokenIndex(toCharArray "gdex --readout", 6) == 15)
		and (microTerminal._GetEndOfTokenIndex(toCharArray "gdex --readout --verbose", 6) == 15)
		and (microTerminal._GetEndOfTokenIndex(toCharArray "gdex--readout", 1) == 14)
	print("_GetEndOfTokenIndex", passed)
	allTestsPassed = allTestsPassed and passed
end

do
	passed = true
		and (microTerminal._GetNextTokenIndex(toCharArray "   gdex", 1) == 4)
		and (microTerminal._GetNextTokenIndex(toCharArray "gdex --readout", 5) == 6)
		and (microTerminal._GetNextTokenIndex(toCharArray "gdex --readout  ", 15) == 16)
	print("_GetNextTokenIndex", passed)
	allTestsPassed = allTestsPassed and passed
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
	allTestsPassed = allTestsPassed and passed
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
	allTestsPassed = allTestsPassed and passed
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
	allTestsPassed = allTestsPassed and passed
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
	allTestsPassed = allTestsPassed and passed
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
	allTestsPassed = allTestsPassed and passed
end

runContext = microTerminal.TokensToRunContext(microTerminal.GetTokens("gdex --vbucks=100 --cash= --verbose --tmode=shallow --nmode=false"))

do
	passed = true
		and (runContext:ContainsFlags(1, "--tmode={string}") == "shallow")
		and (runContext:ContainsFlags(1, "--vbucks={number}") == 100)
		and (runContext:ContainsFlags(1, "--cash={number}") == nil)
		and (runContext:ContainsFlags(1, "--cash") == true)
		and (runContext:ContainsFlags(1, "--nmode={boolean}") == false)
	print("runContext:ContainsFlags [expectors]", passed)
	allTestsPassed = allTestsPassed and passed
end


do -- Expector.*
	runContext = microTerminal.TokensToRunContext(microTerminal.GetTokens("gdex --number-1=7 --number-2=-3 --number-3=0.25 --number-4=0xFF"))

	do -- Expector.number
		passed = true
			and (runContext:ContainsFlags(1, "--number-1={number}") == 7)
			and (runContext:ContainsFlags(1, "--number-2={number}") == -3)
			and (runContext:ContainsFlags(1, "--number-3={number}") == 0.25)
			and (runContext:ContainsFlags(1, "--number-4={number}") == 0xFF)
		print("Expector.number", passed)
		allTestsPassed = allTestsPassed and passed
	end

	runContext = microTerminal.TokensToRunContext(microTerminal.GetTokens("gdex --bool-1=true --bool-2=false --bool-3=fase"))

	do -- Expector.boolean
		passed = true
			and (runContext:ContainsFlags(1, "--bool-1={boolean}") == true)
			and (runContext:ContainsFlags(1, "--bool-2={boolean}") == false)
			and (runContext:ContainsFlags(1, "--bool-3={boolean}") == nil)
		print("Expector.boolean", passed)
		allTestsPassed = allTestsPassed and passed
	end

	runContext = microTerminal.TokensToRunContext(microTerminal.GetTokens("gdex --str-1=Faze --str-2=Et\\ tu --str-3=\"Et tu, Brute?\""))

	do -- Expector.string
		passed = true
			and (runContext:ContainsFlags(1, "--str-1={string}") == "Faze")
			and (runContext:ContainsFlags(1, "--str-2={string}") == "Et tu")
			and (runContext:ContainsFlags(1, "--str-3={string}") == "Et tu, Brute?")
		print("Expector.string", passed)
		allTestsPassed = allTestsPassed and passed
	end

	runContext = microTerminal.TokensToRunContext(microTerminal.GetTokens("gdex --nar-1=1,5,7 --nar-2=1"))

	do -- Expector.narray
		passed = true
			and table_compare(runContext:ContainsFlags(1, "--nar-1={narray}"), {1, 5, 7})
			and table_compare(runContext:ContainsFlags(1, "--nar-2={narray}"), {1})
		print("Expector.narray", passed)
		allTestsPassed = allTestsPassed and passed
	end

	runContext = microTerminal.TokensToRunContext(microTerminal.GetTokens("gdex --color-1=100,110,120 --color-2=#AABBCC"))

	do -- Expector.color3
		passed = true
			and (runContext:ContainsFlags(1, "--color-1={color3}") == Color3.fromRGB(100, 110, 120))
			and (runContext:ContainsFlags(1, "--color-2={color3}") == Color3.fromHex("#AABBCC"))
		print("Expector.color3", passed)
		allTestsPassed = allTestsPassed and passed
	end

	runContext = microTerminal.TokensToRunContext(microTerminal.GetTokens("gdex --enum-1=Material.ForceField --enum-2=MessageType.MessageOutput"))

	do -- Expector.enum
		passed = true
			and (runContext:ContainsFlags(1, "--enum-1={enum}") == Enum.Material.ForceField)
			and (runContext:ContainsFlags(1, "--enum-2={enum}") == Enum.MessageType.MessageOutput)
		print("Expector.enum", passed)
		allTestsPassed = allTestsPassed and passed
	end

	runContext = microTerminal.TokensToRunContext(microTerminal.GetTokens("gdex --stra-1=Lorem,Lorem\\ ipsum,\"Lorem ipsum\""))

	do -- Expector.strarray
		passed = true
			and table_compare(runContext:ContainsFlags(1, "--stra-1={strarray}"), {"Lorem", "Lorem ipsum", "Lorem ipsum"})
		print("Expector.strarray", passed)
		allTestsPassed = allTestsPassed and passed
	end
end


do
	passed = true
		and (microTerminal.GetInstanceFromPath(";Workspace") == workspace)
		and (microTerminal.GetInstanceFromPath(";Workspace;Baseplate") == workspace.Baseplate)
		and (microTerminal.GetInstanceFromPath(";Workspace;Baseplate;Texture;..") == workspace.Baseplate)
		and (microTerminal.GetInstanceFromPath(";Workspace;Baseplate;Texture.Parent") == workspace.Baseplate)
	print("GetInstanceFromPath", passed)
	allTestsPassed = allTestsPassed and passed
end

do
	passed = true
		and (runContext._GetExpectationFromComparisonFlag("--nmode={number}") == microTerminal.Expectors.number)
		and (runContext._GetExpectationFromComparisonFlag("--nmode={boolean}") == microTerminal.Expectors.boolean)
		and (not runContext._GetExpectationFromComparisonFlag("--nmode={boolean}{}"))
		and (runContext._GetExpectationFromComparisonFlag("--nmode={string}") == microTerminal.Expectors.string)
		and (runContext._GetExpectationFromComparisonFlag("--nmode={narray}") == microTerminal.Expectors.narray)
		and (runContext._GetExpectationFromComparisonFlag("--nmode={color3}") == microTerminal.Expectors.color3)
		and (runContext._GetExpectationFromComparisonFlag("--nmode={exists}") == microTerminal.Expectors.exists)
	print("runContext._GetExpectationFromComparisonFlag", passed)
	allTestsPassed = allTestsPassed and passed
end

print("")
print("Passed all tests:", allTestsPassed)