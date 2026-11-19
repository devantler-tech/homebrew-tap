cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.215.22"
  sha256 arm:          "6fc4ac4989e7a9f62ba67dcf384eb3aa38b34bb76ebc018e8a88136953e602f5",
         arm64_linux:  "5890b8c22bc3155573923c6b8bfc663022a87ea8fa14135bef86318c9e7f94b6",
         x86_64_linux: "7cfc512621a25f473567a6ed4622e3a2e5c0dfbec0deb08181a268f9edd11a71"

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
