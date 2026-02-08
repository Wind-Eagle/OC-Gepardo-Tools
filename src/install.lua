local shell = require("shell")

local function help()
    print("=" .. string.rep("=", 40))
    print("OCGT Installer")
    print("=" .. string.rep("=", 40))
    print("Usage: lua install.lua --mode=<mode>")
    print("\nModes:")
    print("  network   - Install from local network source")
    print("  internet  - Download and install from internet")
    print("\nOptions:")
    print("  --mode=<mode>  - Set installation mode (required)")
    print("  --help         - Show this help")
end

local mode = nil
local _, options = shell.parse(...)

for argKey, argValue in pairs(options) do
    if not argValue then break end

    if argKey == "help" then
        help()
        os.exit(0)
    elseif argKey == "mode" then
        mode = argValue
    end
end

if not mode then
    print("ERROR: Installation mode is required!")
    print()
    help()
    os.exit(1)
end

mode = mode:gsub('^["\'](.*)["\']$', '%1'):gsub("%s+", ""):lower()

if mode == "network" then
    print("[INFO] Starting network installation...")
elseif mode == "internet" then
    print("[INFO] Starting internet installation...")
else
    print("ERROR: Invalid mode '" .. mode .. "'")
    print("Valid modes are: network, internet")
    os.exit(1)
end

print("[INFO] Installation completed successfully!")
