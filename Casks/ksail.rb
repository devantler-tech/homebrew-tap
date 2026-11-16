cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.215.7"
  sha256 arm:          "3175fd2d18d746ebde1256be58057221a95030d9fef0eb403b4ee8b71f115c20",
         arm64_linux:  "2dfb06f7e2c597312a98dc6cc92e54d86a2d04f6f5f584837d7ca1c4436a0b9c",
         x86_64_linux: "0ba3505e73d4ff3bc534d36d11c30bdb3768f17f6166afcf5cc2fa122449b104"

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
