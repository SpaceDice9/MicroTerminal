local MicroTerminal = require(game.ServerStorage.MicroTerminal)

-- Use while playtesting
function command(runContext: MicroTerminal.RunContext)
	-- It is casted into a number automatically!
	local mode: number = runContext:ContainsFlags(1, "--mode={number}")

	-- The second parameter is used because the first one is just the command prefix
	local parent: Instance = runContext:Param(2, "instance")

	print("Using mode " .. mode .. " in Instance " .. parent.Name)
end

MicroTerminal.RegisterCommandToRobloxOutput("example", command)