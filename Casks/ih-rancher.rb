cask "ih-rancher" do
    version "1.12.2"

    if Hardware::CPU.intel?
        url "https://github.com/rancher-sandbox/rancher-desktop/releases/download/v#{version}/Rancher.Desktop-#{version}.x86_64.dmg"
        sha256 "299034631ee0faa747f55b2ca7d6682419a15563a706ef8a2415e8638108fd35"
    else
        url "https://github.com/rancher-sandbox/rancher-desktop/releases/download/v#{version}/Rancher.Desktop-#{version}.aarch64.dmg"
        sha256 "9ab8131239a34ff880b79617f71254a502fb30a3dd7908b13533b84e9698a499"
    end

    name "Rancher Desktop"
    desc "Alternative to Docker Desktop"
    homepage "https://rancherdesktop.io/"

    app	"Rancher Desktop.app"
end
