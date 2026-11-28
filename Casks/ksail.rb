cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.216.50"
  sha256 arm:          "8a8ca2c904b5bea73f9440853d4e951e29019e956a00f1b21889d388b38d1099",
         arm64_linux:  "7e0f9db618fd33049113b0a9bd89e67aa4833425cc026fc7cee7c3ce3c01daa6",
         x86_64_linux: "511c22696b3a6a0192cbf4d4f343e341c27993c8b12d3dca01770a0bf3d90dc5"

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
