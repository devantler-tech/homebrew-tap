cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.215.14"
  sha256 arm:          "40e29c96149e078c0482a45790c152c480098c5fb47cba92d2caa352b7acd38d",
         arm64_linux:  "c7a8de58084faf6d5a18276b1c6355910ed0776f1262f41ac898a778e1d4dbee",
         x86_64_linux: "24e4ba73cfcfda3954d99329fc5ca6e399b538990bc88e970479b43a3e62ce85"

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
