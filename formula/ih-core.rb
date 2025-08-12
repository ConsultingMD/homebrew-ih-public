class IhCore < Formula
  VERSION="0.1.83"
  desc "Brew formula for installing core tools used at Included Health engineering."
  homepage "https://github.com/ConsultingMD/homebrew-ih-public"
  license "CC BY-NC-ND 4.0"
  url "https://github.com/ConsultingMD/homebrew-ih-public/archive/refs/tags/#{VERSION}.tar.gz"
  head "https://github.com/ConsultingMD/homebrew-ih-public", :using => :git

  depends_on "python@3.9"
  depends_on "awscli"
  depends_on "nano"
  depends_on "gh"
  depends_on "git"
  depends_on "gnu-getopt"
  depends_on "jq"
  depends_on "yq"
  depends_on "go-jira"
  depends_on "openssl@3"
  depends_on "coreutils"
  depends_on "yamllint"
  depends_on "wget"
  depends_on "rancher-cli"
  depends_on "ripgrep"
  # Ensure Homebrew zlib is available so python-build (pyenv) can build CPython on
  # macOS Command Line Tools–only hosts. See: https://github.com/pyenv/pyenv/issues/3300
  depends_on "zlib"

  def install
    lib.install Dir["lib/*"]
    bin.install Dir["bin/*"]
    (prefix/"VERSION").write VERSION
  end

  def caveat

    "Run `ih-setup install` to install IH components"

  end

  test do
    system "#{bin}/ih-setup help"
  end
end
