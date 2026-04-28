# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-04-28

### Added

- Health check support via `:checkhealth esrunner` — validates platform, app
  configuration, and app paths
- Config validation in `setup()` using `vim.validate` — wrong or missing
  `path`/`version` fields now fail immediately with a clear message
- Friendly error when `setup()` is called without `apps` — Neovim continues
  loading so `:ESRunner find_apps` remains usable
- LuaCATS type annotations across all modules for lua-language-server support
- `lint` target in Makefile for CI formatting checks (`stylua --check`)
- Makefile `help` target with grouped, annotated target listing
- Vimdoc `TARGETS` section (`*esrunner.targets*`) listing valid target
  identifiers with usage examples
- Test coverage for config validation and health check module

### Changed

- `:ESRunner find_apps` output is now a ready-to-paste Lua config snippet
  with syntax highlighting, replacing raw `vim.inspect` output
- README updated with supported applications list, target directive
  documentation, options table, visual range usage, and link to `:help esrunner`
- Vimdoc corrected: fixed `execute_on_single_matches` default (`false` → `true`),
  fixed typos, and fixed `/Application/` → `/Applications/`

### Fixed

- `error(msg, vim.log.levels.ERROR)` misuse replaced with `vim.notify` + `return`
  throughout — errors now surface cleanly without a raw `E5108` traceback
- Filetype validation failure incorrectly reported "Buffer has unsaved changes" —
  now reports "Not a valid ExtendScript filetype"
- Removed broken `:help esrunner.targets` reference from error message (tag now
  exists and reference has been restored)
- Dropped unused stdout capture in `execute_in_target_app`
- Removed dead commented-out code in `config.lua`

## [0.1.0] - 2025-01-07

### Added

- Initial release!
