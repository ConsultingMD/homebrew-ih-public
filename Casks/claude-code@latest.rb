cask "claude-code@latest" do
  arch arm: "arm64", intel: "x64"

  version "2.1.154"
  sha256 arm:    "643ec0cfa324744c15f6bf552d3ce6e934c42651b56f40ea8d4ec4f653a9b49f",
         x86_64: "352e504e405a25e5f2b44ae3758b6dced15371c5411486b2c3add4c3ac4a5000"

  url "https://github.com/anthropics/claude-code/releases/download/v#{version}/claude-darwin-#{arch}.tar.gz"
  name "Claude Code"
  desc "Terminal-based AI coding assistant (GitHub release mirror — VPN-safe)"
  homepage "https://claude.com/product/claude-code"

  livecheck do
    url "https://github.com/anthropics/claude-code/releases/latest"
    strategy :github_latest
  end

  deprecate! date:    "2026-07-01",
             because: "is superseded by the official claude-code@latest cask, now reachable on the IH VPN"

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
