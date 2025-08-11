#!/usr/bin/env zx
import fs from "fs/promises";

try {
    const outputPath = path.resolve(process.cwd(), ".nvim.lua");
    const templateContent = `
require("overseer").register_template({
    name = "sample task",
    builder = function()
        local file = vim.fn.expand("%:p")
        return {
            cmd = { "echo" },
            args = { file },
            components = {
                { "open_output", on_complete = "failure", direction = "vertical" },
                "default",
            },
        }
    end,
})
`;
    await fs.writeFile(outputPath, templateContent);
    console.log(`Successfully created ${outputPath}`);
} catch (error) {
    console.error(`Error: ${error.message}`);
    process.exit(1);
}
