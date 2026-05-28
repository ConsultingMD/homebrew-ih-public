cask "claude-code@latest" do
  arch arm: "arm64", intel: "x64"

  version "2.1.153"
  sha256 arm:    "f2f2f09273971c634cd4c90b96882ae0a2bafa026e4f501fb37b6c2794d4594d",
         x86_64: "368e3ec7ee2554e2205f9f3c57e698b259af8c526a8abb675c34bd1a9c1079fb"

  url "https://github.com/anthropics/claude-code/releases/download/v#{version}/claude-darwin-#{arch}.tar.gz"
  name "Claude Code"
  desc "Terminal-based AI coding assistant (GitHub release mirror — VPN-safe)"
  homepage "https://claude.com/product/claude-code"

  livecheck do
    url "https://github.com/anthropics/claude-code/releases/latest"
    strategy :github_latest
  end

  binary "claude"

  zap trash: [
        "~/.cache/claude",
        "~/.claude.json*",
        "~/.config/claude",
        "~/.local/bin/claude",
        "~/.local/share/claude",
        "~/.local/state/claude",
        "~/Library/Caches/claude-cli-nodejs",
      ],
      rmdir: "~/.claude"
end
