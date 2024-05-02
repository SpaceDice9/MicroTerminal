# MicroTerminal Documentation
Work in progess.

## RunContext
An object generated when running commands. Use this for reading flags and parameters.


### `(true | nil) :ContainsShortFlag(int index, string shortFlag)`
Gives whether the command has a short flag at index. Short flags do not support expectors.


### `any :ContainsLongFlag(int index, string longFlag)`

Gives whether the command has a long flag at index. If an expectation is set this will try to typecast into that.


### `any :ContainsFlags(int index, string ...)`

Gives whether the command has at least one of several flags at index. If an expectation is set this will try to typecast into that.


### `any :Param(int index, (string | Expector)? expectation)`

Gives a parameter at index. If an expectation is set this will try to typecast into that.


## MicroTerminal
The main library.

### `boolean .IsFlag(string token)`


### `boolean .IsLongFlag(string token)`


### `boolean .IsShortFlag(string token)`


### `{string} .GetTokens(string inputString)`
Tokenizes a given input string.


### `RunContext .TokensToRunContext({string} tokens)`
Returns a RunContext from tokens.


### `Instance? .GetInstanceFromPath(string path)`
Resolves an instance path into an Instance, if it exists.


### `.Print(any value)`


### `.PrintCommand(string commandString)`


### `.OutputToLog(TerminalLog terminalLog, any value)`


### `(RBXScriptConnection, GoodSignalConnection) .BindTerminalLogToRobloxOutput(TerminalLog terminalLog)`
Binds a given TerminalLog object to Roblox's output/console.


### `.RegisterCommandToTerminalLog(TerminalLog terminalLog, string prefix, ((RunContext) -> (string?)) func)`
Registers a command to a terminal log


### `RBXScriptConnection .RegisterCommandToRobloxOutput(string prefix, ((RunContext) -> (string?)) func)`
Registers a command to Roblox console.


### `any .RunCommand(string commandString, ((RunContext) -> (string?)) func)`
Runs a command directly.


## InstancePath
An object used to resolve instance paths with custom roots, foci and homes.

### Fields

### `Instance .Root`

### `Instance .Home`

### `Instance .Focus`

### Methods

### `InstancePath .new(Instance root, Instance home, Instance focus)`

### `Instance? :Resolve(string path)`


## TerminalLog
Used for simulating a terminal. Only use this for more technical uses of MT.

### `:Input(any input, string? inputType)`

### `:Output(any output, OutputType? outputType)`

### `TerminalLog .new(int maxLogLength)`


## Expectors

Expectors in MicroTerminal are used for automatic typecasting for parameters and flags.

* `boolean`
* `number`
* `string`
* `instance`
* `narray` (number array)
* `vector3`
* `strarray` (string array)
* `color3`
* `vector2`
* `enum`