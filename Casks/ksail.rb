cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.215.17"
  sha256 arm:          "191a731cb8008bf35dd4fb8a22dddd80487d041357d30c887f758fcd0aff5c7d",
         arm64_linux:  "5ad0803ebb7ea9baed97ef6400ae0dd8f542530657f4e6b784f872ad24d6e334",
         x86_64_linux: "cf6394be46352db643864ade28d8e493323fac643b9b50e3339534d9a39d9a32"

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
