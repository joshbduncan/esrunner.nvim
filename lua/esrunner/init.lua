local M = {}

M["version"] = "0.1.0"

---Setup user configuration options
---@param opts table User configuration options
M.setup = function(opts)
	opts = opts or {}
	require("esrunner.config").set_options(opts)
end

return M
