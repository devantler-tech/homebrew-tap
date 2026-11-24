cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.216.15"
  sha256 arm:          "9f0bf4f80b775bc26cee1bfd8868802975dcc7a87357ff21e45fe3c39c115ea0",
         arm64_linux:  "fd56ac1c4a4b42e90dbecf23a879ff0503430ca31ffc843d60c4329802c2add3",
         x86_64_linux: "550e5eb04fed552d6b0cc11d5fae4d2cfa05256397fd97c9e93dfc282b30a2db"

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
