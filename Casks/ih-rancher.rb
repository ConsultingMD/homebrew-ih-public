cask "ih-rancher" do
    version "1.13.1"

    if Hardware::CPU.intel?
        url "https://github.com/rancher-sandbox/rancher-desktop/releases/download/v#{version}/Rancher.Desktop-#{version}.x86_64.dmg"
        sha256 "75a5532f5d2332f07a556c75455367c26954471de5d4ba436f9ab4aa3b309ac2"
    else
        url "https://github.com/rancher-sandbox/rancher-desktop/releases/download/v#{version}/Rancher.Desktop-#{version}.aarch64.dmg"
        sha256 "7334e2246c8e0d015733697f9bc9abae18973296671595f6b9e039870d327388"
    end

    name "Rancher Desktop"
    desc "Alternative to Docker Desktop"
    homepage "https://rancherdesktop.io/"

    app	"Rancher Desktop.app"
end
