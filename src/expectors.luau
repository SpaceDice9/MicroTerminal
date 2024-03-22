local Util = require(script.Parent.util)

local Expectors = {}

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
	local instance = Util.GetInstanceFromPath(valueString)

	if instance then
		return true, instance
	end

	return false, nil
end

function Expectors.exists(valueString)
	return true, true
end

return Expectors