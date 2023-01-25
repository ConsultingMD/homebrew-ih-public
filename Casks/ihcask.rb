cask "ihcask" do
    version "1.7.0"
    sha256 "41feea152b3dcff8fb729106b195e4dc7632cda669ef7054045f72c595825242"
      
    url "https://github.com/rancher-sandbox/rancher-desktop/releases/download/v#{version}/Rancher.Desktop-#{version}.aarch64.dmg"
    name "Rancher Desktop"
    desc "Alternative to Docker Desktop"
    homepage "https://rancherdesktop.io/"

    app	"Rancher Desktop.app"
end