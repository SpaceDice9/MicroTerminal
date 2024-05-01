local GoodSignal = require(script.Parent.Packages.goodsignal)
local Types = require(script.Parent.types)

local TerminalLog = {
	Print = "Print",
	Warn = "Warn",
	Error = "Error",
	Info = "Info",
}
TerminalLog.__index = TerminalLog

function TerminalLog.new(maxLogLength: number): Types.TerminalLog
	local self = {
		Log = {},
		MaxLogLength = maxLogLength,

		OnInput = GoodSignal.new(),
		OnOutput = GoodSignal.new(),
		OnLog = GoodSignal.new(),
	}

	setmetatable(self, TerminalLog)

	return self
end

function trimLogs(self)
	if #self.Log > self.MaxLogLength then
		table.remove(self.Log, 1)
	end
end

function TerminalLog:Input(input: any, inputType: string?)
	table.insert(self.Log, input)
	trimLogs(self)

	self.OnInput:Fire(input, inputType)
	self.OnLog:Fire(input, inputType)
end

function TerminalLog:Output(output: any, outputType: Types.OutputType?)
	table.insert(self.Log, output)
	trimLogs(self)

	self.OnOutput:Fire(output, outputType)
	self.OnLog:Fire(output, outputType)
end

return TerminalLog