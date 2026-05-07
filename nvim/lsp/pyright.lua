return {
    cmd = { "pyright-langserver", "--stdio" },
    filetypes = { "python" },
    root_markers = { "pyproject.toml", ".git" },
    settings = {
        python = {
            pythonPath = '.venv/bin/python',
            analysis = {
                typeCheckingMode = "basic",
            },
        },
    },
}
