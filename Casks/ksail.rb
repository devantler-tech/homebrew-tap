cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.216.17"
  sha256 arm:          "8d5de95da894eb398b754954ab83c55603854538709b22f32098359a34cc2ac0",
         arm64_linux:  "8412784b809de5e96d8c4bdaba008d00a7c9f02c981a040171a7a2d56b7bbf75",
         x86_64_linux: "f95830be327ebb0f37cf98fa8d387b8d1276cb7ff87be79b8763a2b85f48e3e3"

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
