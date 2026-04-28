local M = {}

M.check = function()
	vim.health.start("esrunner")

	-- platform check
	if vim.fn.has("mac") == 1 then
		vim.health.ok("Running on macOS")
	else
		vim.health.error("esrunner.nvim only supports macOS")
		return
	end

	-- apps configured
	local apps = require("esrunner.config").apps
	if vim.tbl_isempty(apps) then
		vim.health.error("No apps configured. Call require('esrunner').setup{ apps = { ... } }")
		return
	end

	-- validate each app path
	local utils = require("esrunner.utils")
	for name, app in pairs(apps) do
		if utils.validate_app_directory(app.path) then
			vim.health.ok(string.format("%s found at %s", name, app.path))
		else
			vim.health.warn(string.format("%s not found at %s", name, app.path))
		end
	end
end

return M
