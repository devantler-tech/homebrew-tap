cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.216.28"
  sha256 arm:          "50f2d4fadc80224b690611f8cb02bae3ce3901cf36e38ed5dbf4cb19c33523b0",
         arm64_linux:  "52dee7e7ad9b5066e8a4aa23e3c5b2428170f3176152976f6d8b9cdb3cac83af",
         x86_64_linux: "7bcdf9224c4ec5a991c887f2b3f654890672e95eef43c1c945389d212420ae4d"

  on_macos do
    depends_on arch: :arm64
  end

  url "https://github.com/devantler-tech/ksail/releases/download/v#{version}/ksail_#{version}_#{os}_#{arch}.tar.gz"
  name "ksail"
  desc "CLI tool to manage Kubernetes clusters and workloads"
  homepage "https://ksail.devantler.tech/"

  livecheck do
    url :url
    strategy :github_latest
  end

  binary "ksail"
  bash_completion "completions/ksail.bash"
  zsh_completion "completions/ksail.zsh"
  fish_completion "completions/ksail.fish"

  postflight_steps do
    on_macos do
      run "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", "{{staged_path}}/ksail"]
    end
  end

  zap :not_required
end
