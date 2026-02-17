cask "ih-mcp-router" do
    version "0.6.2"

    url "https://github.com/mcp-router/mcp-router/releases/download/v#{version}/MCP-Router.dmg"
    sha256 :no_check

    name "MCP Router"
    desc "Unified MCP Server Management App"
    homepage "https://mcp-router.net/"

    app "MCP Router.app"
end
