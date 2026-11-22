cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.215.44"
  sha256 arm:          "73a7ca430b0d958d0e0bab635049a4e9df64187627e1c7d64fff733403c4df47",
         arm64_linux:  "2f68b509a8e7aabb17108c4be3565feb8c44828d556bcb2f863b5ca5464bac04",
         x86_64_linux: "3034045c8f761b707f376ca48e3bf66bffe106ecad9afd12af7c659b62a75a34"

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
