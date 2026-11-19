cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.215.18"
  sha256 arm:          "2a9893a3dd173cf8aee720813a22ae747e28b566aea1c90ca1d3f8c25cd25020",
         arm64_linux:  "140493ba2153dc67b15d53aaaed5ffb2fe8b7aa9b7e8f6f9a3922940679d5bce",
         x86_64_linux: "3a5635e681858010058d312513def8db3e61ea236a9a6e8986c60f2c7d2aa58b"

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
