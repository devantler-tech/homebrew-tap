cask "ksail-desktop" do
  version "7.216.1"

  on_macos do
    sha256 "9253ba1a02b03b486d01dfaabb150e01483a2d647d3e8a420fa5387ac682c376"

    url "https://github.com/devantler-tech/ksail/releases/download/v#{version}/KSail_#{version}_darwin_arm64.zip"

    depends_on arch: :arm64
  end

  name "ksail-desktop"
  desc "Native desktop app to manage local Kubernetes clusters"
  homepage "https://ksail.devantler.tech/"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on :macos

  app "KSail.app"
  binary "#{appdir}/KSail.app/Contents/MacOS/ksail-desktop"

  postflight_steps do
    on_macos do
      run "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", "{{appdir}}/KSail.app"]
    end
  end

  uninstall quit: "tech.devantler.ksail.desktop"

  zap :not_required
end
