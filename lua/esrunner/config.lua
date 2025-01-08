local config = {}

-- plugin option defaults
config.defaults = {
	["execute_on_single_matches"] = true,
}

-- table to hold configuration options
config.options = {}

-- table to hold user config app paths
config.apps = {}

config.set_options = function(opts)
	-- set defaults
	local defaults = vim.F.if_nil(config.defaults, {})
	local user_defaults = vim.F.if_nil(opts.defaults, {})

	for key, value in pairs(defaults) do
		if rawget(user_defaults, key) ~= nil then
			value = user_defaults[key]
		end
		config.options[key] = value
	end

	config.apps = opts.apps
end

-- NOTE: tested app targets
config.targets = {}
config.targets["aftereffects"] = {
	app = "After Effects",
	cmd = function(target, script)
		return {
			"osascript",
			"-e",
			string.format('tell application "%s"', target),
			"-e",
			"activate",
			"-e",
			string.format('DoScriptFile "%s"', script),
			"-e",
			"end tell",
			"&",
		}
	end,
}
config.targets["illustrator"] = {
	app = "Illustrator",
	cmd = function(target, script)
		return { "open", "-a", target, script }
	end,
}
config.targets["indesign"] = {
	app = "InDesign",
	cmd = function(target, script)
		return {
			"osascript",
			"-e",
			string.format('tell application "%s"', target),
			"-e",
			"activate",
			"-e",
			string.format('do script "%s" language javascript', script),
			"-e",
			"end tell",
			"&",
		}
	end,
}
config.targets["photoshop"] = {
	app = "Photoshop",
	cmd = function(target, script)
		return { "open", "-a", target, script }
	end,
}

-- config.targets = {}
-- config.targets["After Effects"] = {
-- 	id = "aftereffects",
-- 	cmd = function(target, script)
-- 		return {
-- 			"osascript",
-- 			"-e",
-- 			string.format('tell application "%s"', target),
-- 			"-e",
-- 			"activate",
-- 			"-e",
-- 			string.format('do script "%s" language javascript', script),
-- 			"-e",
-- 			"end tell",
-- 			"&",
-- 		}
-- 	end,
-- }
-- config.targets["Illustrator"] = {
-- 	id = "illustrator",
-- 	cmd = function(target, script)
-- 		return { "open", "-a", target, script }
-- 	end,
-- }
-- config.targets["InDesign"] = {
-- 	id = "indesign",
-- 	cmd = function(target, script)
-- 		return {
-- 			"osascript",
-- 			"-e",
-- 			string.format('tell application "%s"', target),
-- 			"-e",
-- 			"activate",
-- 			"-e",
-- 			string.format('do script "%s" language javascript', script),
-- 			"-e",
-- 			"end tell",
-- 			"&",
-- 		}
-- 	end,
-- }
-- config.targets["Photoshop"] = {
-- 	id = "photoshop",
-- 	cmd = function(target, script)
-- 		return { "open", "-a", target, script }
-- 	end,
-- }

return config
