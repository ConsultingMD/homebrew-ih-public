# Documentation: https://docs.brew.sh/Formula-Cookbook
#                https://rubydoc.brew.sh/Formula
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!
class IhCore < Formula
  desc "Brew formula for installing core tools used at Included Health engineering."
  homepage "https://github.com/ConsultingMD/homebrew-ih-public"
  license "CC BY-NC-ND 4.0"
  url "https://github.com/ConsultingMD/homebrew-ih-public/archive/refs/tags/0.0.1.tar.gz"
  head "https://github.com/ConsultingMD/homebrew-ih-public", :using => :git

  depends_on "asdf"
  depends_on "awscli"
  depends_on "nano"
  depends_on "gh"
  depends_on "git"
  depends_on "gnu-getopt"
  depends_on "jq"
  depends_on "go-jira"
  #depends_on "virtualenv"

  def install
    prefix.install Dir["ih-core/lib"] => "lib"
    bin.install "ih-core/bin/ih-setup"
  end

  def caveat

    "Run `ih-setup install` to install IH compontents"

  end

  test do
    system "#{bin}/ih-setup help"
  end
end
