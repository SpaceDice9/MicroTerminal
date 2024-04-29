local GoodSignal = require(script.Parent.GoodSignal)

local TerminalLog = {}
TerminalLog.__index = TerminalLog

function TerminalLog.new(maxLogLength)
	local self = {
		Log = {},
		MaxLogLength = maxLogLength,

		OnInput = GoodSignal.new(), -- Event
		OnOutput = GoodSignal.new(), -- Event
		OnLog = GoodSignal.new(), -- Event
	}

	setmetatable(self, TerminalLog)

	return self
end

function trimLogs(self)
	if #self.Log > self.MaxLogLength then
		table.remove(self.Log, 1)
	end
end

function TerminalLog:Input(str: string, inputType: string)
	table.insert(self.Stream, str)
	trimLogs(self)

	self.OnInput:Fire(str, inputType)
	self.OnLog:Fire(str, inputType)
end

function TerminalLog:Output(str: string, outputType: string)
	table.insert(self.Stream, str)
	trimLogs(self)

	self.OnOutput:Fire(str, outputType)
	self.OnLog:Fire(str, outputType)
end