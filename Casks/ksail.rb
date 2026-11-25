cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.216.26"
  sha256 arm:          "2c6948a3e4607bc8682fbb0eb9867195e660d9243f623e1feed6f0679b7c70da",
         arm64_linux:  "71533ccd2604a877c72109a0989bc09a0f57f5bb8d8f54277b52c438467a596f",
         x86_64_linux: "08898e3fe24a86973910bd160b49f4149da7d38ff0575d1579cb5d6801f0f0ae"

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
