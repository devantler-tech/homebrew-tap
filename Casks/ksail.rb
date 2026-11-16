cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.215.3"
  sha256 arm:          "b18c7cab79603f6fd00618f2a2919e429496bb032925973a8f974774d2d00e40",
         arm64_linux:  "978bdc6a83c8c6e5e3b400713c1dcdf2617f34a4f4e9b1a0ad5fafedca1f21bd",
         x86_64_linux: "e2dc600d7eb5a60f420862e0c53bd62b4f927d51ebccbafa4c6f8614d4b62f8e"

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
