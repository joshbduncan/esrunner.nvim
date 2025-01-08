# esrunner.nvim

A plugin for running ExtendScript scripts for Adobe applications from within Neovim on your Mac 👨‍💻.

## Setup

Any Adobe app you wish to execute scripts with needs to be loaded into the plugin setup as a Lua table. Each entry in the table should be a valid system path to the app '.app' package.

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

> [!TIP]
> You can specify different versions of the same application.

## Usage

Run the command `:ESRunner` (or `:ESRunner run`) to execute the script in the current buffer.

## Adobe Application Paths

Most often, Adobe apps are installed into either the base Application directory `/Application/...` or your user Application directory `~/Applications/...`.

To ensure the Adobe application paths you provided to the plugin setup are correct, run the command `ESRunner validate_apps`.

If you are having trouble and need help determining your installed Adobe application paths, run the command `:ESRunner find_apps` for a report of all paths found on your system.

> [!WARNING]
> Depending on your system, it may take a few moments for ESRunner to find your installed apps.
