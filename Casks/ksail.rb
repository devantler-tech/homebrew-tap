cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.215.41"
  sha256 arm:          "1825e6cc807d17fc00d671bd9dbd31e0ca7093c0011f947dc832a184c94e6ece",
         arm64_linux:  "aecb571a9d3bc0876d3f5ad1bdc6f69ae21be3c8f86569e03bce340c7f2053f3",
         x86_64_linux: "12542ceab3232d93d6f77f5ca3c83ca969efb33a0637ba88f27dc970a574e5e8"

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
