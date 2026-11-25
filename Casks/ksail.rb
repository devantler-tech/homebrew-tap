cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.216.24"
  sha256 arm:          "5154c29dd36c941f9cdd9810a27175040546ce90a8f9656c9baea42c749c63b8",
         arm64_linux:  "f16126b0929daa1846162c74a74d1349a520c7f7329bde2f54305baae81a99c2",
         x86_64_linux: "e91e2bc35bda64b76dc20a050131fb1169904f284726543e42fb875c8f0cdf7a"

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
