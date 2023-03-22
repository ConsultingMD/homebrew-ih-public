cask "ih-rancher" do
    version "1.8.1"

    if Hardware::CPU.intel? 
        url "https://github.com/rancher-sandbox/rancher-desktop/releases/download/v#{version}/Rancher.Desktop-#{version}.x86_64.dmg"
        sha256 "5233a6b7024077bb2102f8c4afde7bed79207ab4d1989d8b2e34e5b353ef3d82"
    else
        url "https://github.com/rancher-sandbox/rancher-desktop/releases/download/v#{version}/Rancher.Desktop-#{version}.aarch64.dmg"
        sha256 "ed88c10760cf5ff03bfcfa68870a90bb839d79dd95a8357def11875fb1ffbd23"
    end
    
    name "Rancher Desktop"
    desc "Alternative to Docker Desktop"
    homepage "https://rancherdesktop.io/"

    app	"Rancher Desktop.app"
end
