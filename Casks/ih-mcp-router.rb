cask "ih-mcp-router" do
    version "0.6.2"

    # To update these values,
    # go to the release page on GitHub and copy the download URL and SHA256 hash
    # for the appropriate architecture.
    if Hardware::CPU.intel?
        url "https://github.com/mcp-router/mcp-router/releases/download/v#{version}/MCP-Router.dmg"
        sha256 "125dcbba4dde6cc573f5e30e2d9cb35f91eee00ea6bba565ce9518b4639580a7"
    else
        url "https://github.com/mcp-router/mcp-router/releases/download/v#{version}/MCP.Router-darwin-arm64-#{version}.zip"
        sha256 "5373dfae8a97197cfa245b41e2f95e35287d7e0aa13a37acffa33d4befa1251f"
    end

    name "MCP Router"
    desc "Unified MCP Server Management App"
    homepage "https://mcp-router.net/"

    app "MCP Router.app"
end
