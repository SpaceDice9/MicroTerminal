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

function convertToNumberArray(array)
	local isValidVector = true

	for i, numberString in array do
		local number = tonumber(numberString)

		if number then
			array[i] = number
		else
			isValidVector = false
			break
		end
	end

	return isValidVector
end

function Expectors.narray(valueString)
	local array = string.split(valueString, ",")
	local isValidVector = convertToNumberArray(array)

	if isValidVector then
		return true, array
	end

	return false, nil
end

function Expectors.vector3(valueString)
	local vectorArray = string.split(valueString, ",")
	local isValidVector = convertToNumberArray(vectorArray)

	if #vectorArray == 3 and isValidVector then
		return true, Vector3.new(vectorArray[1], vectorArray[2], vectorArray[3])
	end

	return false, nil
end

function Expectors.strarray(valueString)
	local array = string.split(valueString, ",")

	if #array == 0 then
		return false, nil
	end

	return true, array
end

function Expectors.color3(valueString)
	if string.match(valueString, "^#") then
		-- deal with hex values
		local red = tonumber("0x" .. string.sub(valueString, 2, 3))
		local green = tonumber("0x" .. string.sub(valueString, 4, 5))
		local blue = tonumber("0x" .. string.sub(valueString, 6, 7))

		if red and green and blue then
			return true, Color3.fromRGB(red, green, blue)
		else
			return false, nil
		end
	end

	local vectorArray = string.split(valueString, ",")
	local isValidVector = convertToNumberArray(vectorArray)

	if #vectorArray == 3 and isValidVector then
		return true, Color3.fromRGB(vectorArray[1], vectorArray[2], vectorArray[3])
	end

	return false, nil
end

function Expectors.vector2(valueString)
	local vectorArray = string.split(valueString, ",")
	local isValidVector = convertToNumberArray(vectorArray)

	if #vectorArray == 2 and isValidVector then
		return true, Vector2.new(vectorArray[1], vectorArray[2])
	end

	return false, nil
end

function Expectors.enum(valueString)
	local enumNames = string.split(valueString, ".")
	local enum = Enum[enumNames[1]]

	if not enum then
		return
	end

	local enumItem = enum[enumNames[2]]

	if enumItem then
		return true, enumNames
	else
		return false, nil
	end
end

function Expectors.exists(valueString)
	return true, true
end

return Expectors