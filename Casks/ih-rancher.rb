cask "ih-rancher" do
    version "1.19.0"

    if Hardware::CPU.intel?
        url "https://github.com/rancher-sandbox/rancher-desktop/releases/download/v#{version}/Rancher.Desktop-#{version}.x86_64.dmg"
        sha256 "d0a0f06556c69bce86c10e7cc0fcc88f02c9a9fa0241ea16325d0995a03425bd"
    else
        url "https://github.com/rancher-sandbox/rancher-desktop/releases/download/v#{version}/Rancher.Desktop-#{version}.aarch64.dmg"
        sha256 "1b5c90261bcba90afb5d1372e78f1f68487b888b5a847623ab5177eb16acf112"
    end

    name "Rancher Desktop"
    desc "Alternative to Docker Desktop"
    homepage "https://rancherdesktop.io/"

    app	"Rancher Desktop.app"
end
