vim.api.nvim_create_user_command("ESRunner", function(opts)
	-- get selected range if provided
	local range = {}
	if opts.range > 0 then
		range = { opts.line1, opts.line2 }
	end

	require("esrunner.commands").execute(range, unpack(opts.fargs))
end, {
	nargs = "?",
	range = true,
	complete = function(cur, line)
		local sub_commands = { "run", "find_apps", "validate_apps" }
		local l = vim.split(line, "%s+")

		if #l - 1 == 0 then
			return sub_commands
		end

		return vim.tbl_filter(function(value)
			return string.match(value, cur)
		end, sub_commands)
	end,
})
