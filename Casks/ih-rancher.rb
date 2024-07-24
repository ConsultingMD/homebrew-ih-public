cask "ih-rancher" do
    version "1.14.2"

    if Hardware::CPU.intel?
        url "https://github.com/rancher-sandbox/rancher-desktop/releases/download/v#{version}/Rancher.Desktop-#{version}.x86_64.dmg"
        sha256 "e764e335d1475f8bceb3fb6d1d1892b09d3c2bee3f34355ddab8a7e157c87452"
    else
        url "https://github.com/rancher-sandbox/rancher-desktop/releases/download/v#{version}/Rancher.Desktop-#{version}.aarch64.dmg"
        sha256 "fccf84337e0a894cda047ea1c5796e4de843a9f992665d28a9451e1097061bfc"
    end

    name "Rancher Desktop"
    desc "Alternative to Docker Desktop"
    homepage "https://rancherdesktop.io/"

    app	"Rancher Desktop.app"
end
