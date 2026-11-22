cask "ksail-desktop" do
  version "7.215.45"

  on_macos do
    sha256 "5629f0d17b0b901afd06b9b7b79e5f9286a0cbecefeb5c1fbcb6b767af1d1008"

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
