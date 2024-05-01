export type RunContext = {
	Params: {string},
	Flags: {{string}},

	ContainsShortFlag: (self: RunContext, index: number, flag: string) -> (true | nil),
	ContainsLongFlag: (self: RunContext, index: number, flag: string) -> (any),
	ContainsFlags: (self: RunContext, index: number, ...string) -> (any),
	Param: (self: RunContext, index: number, expectation: string?) -> (any),
}

export type GoodSignalConnection = {
	Disconnect: (self: GoodSignalConnection) -> (),
}

export type GoodSignal = {
	Connect: (self: GoodSignal, fn: (...any) -> ()) -> GoodSignalConnection,
	DisconnectAll: (self: GoodSignal) -> (),
	Fire: (self: GoodSignal, ...any) -> (),
	Wait: (self: GoodSignal) -> (...any),
	Once: (self: GoodSignal, fn: (...any) -> ()) -> GoodSignalConnection,
}

export type TerminalLog = {
	Log: {any},
	MaxLogLength: number,

	Print: "Print",
	Warn: "Warn",
	Error: "Error",
	Info: "Info",

	OnInput: GoodSignal,
	OnOutput: GoodSignal,
	OnLog: GoodSignal,

	Input: (self: TerminalLog, input: any, inputType: string?) -> (),
	Output: (self: TerminalLog, output: any, outputType: OutputType?) -> (),
}

export type OutputType = "Print" | "Warn" | "Error" | "Info"

export type Expector = (valueString: string) -> (boolean, any)

return {}