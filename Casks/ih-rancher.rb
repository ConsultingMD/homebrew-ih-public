cask "ih-rancher" do
    version "1.18.0"

    if Hardware::CPU.intel?
        url "https://github.com/rancher-sandbox/rancher-desktop/releases/download/v#{version}/Rancher.Desktop-#{version}.x86_64.dmg"
        sha256 "7be0128f73e994881eb908990255eb9b5e1f266ff8c3ab0c85efba745152a32b"
    else
        url "https://github.com/rancher-sandbox/rancher-desktop/releases/download/v#{version}/Rancher.Desktop-#{version}.aarch64.dmg"
        sha256 "dd4d615418a55165ba58987295fb0f79998cda3bc722ee93274ea082c61abd26"
    end

    name "Rancher Desktop"
    desc "Alternative to Docker Desktop"
    homepage "https://rancherdesktop.io/"

    app	"Rancher Desktop.app"
end
