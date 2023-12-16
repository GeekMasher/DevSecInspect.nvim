<div align="center">
<h1>DevSecInspect.nvim</h1>

[![GitHub](https://img.shields.io/badge/github-%23121011.svg?style=for-the-badge&logo=github&logoColor=white)](https://github.com/GeekMasher/DevSecInspect.nvim)
[![GitHub Issues](https://img.shields.io/github/issues/geekmasher/DevSecInspect.nvim?style=for-the-badge)](https://github.com/GeekMasher/DevSecInspect.nvim/issues)
[![GitHub Stars](https://img.shields.io/github/stars/geekmasher/DevSecInspect.nvim?style=for-the-badge)](https://github.com/GeekMasher/DevSecInspect.nvim)
[![Licence](https://img.shields.io/github/license/Ileriayo/markdown-badges?style=for-the-badge)](./LICENSE)

</div>

[DevSecInspect][dsirepo] is a [Neovim][neovim] plugin focusing on putting security results in the hands of Developers.

## ✨ Features

- Automatic analyze code or dependencies
- Fully Customizable

## ⚡️ Requirements

- [Neovim][neovim] `>= 0.9.0`

## 📦 Installing

**Lazy:**

```lua
return {
    {
        "GeekMasher/DevSecInspect.nvim",
        dependencies = {
            "MunifTanjim/nui.nvim",
        },
        config = function()
            require("devsecinspect").setup({
                -- Options
            })
        end
    }
}
```

### [Tools][tools]

<!-- GENERATE: tools -->

- [Bandit](https://bandit.readthedocs.io/en/latest/) (sast)
- [Cargo Audit](https://github.com/RustSec/rustsec/tree/main/cargo-audit) (sca)
- [GitHub Advanced Security](https://github.com/features/security) (service)
- [NPM Audit](https://docs.npmjs.com/cli/v10/commands/npm-audit) (sca)
- [Quibble](https://github.com/GeekMasher/quibble) (sast)
- [Semgrep](https://github.com/semgrep/semgrep) (sast)

<!-- GENERATE-END -->

## Configuration

DevSecInspect is highly customizable allowing users to configure the plugin to do what you need.

```lua
require("devsecinspect").setup({
    -- Automatically add Nvim auto commands
    autocmd = true,
    -- List of tools to enable / use
    tools = {},
    -- Enable default tools
    default_tools = true,
    -- Custom tools
    custom_tools = {},
    -- Alerts Display and Panel settings
    alerts = {
        -- Mode to display alerts
        mode = "summarised",   -- "summarised" or "full"
        auto_open = false,     -- automatically open the panel
        auto_close = false,    -- automatically close the panel
        auto_preview = true,   -- automatically preview alerts in the main buffer
        text_position = "eol", -- "eol" / "overlay" / "right_align" / "inline"
        panel = {
            enabled = false,   -- always show the panel
            -- Panel position and size
            position = {
                row = "0%",
                col = "100%"
            },
            size = {
                width = "30%",
                height = "97%",
            },
        },
        -- Alert filters on when to display alerts
        filters = {
            -- Filter out alerts with severity below this level
            severity = "medium",
            -- Filter out alerts with confidence below this level
            confidence = nil
        }
    },
    symbols = {
        -- Icons
        info = " ",
        debug = " ",
        error = " ",
        warning = " ",
        hint = " ",
        -- Statuses
        enabled = "",
        disabled = "",
        running = " "
    },
})
```

[All the configurations can be found here](./lua/devsecinspect/config.lua).

## Support

Please create issues for any feature requests, bugs, or documentation problems.

## Acknowledgement

- @GeekMasher - Author and Maintainer

## Licence

This project is licensed under the terms of the MIT open source license.
Please refer to [MIT](./LICENSE.md) for the full terms.

<!-- resources / references -->

[dsirepo]: https://github.com/GeekMasher/DevSecInspect.nvim
[neovim]: https://neovim.io/
[tools]: ./tools
