cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.216.22"
  sha256 arm:          "bd2191b5623a97dc0f2271eacf819653fe7c2762d2b5db19e68db998c3605c46",
         arm64_linux:  "fb26dd825f8faec8e25491cea603ffad23ab7142829e6736082568cab49f96a5",
         x86_64_linux: "5506cfae7883abadd0c1f02c2959f1a5e8f7b5e6e979ca7753cf800d10bcaeb7"

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
