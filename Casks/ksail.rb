cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.216.43"
  sha256 arm:          "45ba285a497d53345fd275fa929d9929873817c93ef7dc2f687afab03d63ba6e",
         arm64_linux:  "a0a97675913df702496b8e1c6e802326f416ac9012e7c28f3da54c4f5db834b2",
         x86_64_linux: "0fd5ef549758c11be96bae78f442fed1e5ce946c94ca6d409e4b62fd1919b2c7"

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
