cask "ih-rancher" do
    version "1.7.0"

    if Hardware::CPU.intel? 
        url "https://github.com/rancher-sandbox/rancher-desktop/releases/download/v#{version}/Rancher.Desktop-#{version}.x86_64.dmg"
        sha256 "828dde44868c3c33fe709e099f9af080143a379f9fba2e3bacd8641f5ad8e72b"
    else
        url "https://github.com/rancher-sandbox/rancher-desktop/releases/download/v#{version}/Rancher.Desktop-#{version}.aarch64.dmg"
        sha256 "41feea152b3dcff8fb729106b195e4dc7632cda669ef7054045f72c595825242"
    end
    
    name "Rancher Desktop"
    desc "Alternative to Docker Desktop"
    homepage "https://rancherdesktop.io/"

    app	"Rancher Desktop.app"
end
