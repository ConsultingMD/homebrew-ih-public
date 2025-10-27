cask "ih-rancher" do
    version "1.20.0"

    # To update these values,
    # Go to the release page in GitHub
    # and copy the download URL and SHA256 hash
    # for the appropriate architecture.
    if Hardware::CPU.intel?
        url "https://github.com/rancher-sandbox/rancher-desktop/releases/download/v#{version}/Rancher.Desktop-#{version}.x86_64.dmg"
        sha256 "380cb77bcdcb7723817abe387fd32c4f81998c3070455c98b43619626640b290"
    else
        url "https://github.com/rancher-sandbox/rancher-desktop/releases/download/v#{version}/Rancher.Desktop-#{version}.aarch64.dmg"
        sha256 "ee0073896ffc149c3db12a21004981edbaa2f194341d9680375dc2df809fcfc2"
    end

    name "Rancher Desktop"
    desc "Alternative to Docker Desktop"
    homepage "https://rancherdesktop.io/"

    app	"Rancher Desktop.app"
end
