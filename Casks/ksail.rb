cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.215.4"
  sha256 arm:          "71942a26575eb4265e8c18cb276d310b5842da81c6f92afd2ec0741a4b256ff8",
         arm64_linux:  "0143f9b6c3584607aaf84d5f5088a45f7d682ad3700de0d5e9b000a9543558bb",
         x86_64_linux: "3a7d85d3c9e9c1f276d882c9bd0d3ffc285e86d73551d78a72a6eb54a8fce92e"

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
