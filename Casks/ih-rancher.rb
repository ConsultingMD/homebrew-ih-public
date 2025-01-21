cask "ih-rancher" do
    version "1.16.0"

    if Hardware::CPU.intel?
        url "https://github.com/rancher-sandbox/rancher-desktop/releases/download/v#{version}/Rancher.Desktop-#{version}.x86_64.dmg"
        sha256 "c63599d038ffd292e5d49c0f41ed520c0ef1a86dec66a1735d47e9aa9e533b20"
    else
        url "https://github.com/rancher-sandbox/rancher-desktop/releases/download/v#{version}/Rancher.Desktop-#{version}.aarch64.dmg"
        sha256 "9b1d56a5d606751edba48022a454f891e792f7aa36c38e681271b2104f59f7f4"
    end

    name "Rancher Desktop"
    desc "Alternative to Docker Desktop"
    homepage "https://rancherdesktop.io/"

    app	"Rancher Desktop.app"
end
