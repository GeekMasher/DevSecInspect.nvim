<div align="center">
<h1>DevSecInspect.nvim</h1>

[![GitHub](https://img.shields.io/badge/github-%23121011.svg?style=for-the-badge&logo=github&logoColor=white)](https://github.com/GeekMasher/DevSecInspect.nvim)
[![GitHub Issues](https://img.shields.io/github/issues/geekmasher/DevSecInspect.nvim?style=for-the-badge)](https://github.com/GeekMasher/DevSecInspect.nvim/issues)
[![GitHub Stars](https://img.shields.io/github/stars/geekmasher/DevSecInspect.nvim?style=for-the-badge)](https://github.com/GeekMasher/DevSecInspect.nvim)
[![Licence](https://img.shields.io/github/license/Ileriayo/markdown-badges?style=for-the-badge)](./LICENSE)

</div>

## Overview

[DevSecInspect](https://github.com/GeekMasher/DevSecInspect.nvim) is a [Neovim](https://neovim.io/) plugin focusing on putting security results in the hands of Developers.

## Installing

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

## Support

Please create issues for any feature requests, bugs, or documentation problems.

## Acknowledgement

- @GeekMasher - Author and Maintainer

## Licence

This project is licensed under the terms of the MIT open source license.
Please refer to [MIT](./LICENSE.md) for the full terms.
