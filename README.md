# esrunner.nvim

A plugin for running ExtendScript scripts for Adobe applications from within Neovim on your Mac 👨‍💻.

## Supported Applications

- Adobe After Effects
- Adobe Illustrator
- Adobe InDesign
- Adobe Photoshop

## Setup

Any Adobe app you wish to execute scripts with needs to be loaded into the plugin setup as a Lua table. Each entry in the table should be a valid system path to the app `.app` package.

```lua
require('esrunner').setup{
    apps = {
        ["Adobe Illustrator 2025"] = {
            path = "/Applications/Adobe Illustrator 2025/Adobe Illustrator.app",
            version = "29.1.0",
        },
        ["Adobe InDesign 2025"] = {
            path = "/Applications/Adobe InDesign 2025/Adobe InDesign 2025.app",
            version = "20.0.1.32",
        },
        ["Adobe Photoshop 2025"] = {
            path = "/Applications/Adobe Photoshop 2025/Adobe Photoshop 2025.app",
            version = "26.1.0",
        },
    },
}
```

### Options

| Option | Default | Description |
|---|---|---|
| `execute_on_single_matches` | `true` | Auto-execute when only one app matches, skipping the picker |

```lua
require('esrunner').setup{
    apps = { ... },
    defaults = {
        execute_on_single_matches = false, -- always show the picker
    },
}
```

## Usage

Run the command `:ESRunner` (or `:ESRunner run`) to execute the script in the current buffer.

To execute only part of a buffer, select lines in visual mode first, then run `:ESRunner run`.

### Target directive

If your script contains a `#target` or `//@target` preprocessor directive, ESRunner will automatically route execution to the correct application without prompting.

```js
//@target illustrator
alert("hello from Illustrator");
```

The target specifier supports an optional version to select a specific installed version:

```js
//@target illustrator-29.1.0
```

If the version matches an installed app exactly, that app is used. If no exact match is found, all installed versions at or above the specified version are offered.

> [!TIP]
> You can register different versions of the same application in `setup()` and use version specifiers in your scripts to control which one runs.

Valid target identifiers are: `aftereffects`, `illustrator`, `indesign`, `photoshop`.

## Adobe Application Paths

Most often, Adobe apps are installed into either the base Application directory `/Applications/...` or your user Application directory `~/Applications/...`.

To ensure the Adobe application paths you provided to the plugin setup are correct, run the command `:ESRunner validate_apps`.

If you are having trouble and need help determining your installed Adobe application paths, run the command `:ESRunner find_apps` for a report of all supported app paths found on your system, formatted as a ready-to-paste config snippet.

> [!WARNING]
> Depending on your system, it may take a few moments for `:ESRunner find_apps` to finish.

## Documentation

Full documentation is available within Neovim via `:help esrunner`.
