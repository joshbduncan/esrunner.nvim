local utils = {}

---Save `lines` to a temporary file.
---@param lines table Lines to save
---@return string # Path of temporary file
utils.save_temp_file = function(lines)
	-- make a new scratch buffer and set it contents
	local bufnr = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

	-- write the buffer to a temporary file
	local fp = string.format("/tmp/jsx_runner_%s.jsx", os.time())
	vim.api.nvim_buf_call(bufnr, function()
		vim.api.nvim_command(string.format("write! %s", fp))
	end)

	return fp
end

---Validate current buffer filetype for ExtendScript.
---@return boolean
utils.valid_filetype = function()
	return vim.bo.filetype == "javascriptreact" or vim.bo.filetype == "javascript"
end

---Check for a target application specifier in the current buffer lines.
---
---Details: https://extendscript.docsforadobe.dev/extendscript-tools-features/preprocessor-directives.html?highlight=target#target-name
---Application Specifier Details: https://extendscript.docsforadobe.dev/interapplication-communication/application-and-namespace-specifiers.html#application-specifiers
---@param start number First line index
---@param end_ number Last line index (exclusive)
---@return number # Line number of target application specifier (or -1 if none found)
utils.check_for_target = function(start, end_)
	-- setup the regex pattern
	local pattern = "\\(\\/\\/@\\|#\\)target"
	local flags = "nc" -- 'n' prevents the cursor from moving

	-- save the current cursor position
	local current_pos = vim.api.nvim_win_get_cursor(0) -- (line, column)

	-- move cursor to the start line, first column
	vim.api.nvim_win_set_cursor(0, { start, 0 })

	-- check for a match between the specified lines
	local match_line = vim.fn.search(pattern, flags)

	-- if no match between the specified lines,
	if match_line == 0 or match_line > end_ then
		-- then move cursor to the first line, first column,
		vim.api.nvim_win_set_cursor(0, { 1, 0 })

		-- and check for a match anywhere in the buffer
		match_line = vim.fn.search(pattern, flags)
	end

	-- restore the cursor to its original position
	vim.api.nvim_win_set_cursor(0, current_pos)

	-- return the line number of the first match (0 if no match)
	return match_line
end

---Validate a target specifier.
---@param target_specifier string ExtendScript target app specifier to validate
---@return boolean
function utils.validate_target_specifier(target_specifier)
	local targets = require("esrunner.config").targets
	return rawget(targets, target_specifier) ~= nil
end

---Parse ExtendScript target app specifier
---@param target_specifier string Target specifier to parse
---@return string|nil # Applicaiton appname
---@return string|nil # Application instance
---@return string|nil # Application version
---@return string|nil # Adobe locale code
function utils.parse_target_specifier(target_specifier)
	local appname, version, locale = unpack(vim.split(target_specifier, "-"))
	local instance = nil

	-- check for an app instance identifier
	if string.find(appname, "_") ~= nil then
		appname, instance = unpack(vim.split(appname, "_"))
	end

	return appname, instance, version, locale
end

---Find all valid app paths that match an app target identifier.
---@param appname string Target app specifier to match with
---@param version string|nil Target app version specifier
---@return table # Matching apps
function utils.match_target_specifier_to_app(appname, version)
	local compare_versions = function(v1, v2)
		-- split the version strings into components
		local function split_version(v)
			return vim.split(v, "%.")
		end

		-- convert version strings into numeric arrays
		local v1_parts = split_version(v1)
		local v2_parts = split_version(v2)

		-- compare each part
		for i = 1, math.max(#v1_parts, #v2_parts) do
			local v1_part = tonumber(v1_parts[i] or "0") -- Default to 0 if missing
			local v2_part = tonumber(v2_parts[i] or "0") -- Default to 0 if missing

			if v1_part > v2_part then
				return 1 -- v1 is greater
			elseif v1_part < v2_part then
				return -1 -- v2 is greater
			end
		end

		return 0 -- versions are equal
	end

	local apps = require("esrunner.config").apps
	local name = require("esrunner.config").targets[appname].app

	local matches = {}
	for key, value in pairs(apps) do
		if string.find(string.lower(key), string.lower(name)) ~= nil then
			if version ~= nil then
				local version_comp = compare_versions(version, value.version)
				if version_comp == 0 then
					matches = { key }
					break
				elseif version_comp == -1 then
					table.insert(matches, key)
				end
			else
				table.insert(matches, key)
			end
		end
	end
	return matches
end

---Pick target app for script execution.
---@param apps table App choices to pick from
---@param fp string File path of script to execute in selected app
utils.pick_app = function(apps, fp)
	if vim.tbl_isempty(apps) then
		vim.notify("No valid apps found.", vim.log.levels.ERROR)
		return
	end

	if #apps == 1 and require("esrunner.config").options.execute_on_single_matches then
		utils.execute_in_target_app(apps[1], fp)
		return
	end

	local apps_info = require("esrunner.config").apps

	vim.ui.select(apps, {
		prompt = "Execute Script Where?",
		format_item = function(item)
			return string.format("%s (v%s)", item, apps_info[item]["version"])
		end,
	}, function(choice)
		if choice == nil then
			return
		end
		utils.execute_in_target_app(choice, fp)
	end)
end

---Execute the script with the target application.
---@param target string File path of app to execute the script with
---@param script string File path of script to execute
utils.execute_in_target_app = function(target, script)
	local apps = require("esrunner.config").apps
	local targets = require("esrunner.config").targets
	local cmd = nil
	for _, value in pairs(targets) do
		if string.find(target, value.app) ~= nil then
			cmd = value.cmd(apps[target]["path"], script)
			break
		end
	end

	if cmd == nil then
		error(string.format("Target '%s' not found.", target), vim.log.levels.ERROR)
	end

	-- execute the script with a system command
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
		error(error_result, vim.log.levels.ERROR)
	end
end

---Validate `fp` exists as a directory on the system and ends in '.app'
---@param fp string File path to validate
---@return boolean
utils.validate_app_directory = function(fp)
	local app_ending = ".app"
	return vim.fn.isdirectory(vim.fn.expand(fp)) == 1 and string.sub(fp, -#app_ending) == app_ending
end

---Generate a sample table of supported apps found on the system
---@param apps table Supported applications found on the system { name, path, version }
---@return table # System apps table
utils.generate_system_apps_table = function(apps)
	table.sort(apps, function(a, b)
		return a[1] < b[1]
	end)
	local d = {}
	for _, app in ipairs(apps) do
		local sub_d = {}
		local name, path, version = unpack(app)
		sub_d["path"] = path
		sub_d["version"] = version
		d[name] = sub_d
	end
	return d
end

return utils
