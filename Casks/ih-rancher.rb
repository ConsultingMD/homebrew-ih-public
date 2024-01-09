cask "ih-rancher" do
    version "1.12.0"

    if Hardware::CPU.intel?
        url "https://github.com/rancher-sandbox/rancher-desktop/releases/download/v#{version}/Rancher.Desktop-#{version}.x86_64.dmg"
        sha256 "58388cf60514ca05fdc58bd5c8e2467f9fe5a3dec7371a31c1daeb22e4aeea17"
    else
        url "https://github.com/rancher-sandbox/rancher-desktop/releases/download/v#{version}/Rancher.Desktop-#{version}.aarch64.dmg"
        sha256 "68464fd4520a09ba10ada6fc49bc20eeaee24e30931f52530be399cbec85e3b6"
    end

    name "Rancher Desktop"
    desc "Alternative to Docker Desktop"
    homepage "https://rancherdesktop.io/"

    app	"Rancher Desktop.app"
end
