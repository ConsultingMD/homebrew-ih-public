cask "claude-code" do
  arch arm: "arm64", intel: "x64"

  version "2.1.145"
  sha256 arm:    "a385eb18d127b55cf2b1846d0a1771db335d9fdb1f6d1181f79343f61c95ba91",
         x86_64: "4ad91d8572e242d860308319930f04f1110c6301670eef4ba896f02b9759e177"

  url "https://github.com/anthropics/claude-code/releases/download/v#{version}/claude-darwin-#{arch}.tar.gz"
  name "Claude Code"
  desc "Terminal-based AI coding assistant (GitHub release mirror — VPN-safe)"
  homepage "https://claude.com/product/claude-code"

  livecheck do
    url "https://github.com/anthropics/claude-code/releases"
    strategy :github_latest
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  conflicts_with cask: "claude-code@latest"

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
