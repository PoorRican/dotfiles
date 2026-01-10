local util = require("lspconfig.util")

return function(on_attach)
    return {
        on_attach = on_attach,
        root_dir = util.root_pattern("uv.lock", "pyproject.toml", ".git"),
    }
end
