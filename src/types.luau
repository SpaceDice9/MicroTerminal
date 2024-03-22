export type RunContext = {
	Params: {string},
	Flags: {{string}},

	ContainsShortFlag: (self: RunContext, index: number, flag: string) -> (true | nil),
	ContainsLongFlag: (self: RunContext, index: number, flag: string) -> (any),
	ContainsFlags: (self: RunContext, index: number, ...string) -> (any),
}

export type Expector = (valueString: string) -> (boolean, any)

return {}