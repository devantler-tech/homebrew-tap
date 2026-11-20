cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.215.26"
  sha256 arm:          "7d91c5737fd3762dfdf8d367be6b8acba6fd3742121c59eff0788f676b93791d",
         arm64_linux:  "8bf2c15ece4931332f61db0a8f509aeefa3120b25b0a6489fe0b7332d3e84b5b",
         x86_64_linux: "c6622e76c03f8728051656e53089be6efd000f9608150d0b2b6bc6c1896325e7"

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
