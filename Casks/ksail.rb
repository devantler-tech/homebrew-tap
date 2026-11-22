cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.215.46"
  sha256 arm:          "a2a7ad54d66a6c7dd1cba65050d82b1710f29894a6724afbe748018a43005caf",
         arm64_linux:  "ee842c9fe23f503c0d2c692c934ef24a3daf5bd9d2b8a8a27b4a28f5ee648bc4",
         x86_64_linux: "d75f3031173d9a6db5ad1839dfe62818daf297c2e4c985212b31b06fa23d5e09"

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
