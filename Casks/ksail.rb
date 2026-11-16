cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.215.8"
  sha256 arm:          "acdfc2865363d639cf0e352e8205453461d2a5f515126ccd79c25c4ca413d2ab",
         arm64_linux:  "76a3af2d500e2953cd0b47082f1d9b52678dcfc139f7cbd8271d2efbf311468b",
         x86_64_linux: "8fa35eed743ccfe69ec9c3ab2a68f4d1d95006cf5b4bab3c653df57adf0af6ee"

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
