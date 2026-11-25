cask "world-at-ruin" do
  version "0.172.5"
  sha256 "b5d3b939f5450512a9d7ba12f59481ec33cc9464c634b8c890968e0c46749dd7"

  # No verified: parameter here. brew audit --strict rejects it when
  # the download domain matches the homepage domain, which it does
  # here (both github.com). ksail needs it only because its homepage
  # is a separate site.
  url "https://github.com/devantler-tech/world-at-ruin/releases/download/v#{version}/WorldAtRuin-#{version}-macOS-universal.zip"
  name "World at Ruin"
  desc "Cloud-native MMORPG built almost entirely by agents"
  homepage "https://github.com/devantler-tech/world-at-ruin/"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on :macos

  app "World at Ruin.app"

  postflight_steps do
    # The build is AD-HOC signed (Godot's built-in codesign, no
    # Developer ID), so Gatekeeper quarantines it on download and it
    # will not launch without this.
    run "/usr/bin/xattr",
        args: ["-dr", "com.apple.quarantine", "{{appdir}}/World at Ruin.app"]
  end

  uninstall quit: "tech.devantler.worldatruin"

  zap trash: "~/Library/Application Support/Godot/app_userdata/World at Ruin"
end
