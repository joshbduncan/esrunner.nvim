.DEFAULT_GOAL := help
.PHONY: help test test_file format lint

##@ General
help: ## Display this help section
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Testing
test: deps/mini.nvim ## Run all test files
	nvim --headless --noplugin -u ./scripts/minimal_init.lua -c "lua MiniTest.run()"

test_file: deps/mini.nvim ## Run a single test file (usage: make test_file FILE=path/to/file)
	nvim --headless --noplugin -u ./scripts/minimal_init.lua -c "lua MiniTest.run_file('$(FILE)')"

##@ Code Quality
format: ## Format Lua files with StyLua
	stylua lua/ plugin/

lint: ## Check Lua formatting with StyLua without applying changes
	stylua --check lua/ plugin/

##@ Dependencies
deps/mini.nvim: ## Download mini.nvim for use with mini.test
	@mkdir -p deps
	git clone --filter=blob:none https://github.com/echasnovski/mini.nvim $@
