# Documentation: https://docs.brew.sh/Formula-Cookbook
#                https://rubydoc.brew.sh/Formula
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!
class IhCore < Formula
  desc "Brew formula for installing core tools used at Included Health engineering."
  homepage "https://github.com/ConsultingMD/homebrew-ih-public"
  license "CC BY-NC-ND 4.0"
  
  head "https://github.com/ConsultingMD/homebrew-ih-public", :using => :git

  depends_on "asdf"
  depends_on "awscli"
  depends_on "nano"
  #depends_on "gh"
  #depends_on "git"
  #depends_on "gnu-getopt"
  #depends_on "jq"
  #depends_on "virtualenv"
  #depends_on "go-jira"

  def install
    prefix.install Dir["ih-core/lib"] => "lib"
    bin.install "ih-core/bin/ih"
    system "cp", "-r", "ih.d", "$HOME"
  end

  def caveat

    "this was installed"

  end

  test do
    # `test do` will create, run in and delete a temporary directory.
    #
    # This test will fail and we won't accept that! For Homebrew/homebrew-core
    # this will need to be a test that verifies the functionality of the
    # software. Run the test with `brew test ih-core`. Options passed
    # to `brew install` such as `--HEAD` also need to be provided to `brew test`.
    #
    # The installed folder is not in the path, so use the entire path to any
    # executables being tested: `system "#{bin}/program", "do", "something"`.
    system "true"
  end
end
