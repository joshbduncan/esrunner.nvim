local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local expect, eq = MiniTest.expect, MiniTest.expect.equality

local esrunner = require("esrunner")
local utils = require("esrunner.utils")

-- setup child process and custom hooks
local child = MiniTest.new_child_neovim()
local custom_hooks = {
	-- This will be executed before every (even nested) case
	pre_case = function()
		-- Restart child process with custom 'init.lua' script
		child.restart({ "-u", "scripts/minimal_init.lua" })
		-- Load tested plugin
		child.lua([[M = require("esrunner")]])
		child.lua([[M.utils = require("esrunner.utils")]])
	end,
	-- This will be executed one after all tests from this set are finished
	post_once = child.stop,
}

local T = new_set()

T["sanity"] = function()
	eq(1 + 1, 2)
end

T["version check"] = new_set({
	hooks = custom_hooks,
}, {
	test = function()
		local result = child.lua_get("M.version")
		eq(result, esrunner["version"])
	end,
})

T["validate saved buffer"] = new_set({
	hooks = custom_hooks,
}, {
	test = function()
		expect.error(function()
			child.cmd("ESRunner run")
			error("cat")
		end)
	end,
})

T["validate file type"] = new_set({
	hooks = custom_hooks,
	parametrize = { { "javascript", true }, { "python", false }, { "javascriptreact", true } },
}, {
	test = function(ft, expected)
		child.cmd(string.format("set filetype=%s", ft))
		local result = child.lua_get("M.utils.valid_filetype()")
		eq(result, expected)
	end,
})

T["check for target in buffer"] = new_set({
	hooks = custom_hooks,
	parametrize = { { 1, 7, 1 }, { 2, 7, 4 } },
}, {
	test = function(start, end_, expected)
		local lines = {
			"//@target illustrator-29.1.0",
			"alert('poop');",
			"//hey",
			"//@target photoshop",
			"alert('dogs > cats');",
			"",
			"alert('donkey');",
		}
		child.api.nvim_buf_set_lines(0, 0, -1, true, lines)
		local match_line = child.lua_get(string.format("M.utils.check_for_target(%s, %s)", start, end_))
		eq(match_line, expected)
	end,
})

T["validate target specifier"] = new_set({
	parametrize = {
		{ "photoshop", true },
		{ "chicken", false },
		{ "illustrator", true },
		{ "newt", false },
	},
}, {
	test = function(target_specifier, expected)
		eq(utils.validate_target_specifier(target_specifier), expected)
	end,
})

T["parse target specifiers"] = new_set({
	parametrize = {
		{ "photoshop", { "photoshop", nil, nil, nil } },
		{ "bridge-3.0", { "bridge", nil, "3.0", nil } },
		{ "indesign_1-6.0", { "indesign", "1", "6.0", nil } },
		{ "illustrator-14.0", { "illustrator", nil, "14.0", nil } },
		{ "illustrator-14.0-de_de", { "illustrator", nil, "14.0", "de_de" } },
	},
}, {
	test = function(target_specifier, expected)
		local a, i, v, l = utils.parse_target_specifier(target_specifier)
		eq({ a, i, v, l }, expected)
	end,
})

T["generate system apps table"] = new_set({}, {
	test = function()
		local apps = {
			{ "Example App 1", "/path/to/example 1.app", "1.2.3" },
			{ "Example App 2", "/diff/path/to/example 2.app", "4.5.6" },
		}
		local expected = {
			["Example App 1"] = {
				path = "/path/to/example 1.app",
				version = "1.2.3",
			},
			["Example App 2"] = {
				path = "/diff/path/to/example 2.app",
				version = "4.5.6",
			},
		}
		eq(utils.generate_system_apps_table(apps), expected)
	end,
})

return T
