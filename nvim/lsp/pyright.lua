return {
    cmd = { "pyright-langserver", "--stdio" },
    filetypes = { "python" },
    settings = {
        python = {
            pythonPath = '.venv/bin/python',
            analysis = {
                typeCheckingMode = "basic",
            },
        },
    },
}
