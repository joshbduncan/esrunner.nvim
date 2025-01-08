local commands = {}

---Execute an ESRunner command
---@param range table Visual selection range { start_line, end_line }
---@param command string Command to execute. Defaults to 'run'.
commands.execute = function(range, command)
	command = command or "run"
	if command == "run" then
		commands.run_script(range)
	elseif command == "find_apps" then
		commands.find_apps()
	elseif command == "validate_apps" then
		commands.validate_apps()
	end
end

---Execute the current buffer or a range of lines.
---@param range table Visual selection range { start_line, end_line }
commands.run_script = function(range)
	local utils = require("esrunner.utils")
	local s, e = 1, vim.api.nvim_buf_line_count(0)
	local fp = vim.fn.expand("%:p")

	if not vim.tbl_isempty(range) then
		s, e = unpack(range)
		local lines = vim.api.nvim_buf_get_lines(0, s - 1, e, true)
		fp = utils.save_temp_file(lines)
	else
		-- validate the current buffer
		local is_modified = vim.api.nvim_get_option_value("modified", { buf = 0 })
		if is_modified then
			error("Buffer has unsaved changes", vim.log.levels.ERROR)
		end
		if not utils.valid_filetype() then
			error("Buffer has unsaved changes", vim.log.levels.ERROR)
		end
	end

	local choices = vim.tbl_keys(require("esrunner.config").apps)
	local target_line = utils.check_for_target(s, e)

	if target_line > 0 then
		local content = vim.api.nvim_buf_get_lines(0, target_line - 1, target_line, false)

		-- extract all specifiers
		-- https://extendscript.docsforadobe.dev/interapplication-communication/application-and-namespace-specifiers.html#application-and-namespace-specifiers
		local target_specifier = string.match(content[1], "^%s*[%p/]*target%s+(%S+)")
		local appname, instance, version, locale = utils.parse_target_specifier(target_specifier)

		if appname == nil or not utils.validate_target_specifier(appname) then
			error(string.format("Invalid target '%s'. See `:help esrunner.targets`.", appname), vim.log.levels.ERROR)
		end

		choices = utils.match_target_specifier_to_app(appname, version)
	end

	-- sort choices before displaying
	table.sort(choices, function(a, b)
		return a < b
	end)

	utils.pick_app(choices, fp)
end

---Find supported application paths on the current system
commands.find_apps = function()
	---Process System Profiler XML Data
	---@param data string System Profiler XML Data
	---@return table # Extracted application paths
	local process_system_profiler_xml = function(data)
		local targets = {}
		for _, value in pairs(require("esrunner.config").targets) do
			table.insert(targets, value.app)
		end

		-- ensure we got an actual xml file
		local plist_check = string.find(data, '<plist version="1.0">.*</plist>')
		if data == "" or plist_check == nil then
			error("Error reading system_profiler data.", vim.log.levels.ERROR)
		end

		-- determine where to start searching
		local s, e = string.find(data, "<key>_SPCommandLineArguments</key>.-<dict>")
		s = e - 6

		-- read in all apps
		local apps = {}
		while true do
			-- search for app dict
			s, e = string.find(data, "<dict>.-</dict>", s)

			-- no need to continue if no more <dict>s
			-- `while s ~= true...` was showing wanting in linter
			if s == nil then
				break
			end

			-- extract app data
			local d = string.sub(data, s, e)
			local name = string.match(d, "<key>_name</key>.-<string>(.-)</string>")
			local path = string.match(d, "<key>path</key>.-<string>(.-)</string>")
			local version = string.match(d, "<key>version</key>.-<string>(.-)</string>")

			-- break if app name or path can't be extracted
			if name == nil or path == nil then
				break
			end

			-- check if app matches any target apps
			for _, app in pairs(targets) do
				if string.find(name, app) ~= nil then
					table.insert(apps, { name, path, version })
					break
				end
			end

			-- move start search position forward
			s, e = e, nil
		end

		return apps
	end

	-- execute the system command
	local cmd = { "system_profiler", "-xml", "SPApplicationsDataType" }
	local result = ""
	local error_result = ""
	local job = vim.system(cmd, {
		text = true,
		stdout = function(_, data)
			if data then
				result = result .. data
			end
		end,
		stderr = function(_, data)
			if data then
				error_result = error_result .. data
			end
		end,
	}):wait()

	local exit_code = job["code"]

	if exit_code ~= 0 and error_result ~= "" then
		vim.notify(error_result, vim.log.levels.ERROR)
	end

	local app_data = process_system_profiler_xml(result)

	-- exit if no valid adobe apps are found
	if vim.tbl_isempty(app_data) then
		vim.notify("No valid applications found.", vim.log.levels.WARN)
		return
	end

	-- generate a formatted system apps report table
	local utils = require("esrunner.utils")
	local app_report = utils.generate_system_apps_table(app_data)

	local buf = vim.api.nvim_create_buf(true, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(vim.inspect(app_report), "\n"))
	vim.api.nvim_win_set_buf(0, buf)
end

---Validate user config application paths
commands.validate_apps = function()
	local apps = require("esrunner.config").apps
	local utils = require("esrunner.utils")
	for key, value in pairs(apps) do
		local fp = value["path"]
		if utils.validate_app_directory(fp) then
			vim.notify(string.format("Path '%s' is valid.", fp))
		else
			vim.notify(string.format("%s not found at %s.", key, fp), vim.log.levels.WARN)
		end
	end
end

return commands
