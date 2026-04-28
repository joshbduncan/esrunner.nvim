local M = {}

M["version"] = "0.1.0"

---Setup user configuration options
---@param opts ESRunnerOpts
M.setup = function(opts)
	opts = opts or {}
	if opts.apps == nil then
		vim.notify("esrunner: opts.apps is required. See `:help esrunner.setup`.", vim.log.levels.ERROR)
		return
	end
	require("esrunner.config").set_options(opts)
end

return M
